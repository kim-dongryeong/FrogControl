using FrogControl.Features;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Input;

/// <summary>
/// The heart of the port: installs the low-level keyboard/mouse hooks and maps every event
/// to a feature, reproducing the AHK hotkey table. Hook callbacks stay fast — one-shot actions
/// go to the worker queue, interactive loops/modes get their own thread.
/// </summary>
public sealed class HotkeyEngine : IDisposable
{
    private readonly KeyboardHook _kb;
    private readonly MouseHook _mouse;

    private bool _capsComboUsed;
    private int _lastModVk;
    private int _lastModTime;

    // Virtual-key codes for the keys we match by letter/symbol.
    private const int A = 0x41, C = 0x43, D = 0x44, E = 0x45, L = 0x4C, M = 0x4D,
        O = 0x4F, R = 0x52, S = 0x53, W = 0x57, X = 0x58, Z = 0x5A;

    public HotkeyEngine()
    {
        _kb = new KeyboardHook(OnKey);
        _mouse = new MouseHook(OnMouse);
    }

    public void Start()
    {
        _kb.Install();
        _mouse.Install();
    }

    public void Dispose()
    {
        _kb.Dispose();
        _mouse.Dispose();
    }

    private static bool IsArrow(int vk) => vk is Win32.VK_LEFT or Win32.VK_UP or Win32.VK_RIGHT or Win32.VK_DOWN;

    // =====================================================================
    // Keyboard
    // =====================================================================
    private void OnKey(KeyHookEventArgs e)
    {
        if (e.IsInjected) return;

        // Typematic re-assertion of a modifier the isolated-send just lifted: swallow it so
        // a held Shift can't corrupt Ctrl+W into Ctrl+Shift+W mid-send (see KeyComboIsolated).
        if (e.IsKeyDown && InputSimulator.ShouldSuppressPhysicalRepeat(e.Vk))
        {
            e.Handled = true;
            return;
        }

        // Route to an active modal mode (date/time input, mouse control).
        var channel = ModeHost.ActiveChannel;
        if (channel != null)
        {
            if (e.IsKeyDown)
            {
                char ch = KeyTranslate.VkToChar(e.Vk, KeyState.Shift);
                channel.Push(new KeyPress(e.Vk, ch, KeyState.Shift));
            }
            e.Handled = true;    // suppress everything while a mode captures input
            return;
        }

        StampModifier(e);

        if (FrogControl.App.Suspended)
        {
            // Only CapsLock+F12 works while suspended; everything else passes through.
            if (e.IsKeyDown && e.Vk == 0x7B /*F12*/ && KeyState.Caps)
            {
                ToggleSuspend();
                e.Handled = true;
            }
            return;
        }

        var s = FrogControl.App.Settings;

        // ---- CapsLock as prefix ----
        if (e.Vk == Win32.VK_CAPITAL)
        {
            if (!s.SuppressCapsLock) return;   // leave CapsLock normal if configured off
            if (e.IsKeyDown)
            {
                _capsComboUsed = false;
                e.Handled = true;
            }
            else
            {
                if (!_capsComboUsed && s.CapsLockTapToggles)
                    CapsLockState.Set(!CapsLockState.IsOn);   // tap toggles the real CapsLock
                e.Handled = true;
            }
            return;
        }

        if (!e.IsKeyDown) return;   // only dispatch on key-down

        // ---- CapsLock + key combos ----
        if (KeyState.Caps && s.SuppressCapsLock)
        {
            if (HandleCapsCombo(e.Vk))
            {
                _capsComboUsed = true;
                e.Handled = true;
            }
            // unrecognised CapsLock+key: let it pass through
            return;
        }

        // ---- Plain modifier combos (Win/Alt/Ctrl/Shift + key) ----
        if (HandleModifierCombo(e.Vk))
            e.Handled = true;
    }

    private void StampModifier(KeyHookEventArgs e)
    {
        if (!e.IsKeyDown) return;
        string? mod = e.Vk switch
        {
            0x10 or 0xA0 or 0xA1 => "Shift",
            0x11 or 0xA2 or 0xA3 => "Control",
            0x12 or 0xA4 or 0xA5 => "Alt",
            0x5B or 0x5C => "Win",
            0x14 => "CapsLock",
            _ => null,
        };
        if (mod == null) return;
        int now = Environment.TickCount;
        if (e.Vk == _lastModVk && now - _lastModTime < 80) return;   // reject typematic auto-repeat
        _lastModVk = e.Vk;
        _lastModTime = now;
        KeyState.RecordTap(mod);
    }

