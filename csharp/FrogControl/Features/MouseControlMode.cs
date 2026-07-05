using System.Globalization;
using FrogControl.Config;
using FrogControl.Input;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Port of the AHK "Mouse Control Mode" (hotkey CapsLock &amp; M, FrogControl.ahk lines 1761-2098).
///
/// A modal loop that turns the keyboard into a mouse driver. It captures the active window,
/// activates the taskbar so stray keystrokes do not leak, then reads suppressed key-downs from
/// the <see cref="KeyInputChannel"/> the engine feeds while <see cref="FrogControl.App.FlagMouseControl"/>
/// is set. Sub-modes reproduced faithfully from the AHK:
///   - number + arrow : jump the cursor N pixels in a direction
///   - CapsLock + arrow (hold) : move-by-keyboard, speed varies with Ctrl/Alt/Shift
///   - '+' or '=' : constrained (axis-locked) mode
///   - 'R' : ruler mode (distance/angle readout)
///   - 'W' : centre cursor on the captured window
///   - 'C' : show current coordinates
///   - '?' : help tooltip;  Esc : close help / finish the mode
///
/// Runs the whole loop on the CURRENT thread (the engine invokes it on a detached thread), so the
/// blocking <c>ch.Read()</c> and the various <c>Thread.Sleep</c> polls are safe here.
/// </summary>
public static class MouseControlMode
{
    // Special-key virtual-key codes (given by the task; kept local so we lean only on the
    // listed foundation classes, never on engine/hook types).
    private const int VK_BACK = 0x08;
    private const int VK_ENTER = 0x0D;
    private const int VK_ESCAPE = 0x1B;
    private const int VK_SPACE = 0x20;
    private const int VK_LEFT = 0x25;
    private const int VK_UP = 0x26;
    private const int VK_RIGHT = 0x27;
    private const int VK_DOWN = 0x28;
    private const int VK_W = 0x57;

    private const string IntroText =
        "Input any number to move mouse or press arrow keys to move it.\n" +
        "Esc to quit the mouse control mode.\n" +
        "Press ? for help.";

    private const string HelpText =
        "Mouse control mode help\n\n" +
        "- Type any number in pixel followed by an arrow key : Move the mouse to the direction\n" +
        "- While holding CapsLock, hold any Arrow key : Move the mouse pointer by the keyboard (holding with Alt, Shift or Ctrl will change the speed)\n" +
        "- + (or =) : Enter the mouse constrained mode. (Press SpaceBar to move the mouse pointer back to the original position.)\n" +
        "- R : Enter the mouse ruler mode. (Then press SpaceBar to set the reference point.)\n" +
        "- W : move the mouse pointer to the center of a current window\n" +
        "- C : Show the current coordinates\n" +
        "- ? : Open the help\n" +
        "- Esc : close the help and finish the Mouse control mode";

    private const string ConstrainedText =
        "Constrained mouse mode\n" +
        "- Space bar: moves to the initial position\n" +
        "- Esc: finishes the constrained mouse mode";

    /// <summary>Runs the whole modal loop on the CURRENT thread.</summary>
    public static void Start()
    {
        // is_capslock_initial := getkeystate("capslock", "T")
        bool capsInitial = CapsLockState.IsOn;

        // FLAG_MOUSECONTROL := 1  +  begin the suppressed-key channel.
        FrogControl.App.FlagMouseControl = true;
        var ch = ModeHost.Begin();

        // WinGet, mouseControl_activeWin, ID, A   (before we steal focus to the taskbar).
        IntPtr activeWin = WindowManager.Active;

        try
        {
            // WinActivate, ahk_class Shell_TrayWnd  -> keystrokes land on the taskbar, not the app.
            WindowManager.ActivateTaskbar();
            TrayTipService.Show("Mouse control mode", "Press ? for help");
            ToolTipService.Show(IntroText);

            RunLoop(ch, activeWin);
        }
        finally
        {
            // WinActivate, ahk_id %mouseControl_activeWin%  + clean up tooltips and flags.
            WindowManager.Activate(activeWin);
            ToolTipService.Hide(2);
            ToolTipService.Hide(3);
            ToolTipService.ShowTimed("Mouse control mode finished", 2000, 1);

            CapsLockState.Set(capsInitial);
            FrogControl.App.FlagMouseControl = false;
            ModeHost.End(ch);
        }
    }

