using FrogControl.Input;
using FrogControl.Native;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// CapsLock + left-click-drag to move a window (port of the CapsLock &amp; LButton block).
///   Drag to a corner/edge/top zone -> Aero-snap to half/quarter/maximize.
///   Hold Shift -> constrain movement to one axis.  Hold Alt -> free move, no snapping.
///   Hold Ctrl -> activate the dragged window.        Esc -> cancel (restore original).
/// Runs on a detached thread until the left button is released.
/// </summary>
public static class MouseDragMove
{
    public static volatile bool Active;   // engine suppresses LButton up while true

    public static void Start()
    {
        if (FrogControl.App.FlagConstrainedMouse) return;
        if (Active) return;
        Active = true;
        try { Run(); }
        finally { Active = false; }
    }

    private static void Run()
    {
        var s = FrogControl.App.Settings;
        InputSimulator.GetCursor(out int startX, out int startY);
        IntPtr win = Win32.WindowFromPoint(new Win32.POINT(startX, startY));
        if (win != IntPtr.Zero)
        {
            IntPtr root = Win32.GetAncestor(win, Win32.GA_ROOT);
            if (root != IntPtr.Zero) win = root;
        }
        if (win == IntPtr.Zero) return;

        if (KeyState.Ctrl) WindowManager.Activate(win);

        var mon = MonitorInfo.Collect();

        int isMaxStart = WindowManager.MinMax(win);
        double origX = 0, origY = 0, W = 0, H = 0;
        int originalMax = 0;
        double shortX = 0, shortY = 0;
        int maxQuadrant = -1;
        double maxWinX = 0, maxWinY = 0, maxWinW = 0, maxWinH = 0;

        if (isMaxStart == 0)
        {
            WindowManager.GetPos(win, out int ox, out int oy, out int ow, out int oh);
            origX = ox; origY = oy; W = ow; H = oh;
            originalMax = 0;
        }
        else if (isMaxStart == 1)
        {
            originalMax = 1;
            WindowManager.GetPos(win, out int mx, out int my, out int mw, out int mh);
            maxWinX = mx; maxWinY = my; maxWinW = mw; maxWinH = mh;
            maxQuadrant = -1;
            shortX = maxWinX + maxWinW - startX;
            shortY = maxWinY + maxWinH - startY;
            if (startX - maxWinX < maxWinW / 2) { shortX = startX - maxWinX; maxQuadrant *= 2; }
            if (startY - maxWinY < maxWinH / 2) { shortY = startY - maxWinY; maxQuadrant *= -1; }
        }

        while (true)
        {
            Thread.Sleep(10);
            if (!KeyState.IsDown(Win32.VK_LBUTTON)) return;   // released -> done
            if (KeyState.Escape)
            {
                if (originalMax == 1 || originalMax == 2) WindowManager.Maximize(win);
                else WindowManager.Move(win, origX, origY, W, H);
                return;
            }
            if (KeyState.Ctrl) WindowManager.Activate(win);

            InputSimulator.GetCursor(out int mouseX, out int mouseY);
            int isMax = WindowManager.MinMax(win);

            var m = mon.FromPoint(mouseX + 0.5, mouseY + 0.5);
            if (m == null) continue;

            double wl = m.WorkLeft, wt = m.WorkTop, wr = m.WorkRight, wb = m.WorkBottom;
            double ww = m.WorkWidth, wh = m.WorkHeight;

            if (KeyState.Shift)
            {
                // straight move: lock to whichever axis moved more
                double det = Math.Abs(mouseX - startX) - Math.Abs(mouseY - startY);
                int step = (int)Math.Floor(Math.Exp(det - Math.Abs(det)));  // 1 if x-dominant else 0
                WindowManager.Move(win, origX + (mouseX - startX) * step, origY + (mouseY - startY) * (1 - step), W, H);
                continue;
            }

            if (!KeyState.Alt)
            {
                if (mouseX < wl + s.CapsMoveCorner && mouseY < wt + s.CapsMoveCorner)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl, wt, ww / 2, wh / 2); }
                else if (mouseX > wr - s.CapsMoveCorner && mouseY < wt + s.CapsMoveCorner)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl + ww / 2, wt, ww / 2, wh / 2); }
                else if (mouseX > wr - s.CapsMoveCorner && mouseY > wb - s.CapsMoveCorner)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl + ww / 2, wt + wh / 2, ww / 2, wh / 2); }
                else if (mouseX < wl + s.CapsMoveCorner && mouseY > wb - s.CapsMoveCorner)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl, wt + wh / 2, ww / 2, wh / 2); }
                else if (mouseX < wl + s.CapsMoveLrb)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl, wt, ww / 2, wh); }
                else if (mouseY < wt + s.CapsMoveTop)
                {
                    if (isMax == 0)
                        WindowManager.Move(win, (wl + wr) / 2 - W / 2, (wt + wb) / 2 - H / 2, W, H);
                    WindowManager.Maximize(win);
                }
                else if (mouseY < wt + s.CapsMoveHalfTop)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl, wt, ww, wh / 2); }
                else if (mouseX > wr - s.CapsMoveLrb)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl + ww / 2, wt, ww / 2, wh); }
                else if (mouseY > wb - s.CapsMoveLrb)
                { RestoreIfMax(win, isMax, ref W, ref H); DwmHelper.WinMove(win, wl, wt + wh / 2, ww, wh / 2); }
                else
                {
                    // free move (outside snap zones)
                    RestoreIfMax(win, isMax, ref W, ref H);
                    if (originalMax == 1)
                    {
                        AdjustFromMax(ref origX, ref origY, startX, startY, W, H, shortX, shortY, maxQuadrant);
                        originalMax = 2;
                    }
                    WindowManager.Move(win, origX + mouseX - startX, origY + mouseY - startY, W, H);
                }
            }
            else
            {
                // Alt held: free move, no snapping
                RestoreIfMax(win, isMax, ref W, ref H);
                if (originalMax == 1)
                {
                    AdjustFromMax(ref origX, ref origY, startX, startY, W, H, shortX, shortY, maxQuadrant);
                    originalMax = 2;
                }
                WindowManager.Move(win, origX + mouseX - startX, origY + mouseY - startY, W, H);
            }
        }
    }

    private static void RestoreIfMax(IntPtr win, int isMax, ref double W, ref double H)
    {
        if (isMax == 1)
        {
            WindowManager.Restore(win);
            WindowManager.GetPos(win, out _, out _, out int w, out int h);
            W = w; H = h;
        }
    }

    private static void AdjustFromMax(ref double origX, ref double origY, int startX, int startY,
        double W, double H, double shortX, double shortY, int maxQuadrant)
    {
        origX = startX - (W - shortX);
        origY = startY - (H - shortY);
        if (maxQuadrant > 0) origY = startY - shortY;
        if (Math.Abs(maxQuadrant) == 2) origX = startX - shortX;
        if (W < shortX) origX = startX - W / 2;
        if (H < shortY) origY = startY - H / 2;
    }
}