    private bool HandleCapsCombo(int vk)
    {
        // Arrows -> window move / grid (guarded; disabled during mouse-control mode)
        if (IsArrow(vk))
        {
            if (FrogControl.App.FlagMouseControl) return false;
            if (!FrogControl.App.IsRunning("windowMove"))
                FrogControl.App.RunDetached("windowMove", WindowMover.Start);
            return true;
        }

        switch (vk)
        {
            case O: FrogControl.App.RunDetached("dateMode", DateTimeInputMode.Start); return true;
            case M: FrogControl.App.RunDetached("mouseMode", MouseControlMode.Start); return true;
            case Z: FrogControl.App.RunDetached("clickL", MouseClicks.HoldLeft); return true;
            case C: FrogControl.App.RunDetached("clickR", MouseClicks.HoldRight); return true;
            case X: FrogControl.App.RunDetached("clickM", MouseClicks.HoldMiddle); return true;
            case W: FrogControl.App.Run(MouseClicks.WheelUp); return true;
            case S: FrogControl.App.Run(MouseClicks.WheelDown); return true;
            case A: FrogControl.App.Run(MouseClicks.WheelLeft); return true;
            case D: FrogControl.App.Run(MouseClicks.WheelRight); return true;
            case E: FrogControl.App.Run(WindowOps.MoveActiveToCursor); return true;
            case R: FrogControl.App.Run(WindowOps.MoveCursorToActiveCenter); return true;
            case Win32.VK_TAB: FrogControl.App.Run(WindowOps.SendEnter); return true;
            case Win32.VK_OEM_PLUS: FrogControl.App.Run(CoordinateMode.Handle); return true;   // CapsLock + '+'/'='
            case Win32.VK_OEM_2: FrogControl.App.Run(ShowHelp); return true;                    // CapsLock + '?'/'/'
            case Win32.VK_OEM_3: FrogControl.App.Run(WheelScroll.EnterSlowMode); return true;   // CapsLock + '`'
            case 0x7A: FrogControl.App.Run(WindowBookmarks.ListAll); return true;               // F10
            case 0x7B: ToggleSuspend(); return true;                                            // F12
        }

        // Digits 1..9,0 -> mouse bookmarks
        if (vk is >= 0x31 and <= 0x39)
        {
            string key = ((char)vk).ToString();
            FrogControl.App.Run(() => MouseBookmarks.Handle(key));
            return true;
        }
        if (vk == 0x30) { FrogControl.App.Run(() => MouseBookmarks.Handle("0")); return true; }

        // F1..F9 -> window bookmarks
        if (vk is >= 0x70 and <= 0x78)
        {
            string fn = "F" + (vk - 0x70 + 1);
            FrogControl.App.Run(() => WindowBookmarks.HandleFn(fn));
            return true;
        }

        return false;
    }

