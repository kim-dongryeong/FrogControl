using System;
using System.Collections.Generic;
using System.Threading;
using FrogControl.Input;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Port of the AHK "Navigating windows by arrow keys" hotkey (#!^Right/Left/Down/Up,
/// i.e. Win+Ctrl+Alt+Arrow) plus its helpers SeekArrow_Step and SeekArrow_FindNext.
///
/// While Win+Ctrl+Alt is held you press the arrow keys to "seek" through the visible
/// (non-minimized) windows: every window is dimmed to HalfTrans, the currently selected
/// one is highlighted to FocusTrans and pulsed to the top, and its title is shown as a
/// tooltip. Direction selection uses dot/cross scoring (nearest window most directly in
/// the pressed direction wins). Releasing any of Win/Ctrl/Alt commits: the selected window
/// is activated, the original topmost ordering is re-applied, and transparencies are restored.
/// </summary>
public static class WindowSeeker
{
    // Called on Win+Ctrl+Alt+Arrow key-down. Runs the full seek loop on the CURRENT thread
    // (the engine already calls this on a detached background thread). Re-entrant-guarded internally.
    public static void Start()
    {
        // started_windowSeekArrow guard.
        if (!App.TryEnter("windowSeekArrow")) return;
        try
        {
            // AltTab_window_list() + "=== To exclude minimized windows ===".
            // woMin mirrors AltTab_ID_List_woMinWin_* (skip MinMax == -1, i.e. minimized).
            var woMin = new List<WindowInfo>();
            foreach (var w in WindowEnumerator.List())
            {
                if (WindowManager.MinMax(w.Id) == -1)
                    continue; // skip minimized windows
                woMin.Add(w);
            }
            if (woMin.Count == 0) return;

            // Checking WS_EX_TOPMOST windows: 1-based index of the first non-topmost window.
            // AHK leaves it unset when all are topmost; default to 1 as a safe fallback.
            int topOfNontopmost = 1;
            for (int aIndex = 1; aIndex <= woMin.Count; aIndex++)
            {
                if (!WindowManager.IsTopmost(woMin[aIndex - 1].Id))
                {
                    topOfNontopmost = aIndex;
                    break;
                }
            }

            // To make all half transparent (saving the original alpha of each window).
            // GetTransparency() == null means "no alpha set" -> AHK treats that as opaque (255).
            var originalTrans = new int[woMin.Count];
            if (!App.FlagHalfTrans)
            {
                for (int i = 0; i < woMin.Count; i++)
                {
                    originalTrans[i] = WindowManager.GetTransparency(woMin[i].Id) ?? 255;
                    WindowManager.SetTransparency(woMin[i].Id, App.Settings.HalfTrans);
                }
                App.FlagHalfTrans = true;
            }

            // To find the current active window (1-based index into woMin).
            // Default to topOfNontopmost when the active window is not in the list.
            IntPtr activeId = WindowManager.Active;
            int current = topOfNontopmost;
            for (int aIndex = 1; aIndex <= woMin.Count; aIndex++)
            {
                if (woMin[aIndex - 1].Id == activeId)
                    current = aIndex;
            }

            // ---- SeekArrow_FindNext: best window in direction (dirX,dirY) from the current one,
            //      or 0 if none. Positions are queried live (windows may have moved). ----
            int FindNext(int dirX, int dirY)
            {
                WindowManager.GetPos(woMin[current - 1].Id, out int cx, out int cy, out int cw, out int ch);
                double cenx = cx + cw / 2.0;
                double ceny = cy + ch / 2.0;
                int best = 0;
                double bestScore = 0;
                for (int aIndex = 1; aIndex <= woMin.Count; aIndex++)
                {
                    if (aIndex == current)
                        continue;
                    WindowManager.GetPos(woMin[aIndex - 1].Id, out int x, out int y, out int w, out int h);
                    double dx = x + w / 2.0 - cenx;
                    double dy = y + h / 2.0 - ceny;
                    double score;
                    if (dx == 0 && dy == 0)
                    {
                        score = 999999999 + aIndex; // same center: last-resort candidate, cycling in list order
                    }
                    else
                    {
                        double proj = dx * dirX + dy * dirY;
                        if (proj <= 0)
                            continue;
                        score = proj + Math.Abs(dx * dirY - dy * dirX) * 2;
                    }
                    if (best == 0 || score < bestScore)
                    {
                        best = aIndex;
                        bestScore = score;
                    }
                }
                return best;
            }

            // ---- SeekArrow_Step: dim current, pick the best window in the direction,
            //      highlight + raise it, show its title, then wait for the key to release (T0.2). ----
            void Step(int dirX, int dirY, string keyName)
            {
                WindowManager.SetTransparency(woMin[current - 1].Id, App.Settings.HalfTrans);
                int next = FindNext(dirX, dirY);
                if (next != 0)
                    current = next;
                var cur = woMin[current - 1];
                WindowManager.SetTransparency(cur.Id, App.Settings.FocusTrans);
                WindowManager.PulseTop(cur.Id);
                ToolTipService.ShowTimed(WindowManager.GetTitle(cur.Id), App.Settings.TooltipDurationShortMs);

                // KeyWait, keyName, T0.2 : wait for release of the arrow key, up to 200ms,
                // so auto-repeat steps at ~5/s while held; break early once released.
                int vk = VkForKey(keyName);
                for (int elapsed = 0; elapsed < 200; elapsed += 10)
                {
                    if (!KeyState.IsDown(vk))
                        break;
                    Thread.Sleep(10);
                }
            }

            // The main loop to receive arrow key inputs.
            while (true)
            {
                Thread.Sleep(10); // poll ~100x/s instead of busy-waiting (CPU)

                // One shared step per direction (dot/cross scoring picks the target).
                if (KeyState.Right) Step(1, 0, "Right");
                if (KeyState.Left) Step(-1, 0, "Left");
                if (KeyState.Down_) Step(0, 1, "Down");
                if (KeyState.Up) Step(0, -1, "Up");

                // Exit once Win+Ctrl+Alt is no longer all held.
                if (!(KeyState.Win && KeyState.Ctrl && KeyState.Alt))
                {
                    WindowManager.Activate(woMin[current - 1].Id);

                    // To make topmost again (restore the original topmost ordering).
                    for (int aIndex = 1; aIndex <= woMin.Count; aIndex++)
                    {
                        if (aIndex < topOfNontopmost)
                        {
                            int temp = topOfNontopmost - aIndex; // 1-based; re-applied in reverse for correct z-order
                            WindowManager.SetAlwaysOnTop(woMin[temp - 1].Id, true);
                        }
                        else if (aIndex != current)
                        {
                            WindowManager.SetBottom(woMin[aIndex - 1].Id);
                        }
                    }
                    if (current < topOfNontopmost)
                        WindowManager.SetAlwaysOnTop(woMin[current - 1].Id, true);

                    // Restore each window's original transparency.
                    if (App.FlagHalfTrans)
                    {
                        for (int i = 0; i < woMin.Count; i++)
                            WindowManager.SetTransparency(woMin[i].Id, originalTrans[i]);
                    }
                    App.FlagHalfTrans = false;
                    break;
                }
            }
        }
        finally
        {
            App.Exit("windowSeekArrow");
        }
    }

    private static int VkForKey(string keyName) => keyName switch
    {
        "Left" => 0x25,
        "Up" => 0x26,
        "Right" => 0x27,
        "Down" => 0x28,
        _ => 0,
    };
}
