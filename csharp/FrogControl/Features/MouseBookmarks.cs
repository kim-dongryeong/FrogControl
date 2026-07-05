using FrogControl.Input;
using FrogControl.UI;

namespace FrogControl.Features;

/// <summary>
/// Mouse position bookmarks at 1..9,0 (port of the CapsLock &amp; 1..0 block).
///   CapsLock + Ctrl + n         -> save current mouse position at n
///   CapsLock + n                -> click at n's (last) bookmark, then return the cursor
///   CapsLock + Shift + n        -> move cursor to n's bookmark (cycling), no click
///   CapsLock + Alt + n          -> delete n's last bookmark
///   CapsLock + Ctrl + Shift + n -> show all of n's bookmark positions
/// </summary>
public static class MouseBookmarks
{
    private static readonly Dictionary<string, List<(int x, int y)>> Store = new();
    private static int _mbIndex;
    private static string _lastKey = "";

    public static void Handle(string key)
    {
        int dur = FrogControl.App.Settings.TooltipDurationShortMs;
        if (key != _lastKey) _mbIndex = 0;
        _lastKey = key;

        if (!Store.TryGetValue(key, out var list))
        {
            list = new List<(int, int)>();
            Store[key] = list;
        }

        InputSimulator.GetCursor(out int mx, out int my);
        bool ctrl = KeyState.Ctrl, shift = KeyState.Shift, alt = KeyState.Alt;

        if (ctrl && !shift)
        {
            list.Add((mx, my));
            ToolTipService.ShowTimed($"Mouse bookmark at {key} ({list.Count}) has been stored.", dur);
        }
        else if (alt)
        {
            if (list.Count >= 1)
            {
                ToolTipService.ShowTimed($"Mouse bookmark at {key} ({list.Count}) has been deleted.", dur);
                list.RemoveAt(list.Count - 1);
            }
            else
            {
                ToolTipService.ShowTimed($"There is no mouse bookmark to delete at {key}.\nYou can bookmark by pressing CapsLock + Ctrl + {key}.", dur);
            }
        }
        else if (!ctrl && shift)
        {
            if (list.Count >= 1)
            {
                _mbIndex = _mbIndex <= 1 ? list.Count : _mbIndex - 1;
                var p = list[_mbIndex - 1];
                InputSimulator.MoveCursor(p.x, p.y);
                ToolTipService.Show($"Mouse bookmark at {key} ({_mbIndex})", 1, p.x + 16, p.y + 16);
                ToolTipService.ShowTimed($"Mouse bookmark at {key} ({_mbIndex})", dur, 1, p.x + 16, p.y + 16);
            }
            else
            {
                ToolTipService.ShowTimed($"There is no mouse bookmark at {key}.\nYou can bookmark by pressing CapsLock + Ctrl + {key}.", dur);
            }
        }
        else if (ctrl && shift)
        {
            if (list.Count >= 1)
                MarkerService.ShowPoints(list, 2000);
            else
                ToolTipService.ShowTimed($"There is no mouse bookmark to show at {key}.", dur);
        }
        else
        {
            // no modifier: click at the last bookmark, then restore the cursor
            if (list.Count >= 1)
            {
                _mbIndex = list.Count;
                var p = list[_mbIndex - 1];
                InputSimulator.GetCursor(out int sx, out int sy);
                InputSimulator.MoveCursor(p.x, p.y);
                InputSimulator.LeftClick();
                InputSimulator.MoveCursor(sx, sy);
                ToolTipService.ShowTimed($"Mouse bookmark at {key} ({_mbIndex})", dur, p.x + 16, p.y + 16);
            }
            else
            {
                ToolTipService.ShowTimed($"There is no mouse bookmark at {key}.\nYou can bookmark by pressing CapsLock + Ctrl + {key}.", dur);
            }
        }
    }
}
