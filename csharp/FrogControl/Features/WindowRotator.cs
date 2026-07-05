using FrogControl.Input;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Wheel-driven window rotation (port of WindowRotate_OnWheel + window_rotate_stacking +
/// window_rotate_popup).
///   Ctrl+Alt+Wheel            -> rotate while stacking (send front window to the back)
///   Win+Ctrl+Alt+Wheel        -> rotate as a "temporary showing" popup (half-transparent peek)
/// Each wheel notch bumps a counter; a background loop consumes the counter and steps until
/// the modifiers are released.
/// </summary>
public static class WindowRotator
{
    private static readonly object Sync = new();
    private static volatile int _wheelCountDown;
    private static int _wheelCountCheck;
    private static int _current;             // 1-based
    private static int _topOfNontopmost = 1; // 1-based
    private static List<IntPtr> _ids = new();
    private static volatile bool _firstStacking;
    private static volatile bool _firstPopup;

    public static void OnWheel(bool isPopup, bool dirDown)
    {
        lock (Sync)
        {
            // The other mode's loop is live: don't touch the shared counters.
            if (isPopup ? _firstStacking : _firstPopup) return;

            bool myFirst = isPopup ? _firstPopup : _firstStacking;
            if (!myFirst)
            {
                if (isPopup) _firstPopup = true; else _firstStacking = true;
                _wheelCountDown = dirDown ? 1 : -1;
                _wheelCountCheck = 0;

                var list = WindowEnumerator.List();
                _ids = list.Select(w => w.Id).ToList();
                _topOfNontopmost = 1;
                for (int i = 0; i < _ids.Count; i++)
                {
                    if (!isPopup) WindowManager.SetAlwaysOnTop(_ids[i], false);
                    if (!WindowManager.IsTopmost(_ids[i])) { _topOfNontopmost = i + 1; break; }
                }
                _current = (isPopup && dirDown) ? _topOfNontopmost : 1;

                if (isPopup) FrogControl.App.RunDetached("rotatePopup", PopupLoop);
                else FrogControl.App.RunDetached("rotateStacking", StackingLoop);
                return;
            }
            _wheelCountDown += dirDown ? 1 : -1;
        }
    }

    private static int Count => _ids.Count;
    private static IntPtr Cur => _ids[_current - 1];
    private static int Dur => FrogControl.App.Settings.TooltipDurationShortMs;

    private static void ShowTitle() => ToolTipService.ShowTimed(WindowManager.GetTitle(Cur), Dur);

    private static void StackingLoop()
    {
        WindowManager.ActivateTaskbar();
        while (true)
        {
            Thread.Sleep(10);
            if (!KeyState.Alt || !KeyState.Ctrl)
            {
                lock (Sync)
                {
                    WindowManager.Activate(Cur);
                    for (int a = 1; a <= Count; a++)
                    {
                        if (a < _topOfNontopmost) WindowManager.SetAlwaysOnTop(_ids[_topOfNontopmost - a - 1], true);
                        else break;
                    }
                    _wheelCountDown = 0; _wheelCountCheck = 0; _firstStacking = false;
                }
                break;
            }
            lock (Sync)
            {
                if (_wheelCountDown > _wheelCountCheck)
                {
                    WindowManager.SetBottom(Cur);
                    _current++; if (_current > Count) _current = 1;
                    ShowTitle();
                    _wheelCountCheck++;
                }
                else if (_wheelCountDown < _wheelCountCheck)
                {
                    _current--; if (_current < 1) _current = Count;
                    WindowManager.PulseTop(Cur);
                    ShowTitle();
                    _wheelCountCheck--;
                }
            }
        }
    }

    private static void PopupLoop()
    {
        var s = FrogControl.App.Settings;
        WindowManager.ActivateTaskbar();
        while (true)
        {
            Thread.Sleep(10);
            if (!FrogControl.App.FlagHalfTrans)
            {
                foreach (var id in _ids) WindowManager.SetTransparency(id, s.HalfTrans);
                FrogControl.App.FlagHalfTrans = true;
            }
            if (!KeyState.Win || !KeyState.Ctrl || !KeyState.Alt)
            {
                lock (Sync)
                {
                    WindowManager.Activate(Cur);
                    for (int a = 1; a <= Count; a++)
                    {
                        if (a < _topOfNontopmost) WindowManager.SetAlwaysOnTop(_ids[_topOfNontopmost - a - 1], true);
                        else if (a != _current) WindowManager.SetBottom(_ids[a - 1]);
                    }
                    if (_current < _topOfNontopmost) WindowManager.SetAlwaysOnTop(Cur, true);
                    if (FrogControl.App.FlagHalfTrans)
                        foreach (var id in _ids) WindowManager.SetTransparency(id, 255);
                    FrogControl.App.FlagHalfTrans = false;
                    _wheelCountDown = 0; _wheelCountCheck = 0; _firstPopup = false;
                }
                break;
            }
            lock (Sync)
            {
                if (_wheelCountDown > _wheelCountCheck)
                {
                    WindowManager.SetTransparency(Cur, s.HalfTrans);
                    _current++; if (_current > Count) _current = 1;
                    WindowManager.PulseTop(Cur);
                    WindowManager.SetTransparency(Cur, s.FocusTrans);
                    ShowTitle();
                    _wheelCountCheck++;
                }
                else if (_wheelCountDown < _wheelCountCheck)
                {
                    WindowManager.SetTransparency(Cur, s.HalfTrans);
                    _current--; if (_current < 1) _current = Count;
                    WindowManager.PulseTop(Cur);
                    WindowManager.SetTransparency(Cur, s.FocusTrans);
                    ShowTitle();
                    _wheelCountCheck--;
                }
            }
        }
    }
}
