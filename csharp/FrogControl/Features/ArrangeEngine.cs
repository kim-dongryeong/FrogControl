using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Port of Show_Windows(vProcessName, vID, girdMode) from lib/FC_Arrange.ahk.
/// Collects the same-type windows, optionally sends them to the bottom when one is
/// already on top, then lays them out either into a grid (gridMode = 1) or "spread"
/// (gridMode = 0) on the primary monitor's work area. Geometry math mirrors the AHK
/// original exactly; DWM_WinMove -> DwmHelper.WinMove rounds internally.
///
/// Runs on a background worker thread; WindowManager/DwmHelper use SetWindowPos which
/// is thread-safe. No Sleeps.
/// </summary>
public static class ArrangeEngine
{
    // gridMode: 1 = grid layout, 0 = spread layout. Exactly one of processName / id is non-empty.
    public static void ShowWindows(string processName, IntPtr id, int gridMode)
    {
        // ---- Monitors (SysGet Monitor / MonitorWorkArea) ----------------------------
        var mon = MonitorInfo.Collect();
        var p = mon.Primary;                      // monitor_%monitor_no_prm%_*
        double workLeft = p.WorkLeft;
        double workTop = p.WorkTop;
        double workRight = p.WorkRight;
        double workBottom = p.WorkBottom;
        double workWidth = p.WorkWidth;           // monitor_*_workarea_width
        double workHeight = p.WorkHeight;         // monitor_*_workarea_height
        double workRatio = p.WorkRatio;           // height / width
        double workCenterX = p.WorkCenterX;
        double workCenterY = p.WorkCenterY;

        // ---- Same-type window list ---------------------------------------------------
        List<WindowInfo> list;
        if (!string.IsNullOrEmpty(processName))
            list = WindowEnumerator.SameType(IntPtr.Zero, processName);
        else if (id != IntPtr.Zero)
            list = WindowEnumerator.SameType(id, "");
        else
            return;

        // No matching window: optionally launch the process, then stop.
        if (list.Count < 1)
        {
            if (!string.IsNullOrEmpty(processName))
            {
                try { Process.Start(new ProcessStartInfo(processName) { UseShellExecute = true }); }
                catch { /* launch is best-effort */ }
            }
            return;
        }

        _ = list[0].Class;                         // vClass in AHK; captured but unused downstream.
        var fullList = WindowEnumerator.List();    // AltTab_List := AltTab_window_list()

        // ---- Send all same-type windows to the bottom if one is currently on top -----
        int windowsSentToBottom = 0;
        _ = WindowManager.GetClass(WindowManager.Active);  // WinGetClass, class_currentActive, A (filter is commented out in AHK)
        IntPtr activeWinId = WindowManager.Active;          // WinGet, activeWin_ID, ID, A

        for (int i = 0; i < list.Count; i++)
        {
            if (list[i].Id != activeWinId)
                continue;

            int activeMomIndex = list[i].MomIndex;
            int activeFExpIndex1 = i + 1;          // 1-based
            // If the window right after the active one is also same-type, keep the active one.
            bool nextSameType = (i + 1 < list.Count) && list[i + 1].MomIndex == activeMomIndex + 1;

            if (nextSameType)
            {
                for (int j = 0; j < list.Count; j++)
                {
                    if (j + 1 == activeFExpIndex1)
                        continue;
                    WindowManager.SetBottom(list[j].Id);
                    windowsSentToBottom = 1;
                }
            }
            else if (!string.IsNullOrEmpty(processName))
            {
                for (int k = 0; k < list.Count; k++)
                {
                    WindowManager.SetBottom(list[k].Id);
                    windowsSentToBottom = 1;
                    if (list[k].Id == activeWinId)
                    {
                        int fexpIndex1 = k + 1;
                        int momIndex = list[k].MomIndex;
                        // Walk the momIndex chain until it breaks; activate the window past the run.
                        for (int m = 1; ; m++)
                        {
                            int nextIdx1 = fexpIndex1 + m;   // 1-based into same-type list
                            bool mismatch = nextIdx1 > list.Count
                                || list[nextIdx1 - 1].MomIndex != momIndex + m;   // AHK reads blank (=> mismatch) past the end
                            if (mismatch)
                            {
                                int toActivate1 = momIndex + m;  // 1-based into full alt-tab list
                                if (toActivate1 >= 1 && toActivate1 <= fullList.Count)
                                    WindowManager.Activate(fullList[toActivate1 - 1].Id);
                                break;
                            }
                        }
                    }
                }
            }
            break;
        }

        // =============================================================================
        //  GRID MODE (gridMode = 1)
        // =============================================================================
        if (windowsSentToBottom == 0 && gridMode == 1)
        {
            // Unminimize/unmaximize each window (so WinMove works & sizes read correctly),
            // and tag the monitor its centre lands on (per-monitor sums in AHK are unused).
            foreach (var w in list)
            {
                WindowManager.Restore(w.Id);
                WindowManager.GetPos(w.Id, out int tx, out int ty, out int tw, out int th);
                w.Mon = mon.FromRectCenter(tx, ty, tw, th).Index;
            }

            int count = list.Count;
            int gridNoX = (int)Math.Ceiling(Math.Sqrt(count * workWidth / workHeight));
            if (gridNoX < 1) gridNoX = 1;
            int gridNoY = (int)Math.Ceiling((double)count / gridNoX);
            if (gridNoY < 1) gridNoY = 1;
            double gridWidth = workWidth / gridNoX;
            double gridHeight = workHeight / gridNoY;

            int counterRvs = count;                            // 1-based index into list
            int lastGridX = (int)Math.Ceiling((double)count / gridNoY);
            int lastGridY = (count % gridNoY == 0) ? gridNoY : (count % gridNoY);
            bool stillEmpty = true;

            for (int a = 1; a <= lastGridX; a++)               // columns, from the right
            {
                int loop1Rev = lastGridX - a + 1;
                for (int b = 1; b <= gridNoY; b++)             // rows, from the bottom
                {
                    int loop2Rev = gridNoY - b + 1;
                    if (loop2Rev > lastGridY && stillEmpty)
                        continue;                              // skip the empty tail cells of the last column
                    stillEmpty = false;
                    if (counterRvs >= 1 && counterRvs <= list.Count)
                    {
                        var w = list[counterRvs - 1];
                        DwmHelper.WinMove(w.Id,
                            workLeft + gridWidth * (loop1Rev - 1),
                            workTop + gridHeight * (loop2Rev - 1),
                            gridWidth, gridHeight);
                        WindowManager.PulseTop(w.Id);
                    }
                    counterRvs--;
                }
            }
            WindowManager.Activate(list[0].Id);
        }

        // =============================================================================
        //  SPREAD MODE (gridMode = 0)
        // =============================================================================
        else if (windowsSentToBottom == 0 && gridMode == 0)
        {
            double allW = 0, allH = 0, maxW = 0, maxH = 0;

            // Measure each window's VISIBLE frame; store on the (cloned) list objects.
            foreach (var w in list)
            {
                WindowManager.Restore(w.Id);                    // "this is the problem" — restore first
                WindowManager.GetPos(w.Id, out int tx, out int ty, out int tw, out int th);
                DwmHelper.GetVisibleRect(w.Id, ref tx, ref ty, ref tw, ref th);
                w.X = tx; w.Y = ty; w.Width = tw; w.Height = th;
                allW += tw; allH += th;
                if (maxW < tw) maxW = tw;
                if (maxH < th) maxH = th;
                w.Mon = mon.FromRectCenter(tx, ty, tw, th).Index;
            }

            // ---------- horizontal fit: all widths fit in one row --------------------
            if (allW <= workWidth)
            {
                double left = workCenterX - allW / 2;
                double top = workCenterY - maxH / 2;
                for (int a = 1; a <= list.Count; a++)
                {
                    var w = list[list.Count - a];               // temp_index = length - A_Index + 1
                    DwmHelper.WinMove(w.Id, left, top);
                    WindowManager.PulseTop(w.Id);
                    left += w.Width;
                }
                WindowManager.Activate(list[0].Id);
            }
            // ---------- vertical fit: all heights fit in one column ------------------
            else if (allH <= workHeight)
            {
                double left = workCenterX - maxW / 2;
                double top = workCenterY - allH / 2;
                for (int a = 1; a <= list.Count; a++)
                {
                    var w = list[list.Count - a];
                    DwmHelper.WinMove(w.Id, left, top);
                    WindowManager.PulseTop(w.Id);
                    top += w.Height;
                }
                WindowManager.Activate(list[0].Id);
            }
            // ---------- narrow screen: overlapping diagonal --------------------------
            else if (Math.Floor(workWidth / 800.0) <= 1 || Math.Floor(workHeight / 450.0) <= 1)
            {
                double left = workLeft, top = workTop;
                double endX = workRight - list[0].Width;        // top window ends bottom-right
                double endY = workBottom - list[0].Height;
                double stepW = (endX - left) / (list.Count - 1);
                double stepH = (endY - top) / (list.Count - 1);
                for (int a = 1; a <= list.Count; a++)
                {
                    var w = list[list.Count - a];
                    DwmHelper.WinMove(w.Id, left + stepW * (a - 1), top + stepH * (a - 1));
                    WindowManager.PulseTop(w.Id);
                }
                WindowManager.Activate(list[0].Id);
            }
            // ---------- exactly 3 windows: normalized L-shaped stack -----------------
            else if (list.Count == 3)
            {
                foreach (var w in list)
                {
                    w.WidthNorm = w.Width * workRatio;          // width_norm
                    w.HeightNorm = w.Height;                    // height_norm
                }
                // Shallow-clone-and-sort: shared WindowInfo refs, read only (never mutate .Width/.Height).
                var sortedWNormDesc = list.OrderByDescending(w => w.WidthNorm).ToList();
                var sortedHNormDesc = list.OrderByDescending(w => w.HeightNorm).ToList();

                if (sortedWNormDesc[0].WidthNorm > sortedHNormDesc[0].Height)
                {
                    // --- horizontal max bigger than vertical max ---
                    IntPtr bottomId = sortedWNormDesc[0].Id;
                    double bottomHNorm = sortedWNormDesc[0].Height;   // .height (not height_norm)
                    IntPtr leftId = IntPtr.Zero, rightId = IntPtr.Zero;
                    double leftWNorm = 0, leftHNorm = 0, rightWNorm = 0;

                    double sumOthersWNorm = 0;                        // sum of widths except the longest
                    for (int a = 1; a <= list.Count - 1; a++)
                        sumOthersWNorm += sortedWNormDesc[a].WidthNorm;
                    double overWNorm = sumOthersWNorm - workWidth * workRatio > 0
                        ? sumOthersWNorm - workWidth * workRatio : 0;
                    double horizNetNorm = sumOthersWNorm - overWNorm > sortedWNormDesc[0].WidthNorm
                        ? sumOthersWNorm - overWNorm : sortedWNormDesc[0].WidthNorm;
                    horizNetNorm = horizNetNorm < workWidth ? horizNetNorm : workWidth;

                    double overH, verticalNet;
                    if (sortedWNormDesc[0].Id == sortedHNormDesc[0].Id)
                    {
                        // longest width AND longest height are the same window
                        rightId = sortedHNormDesc[1].Id;
                        rightWNorm = sortedHNormDesc[1].WidthNorm;
                        leftId = sortedHNormDesc[2].Id;
                        leftWNorm = sortedHNormDesc[2].WidthNorm;
                        leftHNorm = sortedHNormDesc[2].Height;
                        double verticalLength = sortedWNormDesc[0].Height + sortedHNormDesc[1].Height;
                        overH = verticalLength - workHeight > 0 ? verticalLength - workHeight : 0;
                        verticalNet = verticalLength - overH;
                    }
                    else
                    {
                        // longest width but NOT longest height
                        rightId = sortedHNormDesc[0].Id;
                        rightWNorm = sortedHNormDesc[0].WidthNorm;
                        foreach (var w in list)                       // find the remaining (upper-left) window
                        {
                            if (w.Id != rightId && w.Id != bottomId)
                            {
                                leftId = w.Id;
                                leftWNorm = w.WidthNorm;
                                leftHNorm = w.HeightNorm;
                                break;
                            }
                        }
                        double verticalLength = sortedWNormDesc[0].Height + sortedHNormDesc[0].Height;
                        overH = verticalLength - workHeight > 0 ? verticalLength - workHeight : 0;
                        verticalNet = verticalLength - overH;
                    }

                    if (overWNorm > 0)
                    {
                        DwmHelper.WinMove(leftId, workLeft, workTop);
                        DwmHelper.WinMove(bottomId, workLeft, workBottom - bottomHNorm);
                        double rightYAdj = (allH - workHeight) / 2 * 1.5;   // 1.5 adjustment ratio
                        DwmHelper.WinMove(rightId, workRight - rightWNorm / workRatio, leftHNorm - rightYAdj);
                    }
                    else if (overH > 0)
                    {
                        if (leftHNorm + bottomHNorm < workHeight)
                            DwmHelper.WinMove(leftId, workRight - (rightWNorm + leftWNorm) / workRatio,
                                workBottom - bottomHNorm - leftHNorm);
                        else
                            DwmHelper.WinMove(leftId, workRight - (rightWNorm + leftWNorm) / workRatio, workTop);
                        DwmHelper.WinMove(bottomId, workLeft, workBottom - bottomHNorm);
                        DwmHelper.WinMove(rightId, workRight - rightWNorm / workRatio, workTop);
                    }
                    else // !overWNorm && !overH: centre the stack
                    {
                        double sLeft = workCenterX - horizNetNorm / workRatio / 2;
                        double sTop = workCenterY - verticalNet / 2;
                        double sRight = sLeft + horizNetNorm / workRatio;
                        double sBottom = sTop + verticalNet;
                        DwmHelper.WinMove(leftId, sRight - (rightWNorm + leftWNorm) / workRatio,
                            sBottom - bottomHNorm - leftHNorm);
                        DwmHelper.WinMove(bottomId, sLeft, sBottom - bottomHNorm);
                        DwmHelper.WinMove(rightId, sRight - rightWNorm / workRatio, sTop);
                    }

                    WindowManager.PulseTop(leftId);
                    WindowManager.PulseTop(rightId);
                    WindowManager.PulseTop(bottomId);
                    WindowManager.Activate(list[0].Id);
                }
                else
                {
                    // --- vertical max bigger than horizontal max ---
                    IntPtr rightId = sortedHNormDesc[0].Id;
                    double rightHNorm = sortedHNormDesc[0].Height;
                    double rightWNorm = sortedHNormDesc[0].WidthNorm;
                    IntPtr topId = IntPtr.Zero, bottomId = IntPtr.Zero;
                    double topHNorm = 0, topWNorm = 0, bottomHNorm = 0;

                    double sumOthersH = 0;                            // sum of heights except the longest
                    for (int a = 1; a <= list.Count - 1; a++)
                        sumOthersH += sortedHNormDesc[a].Height;
                    double overH = sumOthersH - workHeight > 0 ? sumOthersH - workHeight : 0;
                    double verticalNet = sumOthersH - overH > sortedHNormDesc[0].Height
                        ? sumOthersH - overH : sortedHNormDesc[0].Height;
                    verticalNet = verticalNet < workHeight ? verticalNet : workHeight;

                    double overWNorm, horizNetNorm;
                    if (sortedHNormDesc[0].Id == sortedWNormDesc[0].Id)
                    {
                        bottomId = sortedWNormDesc[1].Id;
                        bottomHNorm = sortedWNormDesc[1].Height;
                        topId = sortedWNormDesc[2].Id;
                        topHNorm = sortedWNormDesc[2].Height;
                        topWNorm = sortedWNormDesc[2].WidthNorm;
                        double horizNorm = sortedHNormDesc[0].WidthNorm + sortedWNormDesc[1].WidthNorm;
                        overWNorm = horizNorm - workWidth * workRatio > 0
                            ? horizNorm - workWidth * workRatio : 0;
                        horizNetNorm = horizNorm - overWNorm;
                    }
                    else
                    {
                        bottomId = sortedWNormDesc[0].Id;
                        bottomHNorm = sortedWNormDesc[0].Height;
                        foreach (var w in list)
                        {
                            if (w.Id != bottomId && w.Id != rightId)
                            {
                                topId = w.Id;
                                topHNorm = w.HeightNorm;
                                topWNorm = w.WidthNorm;
                                break;
                            }
                        }
                        double horizNorm = sortedHNormDesc[0].WidthNorm + sortedWNormDesc[0].WidthNorm;
                        overWNorm = horizNorm - workWidth * workRatio > 0
                            ? horizNorm - workWidth * workRatio : 0;
                        horizNetNorm = horizNorm - overWNorm;
                    }

                    if (overH > 0)
                    {
                        DwmHelper.WinMove(topId, workLeft, workTop);
                        DwmHelper.WinMove(rightId, workRight - rightWNorm / workRatio, workTop);
                        double bottomXAdj = (allW - workWidth) / 2 * 1.5;  // 1.5 adjustment ratio (not normalized)
                        DwmHelper.WinMove(bottomId, topWNorm / workRatio - bottomXAdj, workBottom - bottomHNorm);
                    }
                    else if (overWNorm > 0)
                    {
                        if (topWNorm + rightWNorm < workWidth * workRatio)
                            DwmHelper.WinMove(topId, workRight - (rightWNorm + topWNorm) / workRatio,
                                workBottom - (bottomHNorm + topHNorm));
                        else
                            DwmHelper.WinMove(topId, workLeft, workBottom - (bottomHNorm + topHNorm));
                        DwmHelper.WinMove(rightId, workRight - rightWNorm / workRatio, workTop);
                        DwmHelper.WinMove(bottomId, workLeft, workBottom - bottomHNorm);
                    }
                    else // !overH && !overWNorm: centre the stack
                    {
                        double sTop = workCenterY - verticalNet / 2;
                        double sLeft = workCenterX - horizNetNorm / workRatio / 2;
                        double sBottom = sTop + verticalNet;
                        double sRight = sLeft + horizNetNorm / workRatio;
                        DwmHelper.WinMove(topId, sRight - (rightWNorm + topWNorm) / workRatio,
                            sBottom - (bottomHNorm + topHNorm));
                        DwmHelper.WinMove(rightId, sRight - rightWNorm / workRatio, sTop);
                        DwmHelper.WinMove(bottomId, sLeft, sBottom - bottomHNorm);
                    }

                    WindowManager.PulseTop(topId);
                    WindowManager.PulseTop(bottomId);
                    WindowManager.PulseTop(rightId);
                    WindowManager.Activate(list[0].Id);
                }
            }
            // ---------- exactly 4 windows: 2x2 quadrant, wider-on-left ----------------
            else if (list.Count == 4)
            {
                //   (1,2)-(2,2)   1 - 2
                //   (1,1)-(2,1)   4 - 3
                var sortedHeightDesc = list.OrderByDescending(w => w.Height).ToList();

                // Bottom-left (shortest), bottom-right, top-left (tallest), top-right.
                IntPtr s11Id = sortedHeightDesc[3].Id; double s11W = sortedHeightDesc[3].Width; double s11H = sortedHeightDesc[3].Height;
                double s11X = workCenterX - s11W, s11Y = workCenterY;

                IntPtr s21Id = sortedHeightDesc[2].Id; double s21W = sortedHeightDesc[2].Width; double s21H = sortedHeightDesc[2].Height;
                double s21X = workCenterX, s21Y = workCenterY;

                IntPtr s12Id = sortedHeightDesc[0].Id; double s12W = sortedHeightDesc[0].Width; double s12H = sortedHeightDesc[0].Height;
                double s12X = workCenterX - s12W, s12Y = workCenterY - s12H;

                IntPtr s22Id = sortedHeightDesc[1].Id; double s22W = sortedHeightDesc[1].Width; double s22H = sortedHeightDesc[1].Height;
                double s22X = workCenterX, s22Y = workCenterY - s22H;

                // Put the wider one on the left of each row.
                if (s11W < s21W)
                {
                    (s11Id, s21Id) = (s21Id, s11Id);
                    (s11W, s21W) = (s21W, s11W);
                    (s11H, s21H) = (s21H, s11H);
                    s11X = workCenterX - s11W; s11Y = workCenterY;
                    s21X = workCenterX; s21Y = workCenterY;
                }
                if (s12W < s22W)
                {
                    (s12Id, s22Id) = (s22Id, s12Id);
                    (s12W, s22W) = (s22W, s12W);
                    (s12H, s22H) = (s22H, s12H);
                    s12X = workCenterX - s12W; s12Y = workCenterY - s12H;
                    s22X = workCenterX; s22Y = workCenterY - s22H;
                }

                double halfW = workWidth / 2, halfH = workHeight / 2;

                // Adjust X — bottom row
                bool b11 = s11W > halfW, b21 = s21W > halfW;
                if ((b11 && !b21) || (!b11 && b21))
                {
                    if (s11W + s21W > workWidth)
                    {
                        s11X = workLeft;
                        s21X = workCenterX > workRight - s21W ? workCenterX : workRight - s21W;
                    }
                    else { s11X = workLeft; s21X = s11X + s11W; }
                }
                else if (b11 && b21) { s11X = workLeft; s21X = workCenterX; }

                // Adjust X — top row
                bool b12 = s12W > halfW, b22 = s22W > halfW;
                if ((b12 && !b22) || (!b12 && b22))
                {
                    if (s12W + s22W > workWidth)
                    {
                        s12X = workLeft;
                        s22X = s22W > halfW ? workCenterX : workRight - s22W;
                    }
                    else { s12X = workLeft; s22X = s12X + s12W; }
                }
                else if (b12 && b22) { s12X = workLeft; s22X = workCenterX; }

                // Adjust Y — left column (top s12, bottom s11)
                bool h12 = s12H > halfH, h11 = s11H > halfH;
                if ((h12 && !h11) || (!h12 && h11))
                {
                    if (s12H + s11H > workHeight)
                    {
                        s12Y = workTop;
                        s11Y = workCenterY > workBottom - s11H ? workCenterY : workBottom - s11H;
                    }
                    else { s12Y = workTop; s11Y = s12Y + s12H; }
                }
                else if (h12 && h11) { s12Y = workTop; s11Y = workCenterY; }

                // Adjust Y — right column (top s22, bottom s21)
                bool h22 = s22H > halfH, h21 = s21H > halfH;
                if ((h22 && !h21) || (!h22 && h21))
                {
                    if (s22H + s21H > workHeight)
                    {
                        s22Y = workTop;
                        s21Y = s21H > halfH ? workCenterY : workBottom - s21H;
                    }
                    else { s22Y = workTop; s21Y = s22Y + s22H; }
                }
                else if (h22 && h21) { s22Y = workTop; s21Y = workCenterY; }

                DwmHelper.WinMove(s11Id, s11X, s11Y);
                DwmHelper.WinMove(s12Id, s12X, s12Y);
                DwmHelper.WinMove(s21Id, s21X, s21Y);
                DwmHelper.WinMove(s22Id, s22X, s22Y);

                // Raise all four (On then Off), in the AHK order.
                WindowManager.SetAlwaysOnTop(s12Id, true);
                WindowManager.SetAlwaysOnTop(s22Id, true);
                WindowManager.SetAlwaysOnTop(s11Id, true);
                WindowManager.SetAlwaysOnTop(s21Id, true);
                WindowManager.SetAlwaysOnTop(s12Id, false);
                WindowManager.SetAlwaysOnTop(s22Id, false);
                WindowManager.SetAlwaysOnTop(s11Id, false);
                WindowManager.SetAlwaysOnTop(s21Id, false);

                WindowManager.Activate(list[0].Id);
            }
            // ---------- 5+ windows: 4 corners + the rest on the diagonal --------------
            else if (list.Count >= 5)
            {
                //   (1,2)-(2,2)   n - 3
                //       mid     ..,5,4     (1st = largest by area, nth = smallest)
                //   (1,1)-(2,1)   2 - 1
                int onDiag = list.Count - 4;
                var sortedAreaDesc = list.OrderByDescending(w => w.Area).ToList();

                // Four corners (differently from the 4-window case: pushed to the edges).
                IntPtr s11Id = sortedAreaDesc[1].Id; double s11H = sortedAreaDesc[1].Height;     // bottom-left
                double s11X = workLeft, s11Y = workBottom - s11H;

                IntPtr s21Id = sortedAreaDesc[0].Id; double s21W = sortedAreaDesc[0].Width; double s21H = sortedAreaDesc[0].Height; // bottom-right (largest)
                double s21X = workRight - s21W, s21Y = workBottom - s21H;

                int nWin = list.Count;
                IntPtr s12Id = sortedAreaDesc[nWin - 1].Id;                                       // top-left (smallest)
                double s12X = workLeft, s12Y = workTop;

                IntPtr s22Id = sortedAreaDesc[2].Id; double s22W = sortedAreaDesc[2].Width;       // top-right
                double s22X = workRight - s22W, s22Y = workTop;

                DwmHelper.WinMove(s11Id, s11X, s11Y);
                DwmHelper.WinMove(s12Id, s12X, s12Y);
                DwmHelper.WinMove(s21Id, s21X, s21Y);
                DwmHelper.WinMove(s22Id, s22X, s22Y);
                WindowManager.PulseTop(s12Id);
                WindowManager.PulseTop(s22Id);
                WindowManager.PulseTop(s11Id);

                // Remaining windows (ranks 4..n-1 by area) go on the diagonal, overlapping.
                double dLeft = workLeft, dTop = workTop;
                double dEndX = workRight - s21W;
                double dEndY = workBottom - s21H;
                double stepW = (dEndX - dLeft) / (onDiag + 1);
                double stepH = (dEndY - dTop) / (onDiag + 1);
                for (int a = 1; a <= onDiag; a++)
                {
                    int ti = list.Count - a;                    // 1-based: n-1, n-2, ...
                    if (ti >= 1 && ti <= sortedAreaDesc.Count)
                    {
                        var w = sortedAreaDesc[ti - 1];
                        DwmHelper.WinMove(w.Id, dLeft + stepW * a, dTop + stepH * a);
                        WindowManager.PulseTop(w.Id);
                    }
                }

                WindowManager.PulseTop(s21Id);
                WindowManager.Activate(list[0].Id);
            }
            // ---------- fallback: overlapping diagonal --------------------------------
            else
            {
                double left = workLeft, top = workTop;
                double endX = workRight - list[0].Width;
                double endY = workBottom - list[0].Height;
                double stepW = (endX - left) / (list.Count - 1);
                double stepH = (endY - top) / (list.Count - 1);
                for (int a = 1; a <= list.Count; a++)
                {
                    var w = list[list.Count - a];
                    DwmHelper.WinMove(w.Id, left + stepW * (a - 1), top + stepH * (a - 1));
                    WindowManager.PulseTop(w.Id);
                }
                WindowManager.Activate(list[0].Id);
            }
        }
    }
}