    private bool HandleModifierCombo(int vk)
    {
        bool win = KeyState.Win, alt = KeyState.Alt, ctrl = KeyState.Ctrl, shift = KeyState.Shift;

        // ---- Arrows ----
        if (IsArrow(vk))
        {
            if (win && ctrl && alt)
            {
                if (!FrogControl.App.IsRunning("windowSeekArrow"))
                    FrogControl.App.RunDetached("seek", WindowSeeker.Start);
                return true;
            }
            if (win && alt && shift)
            {
                char dir = vk switch { Win32.VK_RIGHT => 'R', Win32.VK_LEFT => 'L', Win32.VK_UP => 'U', _ => 'D' };
                FrogControl.App.Run(() => WindowResizer.ResizeToEdge(dir));
                return true;
            }
            if (win && alt)
            {
                if (!FrogControl.App.IsRunning("windowResize"))
                    FrogControl.App.RunDetached("resize", WindowResizer.ResizeLoop);
                return true;
            }
            return false;
        }

        // ---- Letters / F-keys / symbols ----
        switch (vk)
        {
            case A when win && !alt && !ctrl && !shift:            // #a
                FrogControl.App.Run(WindowOps.ToggleAlwaysOnTopActive); return true;
            case L when win && ctrl:                               // #^L
                FrogControl.App.Run(WindowOps.ShowAltTabList); return true;
            case 0x70 when win && shift:                           // #+F1 TransColor
                FrogControl.App.Run(WindowOps.TransColorUnderMouse); return true;
            case 0x71 when win && shift:                           // #+F2 toggle caption
                FrogControl.App.Run(WindowOps.ToggleCaption); return true;
            case 0x72 when win && shift:                           // #+F3 toggle border
                FrogControl.App.Run(WindowOps.ToggleBorder); return true;
            case 0x70 when shift && !win && !alt && !ctrl:         // +F1 arrange (explorer spread)
                FrogControl.App.Run(() => ArrangeEngine.ShowWindows("Explorer.exe", IntPtr.Zero, 0)); return true;
            case 0x71 when shift && !win && !alt && !ctrl:         // +F2 arrange (explorer grid)
                FrogControl.App.Run(() => ArrangeEngine.ShowWindows("Explorer.exe", IntPtr.Zero, 1)); return true;
            case 0x72 when shift && !win && !alt && !ctrl:         // +F3 arrange (active type spread)
                FrogControl.App.Run(() => ArrangeEngine.ShowWindows("", WindowManager.Active, 0)); return true;
            case 0x73 when shift && !win && !alt && !ctrl:         // +F4 arrange (active type grid)
                FrogControl.App.Run(() => ArrangeEngine.ShowWindows("", WindowManager.Active, 1)); return true;
            case Win32.VK_OEM_3 when alt:                          // !` / !+`  same-type rotate
                FrogControl.App.Run(() => { if (shift) WindowOps.PrevSameType(); else WindowOps.NextSameType(true); }); return true;
            case 0x31 when win && ctrl && alt && shift:            // #^!+1 virtual desktop
            case 0x32 when ctrl && alt && shift:                  // ^!+2 virtual desktop
                FrogControl.App.Run(WindowOps.VirtualDesktopRight); return true;
        }

        // ---- Bracket keys mirror the wheel actions ----
        if (vk == Win32.VK_OEM_6 || vk == Win32.VK_OEM_4)   // ] or [
        {
            bool up = vk == Win32.VK_OEM_6;                 // ] behaves like WheelUp
            return HandleWheelLike(up, win, alt, ctrl, shift);
        }

        return false;
    }

    // =====================================================================
    // Mouse
    // =====================================================================
    // A suppressed button-DOWN must also swallow the matching button-UP: a lone
    // WM_RBUTTONUP makes DefWindowProc fire WM_CONTEXTMENU, so the context menu popped
    // up alongside Ctrl+Shift+RightClick and ate the next click. (AHK mouse hotkeys
    // suppress the down/up pair automatically; we do it explicitly.)
    private bool _swallowNextLUp;
    private bool _swallowNextRUp;

    private void OnMouse(MouseHookEventArgs e)
    {
        if (e.IsInjected) return;
        if (FrogControl.App.Suspended) return;

        // Swallow the button-up matching a suppressed down (drag or click combo). The explicit
        // flags also cover the race where the drag loop clears .Active before this up arrives.
        if (e.Kind == MouseEventKind.LeftUp && (_swallowNextLUp || MouseDragMove.Active))
        { _swallowNextLUp = false; e.Handled = true; return; }
        if (e.Kind == MouseEventKind.RightUp && (_swallowNextRUp || MouseDragResize.Active))
        { _swallowNextRUp = false; e.Handled = true; return; }

        bool win = KeyState.Win, alt = KeyState.Alt, ctrl = KeyState.Ctrl, shift = KeyState.Shift, caps = KeyState.Caps;

        switch (e.Kind)
        {
            case MouseEventKind.Wheel:
            {
                bool dirDown = e.WheelDelta < 0;
                if (HandleWheel(dirDown, win, alt, ctrl, shift, caps))
                    e.Handled = true;
                return;
            }
            case MouseEventKind.LeftDown:
            {
                if (caps)
                {
                    _capsComboUsed = true;
                    if (!MouseDragMove.Active)
                        FrogControl.App.RunDetached("dragMove", MouseDragMove.Start);
                    _swallowNextLUp = true;
                    e.Handled = true;
                }
                else if (win)
                {
                    FrogControl.App.Run(WindowOps.ToggleAlwaysOnTopUnderMouse);
                    _swallowNextLUp = true;
                    e.Handled = true;
                }
                return;
            }
            case MouseEventKind.RightDown:
            {
                if (caps)
                {
                    _capsComboUsed = true;
                    if (!MouseDragResize.Active)
                        FrogControl.App.RunDetached("dragResize", MouseDragResize.Start);
                    _swallowNextRUp = true;
                    e.Handled = true;
                }
                else if (HandleRightClick(win, alt, ctrl, shift))
                {
                    _swallowNextRUp = true;
                    e.Handled = true;
                }
                return;
            }
        }
    }

