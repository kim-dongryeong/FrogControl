using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Accelerated / slowed mouse-wheel scrolling.
///   CapsLock + Wheel (+ CapsLock taps) -> fast scroll (WheelScroll_CapsFast)
///   Shift + Wheel in Excel/Word         -> horizontal fast scroll via COM (WheelScroll_OfficeFast)
///   CapsLock + `                        -> slow mode: one line per notch while CapsLock is held
/// </summary>
public static class WheelScroll
{
    private static int _fastLv1Started;     // WheelScroll_fast_lv1_started (0/1/2)
    private static int _speedUp;            // wheelScroll_speedUp
    private static int _speedUpExcel;       // wheelScroll_speedUp_Excel
    public static volatile bool SlowMode;   // set while CapsLock+` slow mode is active

    private static int Default => FrogControl.App.Settings.WheelScrollSpeedUpDefault;

    // ---------------- CapsLock + Wheel (fast) ----------------
    public static void CapsFast(bool dirDown)
    {
        if (SlowMode) { InputSimulator.WheelVertical(dirDown ? -1 : 1); return; }

        if (_fastLv1Started == 0)
        {
            _fastLv1Started = 1;
            _speedUp = Default * (1 + KeyState.CountRecentTaps("CapsLock"));
        }

        string cls = WindowManager.GetClass(WindowManager.Active);
        if (cls == "XLMAIN" && KeyState.Shift)
        {
            _speedUpExcel = _speedUp + Default;
            if (!TryExcelScroll("Excel.Application", dirDown, _speedUpExcel))
                InputSimulator.WheelVertical(dirDown ? -_speedUp : _speedUp);
        }
        else
        {
            InputSimulator.WheelVertical(dirDown ? -_speedUp : _speedUp);
        }

        if (_fastLv1Started == 1)
            FirstTooltip();
    }

    // ---------------- Shift + Wheel in Excel/Word (horizontal) ----------------
    public static void OfficeFast(bool dirDown)
    {
        if (_fastLv1Started == 0)
        {
            _fastLv1Started = 1;
            _speedUp = Default * KeyState.CountRecentTaps("Shift");
            _speedUpExcel = _speedUp == 0 ? Default : _speedUp;
            _speedUp -= Default;
        }
        string cls = WindowManager.GetClass(WindowManager.Active);
        string prog = cls == "XLMAIN" ? "Excel.Application" : "Word.Application";
        if (!TryExcelScroll(prog, dirDown, _speedUpExcel))
            InputSimulator.WheelVertical(dirDown ? -1 : 1);

        if ((double)_speedUpExcel / Default < 2)
            _fastLv1Started = 0;
        else if (_fastLv1Started == 1)
            FirstTooltip();
    }

    private static bool TryExcelScroll(string progId, bool dirDown, int amount)
    {
        try
        {
            dynamic? app = ComHelper.GetActive(progId);
            if (app == null) return false;
            if (dirDown) app.ActiveWindow.SmallScroll(0, 0, amount, 0);  // scroll right
            else app.ActiveWindow.SmallScroll(0, 0, 0, amount);         // scroll left
            return true;
        }
        catch { return false; }
    }

    // ---------------- The "level N" tooltip shown once per burst ----------------
    private static void FirstTooltip()
    {
        _fastLv1Started = 2;
        int level = (int)Math.Round((double)_speedUp / Default);
        string extra = level switch
        {
            4 => "       Iuppidu!",
            5 => "       Cool!",
            6 => "       So Cool!",
            7 => "       Daebak..",
            8 => "       Yay!",
            9 => "       Speed camera there!",
            10 => "       Oh my gosh!",
            11 => "       Do you really want more?",
            12 => "       I hereby confirm you are a nerd.",
            13 => "       Basta!",
            14 => "       E = mc^2 ...",
            15 => "       Yes I know I'm a nerd",
            16 => "       Che vuoi?",
            17 => "       Really? Isn't it too much?",
            18 => "       Your keyboard will die ...",
            19 => "       It's not a game..",
            20 => "       Well done!",
            _ => "",
        };
        ToolTipService.ShowTimed($"Wheel speed up: level {level}{extra}", FrogControl.App.Settings.TooltipDurationShortMs);

        // Reset the "started" latch when the modifiers are released (mirrors WheelScroll_fast_first).
        FrogControl.App.RunDetached("wheelReset", () =>
        {
            if (KeyState.Caps || _speedUp != 0)
            {
                Pacing.KeyWaitRelease(Win32.VK_CAPITAL, 0);
                Pacing.KeyWaitRelease(Win32.VK_SHIFT, 0);
            }
            else
            {
                Pacing.KeyWaitRelease(Win32.VK_SHIFT, 0);
            }
            _fastLv1Started = 0;
        });
    }

    // ---------------- CapsLock + ` slow mode ----------------
    public static void EnterSlowMode()
    {
        if (SlowMode) return;
        SlowMode = true;
        TrayTipService.Show("Mouse wheel slow mode", "Hold the hotkey and scroll for one line at a time");
        uint saved = SystemParams.GetWheelScrollLines();
        SystemParams.SetWheelScrollLines(1);
        FrogControl.App.RunDetached("wheelSlow", () =>
        {
            Pacing.KeyWaitRelease(Win32.VK_CAPITAL, 0);
            SystemParams.SetWheelScrollLines(saved);
            SlowMode = false;
        });
    }
}