    // ------------------------------------------------------------------
    // Outer loop: read one key at a time (AHK's `Input, ..., L1 E, {..}`).
    // ------------------------------------------------------------------
    private static void RunLoop(KeyInputChannel ch, IntPtr activeWin)
    {
        string input = "";       // mouseControl_input (numeric buffer)
        bool helpOn = false;     // mouseControl_helpOn

        while (true)
        {
            var read = ch.Read();          // blocking (like AHK Input)
            if (read is null) return;      // channel closed -> bail out
            var kp = read.Value;
            int vk = kp.Vk;
            char c = kp.Ch;

            // --- EndKey:Escape ---
            if (vk == VK_ESCAPE)
            {
                if (helpOn) { ToolTipService.Hide(3); helpOn = false; continue; }
                return;   // finish the mode
            }

            // --- EndKey:W : centre cursor on the captured window ---
            if (c is 'W' or 'w')
            {
                CenterOnWindow(activeWin);
                ToolTipService.Show(IntroText);
                continue;
            }

            // --- EndKey:? : help tooltip near the mouse (mousey + 60), slot 3 ---
            if (c == '?')
            {
                InputSimulator.GetCursor(out int mx, out int my);
                ToolTipService.Show(HelpText, 3, mx, my + 60);
                helpOn = true;
                continue;
            }

            // --- EndKey:C : current coordinates, slot 2, auto-hide short ---
            if (c is 'C' or 'c')
            {
                InputSimulator.GetCursor(out int mx, out int my);
                ToolTipService.ShowTimed($"mouse coordinates: ({mx}, {my})",
                    FrogControl.App.Settings.TooltipDurationShortMs, 2, mx, my - 30);
                continue;
            }

            // --- EndKey:= or EndKey:+ : constrained mode, then break the whole mode ---
            if (c is '=' or '+')
            {
                ConstrainedMode();
                return;   // AHK does `break` after this sub-mode
            }

            // --- EndKey:R : ruler mode, then reset intro and continue ---
            if (c is 'R' or 'r')
            {
                RulerMode();
                ch.Clear();               // drop keys buffered during the ruler sub-loop
                continue;
            }

            // --- Other end keys (Left/Right/Up/Down/Enter/BackSpace): the `input_L1 = ""` branch ---
            if (vk is VK_LEFT or VK_RIGHT or VK_UP or VK_DOWN or VK_ENTER or VK_BACK)
            {
                if (input.Length == 0)
                {
                    // mouseControl_input = "" -> move-by-keyboard sub-loop, then break the mode.
                    ArrowHoldMode(activeWin);
                    return;   // AHK does `break` after this block
                }

                // End key after a number was typed -> jump by that many pixels.
                int n = int.TryParse(input, NumberStyles.Integer, CultureInfo.InvariantCulture, out int v) ? v : 0;
                InputSimulator.GetCursor(out int mx, out int my);
                switch (vk)
                {
                    case VK_RIGHT: MoveCursorTo(mx + n, my); input = ""; ToolTipService.Show(IntroText); break;
                    case VK_LEFT:  MoveCursorTo(mx - n, my); input = ""; ToolTipService.Show(IntroText); break;
                    case VK_DOWN:  MoveCursorTo(mx, my + n); input = ""; ToolTipService.Show(IntroText); break;
                    case VK_UP:    MoveCursorTo(mx, my - n); input = ""; ToolTipService.Show(IntroText); break;
                    case VK_BACK:
                        if (input.Length > 0) input = input.Substring(0, input.Length - 1);
                        ToolTipService.Show(MovePxText(input));
                        break;
                    default: // Enter
                        input = "";
                        ToolTipService.Show(IntroText);
                        break;
                }
                continue;
            }

            // --- Typed character (digit '0'-'9', or any other non-end char): accumulate ---
            // Mirrors AHK's `mouseControl_input .= mouseControl_input_L1` + the final else tooltip.
            if (c != '\0') input += c;
            ToolTipService.Show(MovePxText(input));
        }
    }

    // ------------------------------------------------------------------
    // '+' / '='  : constrained (axis-locked) mode
    // ------------------------------------------------------------------
    private static void ConstrainedMode()
    {
        ToolTipService.ShowTimed(ConstrainedText, FrogControl.App.Settings.TooltipDurationShortMs, 1);
        InputSimulator.GetCursor(out int origX, out int origY);

        while (true)
        {
            InputSimulator.GetCursor(out int curX, out int curY);

            // Nerdy part: floor(exp(det - abs(det))) == 1 when det >= 0 (x-axis dominant) else 0.
            int det = Math.Abs(curX - origX) - Math.Abs(curY - origY);
            int step = (int)Math.Floor(Math.Exp(det - Math.Abs(det)));
            MoveCursorTo(origX + (curX - origX) * step, origY + (curY - origY) * (1 - step));

            if (KeyState.Space)
            {
                MoveCursorTo(origX, origY);
                ToolTipService.ShowTimed($"initial coordinates: ({origX}, {origY})",
                    FrogControl.App.Settings.TooltipDurationShortMs, 1);
            }
            if (KeyState.Escape) break;

            Thread.Sleep(2);
        }
    }