    private bool HandleWheel(bool dirDown, bool win, bool alt, bool ctrl, bool shift, bool caps)
    {
        if (caps)
        {
            FrogControl.App.Run(() => WheelScroll.CapsFast(dirDown));
            _capsComboUsed = true;
            return true;
        }
        if (win && alt && ctrl)
        {
            if (FrogControl.App.Settings.EnableUnstableRotation)
                FrogControl.App.Run(() => WindowRotator.OnWheel(true, dirDown));
            return true;
        }
        if (win && alt && shift)
        {
            FrogControl.App.Run(() => { if (dirDown) WindowOps.NextSameType(true); else WindowOps.PrevSameType(); });
            return true;
        }
        if (win && alt)
        {
            FrogControl.App.Run(() => WindowOps.AdjustTransparencyActive(dirDown ? -20 : 20));
            return true;
        }
        if (win && ctrl)
        {
            FrogControl.App.Run(() => VolumeControl.Adjust(dirDown ? -1 : 1));
            return true;
        }
        if (win)
        {
            FrogControl.App.Run(() => VolumeControl.Adjust(dirDown ? -10 : 10));
            return true;
        }
        if (alt && ctrl)
        {
            FrogControl.App.Run(() => WindowRotator.OnWheel(false, dirDown));
            return true;
        }
        if (ctrl && shift)
        {
            FrogControl.App.Run(() => { if (dirDown) WindowOps.CtrlPageDown(); else WindowOps.CtrlPageUp(); });
            return true;
        }
        if (shift && !win && !alt && !ctrl)
        {
            string cls = WindowManager.GetClass(WindowManager.Active);
            if (cls == "XLMAIN" || cls == "OpusApp")
            {
                FrogControl.App.Run(() => WheelScroll.OfficeFast(dirDown));
                return true;
            }
        }
        return false;
    }

    /// <summary>Bracket-key ([ ]) equivalents of the wheel hotkeys (no caps/office cases).</summary>
    private bool HandleWheelLike(bool up, bool win, bool alt, bool ctrl, bool shift)
    {
        bool dirDown = !up;
        if (win && alt && ctrl) { if (FrogControl.App.Settings.EnableUnstableRotation) FrogControl.App.Run(() => WindowRotator.OnWheel(true, dirDown)); return true; }
        if (win && alt && shift) { FrogControl.App.Run(() => { if (dirDown) WindowOps.NextSameType(true); else WindowOps.PrevSameType(); }); return true; }
        if (win && alt) { FrogControl.App.Run(() => WindowOps.AdjustTransparencyActive(dirDown ? -20 : 20)); return true; }
        if (win && ctrl) { FrogControl.App.Run(() => VolumeControl.Adjust(dirDown ? -1 : 1)); return true; }
        if (win) { FrogControl.App.Run(() => VolumeControl.Adjust(dirDown ? -10 : 10)); return true; }
        if (alt && ctrl) { FrogControl.App.Run(() => WindowRotator.OnWheel(false, dirDown)); return true; }
        return false;
    }

    private bool HandleRightClick(bool win, bool alt, bool ctrl, bool shift)
    {
        if (win && ctrl && alt && shift) { FrogControl.App.Run(WindowOps.CloseWindowUnderMouseForce); return true; }  // #^+!
        if (ctrl && alt && shift) { FrogControl.App.RunDetached("closeWin", WindowOps.CloseWindowUnderMouse); return true; } // ^+!
        if (ctrl && shift) { FrogControl.App.RunDetached("closeTab", WindowOps.CloseTabUnderMouse); return true; }           // ^+
        if (alt && shift) { FrogControl.App.Run(WindowOps.SendToBottomUnderMouse); return true; }                            // !+
        if (alt) { FrogControl.App.Run(WindowOps.MinimizeUnderMouse); return true; }                                         // !
        return false;
    }

    // =====================================================================
    // Misc
    // =====================================================================
    private static void ShowHelp()
    {
        HelpForm.Show(FrogControl.App.HelpLang == 2 ? "ko" : "en");
    }

    public void ToggleSuspend()
    {
        FrogControl.App.Suspended = !FrogControl.App.Suspended;
        if (FrogControl.App.Suspended)
            TrayTipService.Show("FrogControl", "Bye for now! Now disabled");
        else
            TrayTipService.Show("FrogControl", "Hi again! Now enabled");
        TrayIconHost.UpdateSuspendState();
    }
}