    // ------------------------------------------------------------------
    // 'R' : ruler mode
    // ------------------------------------------------------------------
    private static void RulerMode()
    {
        ToolTipService.Show("Press SpaceBar to set the first point");

        // KeyWait, Space, D T10  (emulated by polling physical state via Pacing).
        bool pressed = Pacing.KeyWaitDown(VK_SPACE, 10);
        InputSimulator.GetCursor(out int initX, out int initY);

        if (pressed)
        {
            // (The little reference-point GUI square the AHK draws is purely cosmetic; skipped.)
            string last = "";
            while (true)
            {
                Thread.Sleep(10);
                InputSimulator.GetCursor(out int curX, out int curY);

                int dx = curX - initX;
                int dy = curY - initY;
                double dist = Math.Sqrt((double)dx * dx + (double)dy * dy);

                double angle = 0;
                if (dist > 0)
                {
                    angle = Math.Asin(-dy / dist);
                    if (dx < 0) angle = Math.PI - angle;   // reflect into the left half-plane
                }
                double angleDeg = angle * 57.29578;

                string text =
                    $"Initial mouse coordinates: ({initX}, {initY})\n" +
                    $"Current mouse coordinates: ({curX}, {curY})\n" +
                    $"horizontal distance (x): {dx}\n" +
                    $"veritical distance (y): {-dy}\n" +   // keep AHK's original label/typo
                    $"distance : {dist.ToString("0.######", CultureInfo.InvariantCulture)}\n" +
                    $"angle : {angleDeg.ToString("0.######", CultureInfo.InvariantCulture)}\n" +
                    "Esc to quit the ruler mode.";

                if (text != last) { ToolTipService.Show(text); last = text; }  // update only on change (AHK vtext trick)
                if (KeyState.Escape) break;
            }
        }

        ToolTipService.Show(IntroText);
    }

    // ------------------------------------------------------------------
    // CapsLock + arrow (hold) : move-by-keyboard sub-loop
    // ------------------------------------------------------------------
    private static void ArrowHoldMode(IntPtr activeWin)
    {
        ToolTipService.ShowTimed("Mouse move by keyboard mode. Hold Ctrl or Alt to change speed.", 3000, 1);

        while (true)
        {
            if (KeyState.Ctrl)         ArrowPass(10, 0.006);
            else if (KeyState.Alt)     ArrowPass(1, 0.01);
            else if (KeyState.Shift)   ArrowPass(1, 0.005);
            else
            {
                ArrowPass(20, 0);                                   // middle speed, no per-key wait
                if (KeyState.IsDown(VK_W)) CenterOnWindow(activeWin);
            }

            if (!KeyState.Caps) break;   // CapsLock released -> leave (and the whole mode ends)
            Thread.Sleep(2);
        }
    }

    /// <summary>One pass over the four arrow keys: move the held ones by <paramref name="px"/>,
    /// optionally pacing each with a KeyWait-release of <paramref name="waitSec"/> seconds.</summary>
    private static void ArrowPass(int px, double waitSec)
    {
        if (KeyState.Right) { MoveByArrow(VK_RIGHT, px); if (waitSec > 0) Pacing.KeyWaitRelease(VK_RIGHT, waitSec); }
        if (KeyState.Left)  { MoveByArrow(VK_LEFT, px);  if (waitSec > 0) Pacing.KeyWaitRelease(VK_LEFT, waitSec); }
        if (KeyState.Down_) { MoveByArrow(VK_DOWN, px);  if (waitSec > 0) Pacing.KeyWaitRelease(VK_DOWN, waitSec); }
        if (KeyState.Up)    { MoveByArrow(VK_UP, px);    if (waitSec > 0) Pacing.KeyWaitRelease(VK_UP, waitSec); }
    }

    private static void MoveByArrow(int arrowVk, int px)
    {
        InputSimulator.GetCursor(out int x, out int y);
        switch (arrowVk)
        {
            case VK_RIGHT: MoveCursorTo(x + px, y); break;
            case VK_LEFT:  MoveCursorTo(x - px, y); break;
            case VK_DOWN:  MoveCursorTo(x, y + px); break;
            case VK_UP:    MoveCursorTo(x, y - px); break;
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    private static void CenterOnWindow(IntPtr win)
    {
        if (WindowManager.GetPos(win, out int x, out int y, out int w, out int h))
            MoveCursorTo(x + w / 2, y + h / 2);
    }

    private static string MovePxText(string input) =>
        $"Move mouse {input} px.  Press an arrow key to move the mouse to the direction.\n" +
        "Esc to quit the mouse control mode.\n" +
        "Press ? for help.";

    /// <summary>Absolute cursor move, honouring the configured backend.</summary>
    private static void MoveCursorTo(int x, int y)
    {
        // Both backends currently route through SetCursorPos (InputSimulator.MoveCursor).
        // SendInputRelative is accepted as an equivalent path per the settings contract;
        // branch on it so the setting is respected and a relative-SendInput move can slot in later.
        switch (FrogControl.App.Settings.MouseMoveBackend)
        {
            case MouseMoveBackend.SendInputRelative:
                InputSimulator.MoveCursor(x, y);
                break;
            case MouseMoveBackend.SetCursorPos:
            default:
                InputSimulator.MoveCursor(x, y);
                break;
        }
    }
}
