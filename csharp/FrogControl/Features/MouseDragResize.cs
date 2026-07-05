using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// CapsLock + right-click-drag to resize a window (port of the CapsLock &amp; RButton block).
/// The window is split into a 3×3 grid; the grabbed cell decides which edges/corner move.
/// Grabbing the centre cell moves the whole window. The system cursor becomes the matching
/// resize arrow for the duration. Esc cancels; Ctrl activates.
/// </summary>
public static class MouseDragResize
{
    public static volatile bool Active;   // engine suppresses RButton up while true

    public static void Start()
    {
        if (Active) return;
        Active = true;
        int cursorIndicator = 1;
        try { cursorIndicator = Run(); }
        finally
        {
            SystemCursorService.Restore();
            Active = false;
        }
    }

    private static int Run()
    {
        InputSimulator.GetCursor(out int startX, out int startY);
        IntPtr win = Win32.WindowFromPoint(new Win32.POINT(startX, startY));
        if (win != IntPtr.Zero)
        {
            IntPtr root = Win32.GetAncestor(win, Win32.GA_ROOT);
            if (root != IntPtr.Zero) win = root;
        }
        if (win == IntPtr.Zero) return 1;

        WindowManager.GetPos(win, out int origX, out int origY, out int origW, out int origH);

        if (WindowManager.MinMax(win) == 1)
        {
            WindowManager.Restore(win);
            WindowManager.Move(win, origX, origY, origW, origH);
        }

        int indX = startX < origX + origW / 3.0 ? -1 : (startX > origX + origW * 2.0 / 3.0 ? 1 : 0);
        int indY = startY < origY + origH / 3.0 ? -1 : (startY > origY + origH * 2.0 / 3.0 ? 1 : 0);
        int cursorIndicator = Math.Abs(3 * indX + indY) + 1;
        SystemCursorService.Toggle(cursorIndicator);

        int msX = startX, msY = startY;
        while (true)
        {
            Thread.Sleep(10);
            if (!KeyState.IsDown(Win32.VK_RBUTTON)) break;
            if (KeyState.Escape)
            {
                WindowManager.Move(win, origX, origY, origW, origH);
                break;
            }
            if (KeyState.Ctrl) WindowManager.Activate(win);

            InputSimulator.GetCursor(out int mouseX, out int mouseY);
            WindowManager.GetPos(win, out int winX, out int winY, out int curW, out int curH);

            double c = Math.Floor(Math.Abs(Math.Cos(2 * indX + indY)));  // 1 only at the centre cell
            double dx = mouseX - msX, dy = mouseY - msY;
            double newX = winX + Math.Floor((1 - indX) / 2.0) * dx * (1 - c) - dx * c;
            double newY = winY + Math.Floor((1 - indY) / 2.0) * dy * (1 - c) - dy * c;
            double newW = curW + indX * dx * (1 - c) + 2 * dx * c;
            double newH = curH + indY * dy * (1 - c) + 2 * dy * c;
            WindowManager.Move(win, newX, newY, newW, newH);

            msX = mouseX; msY = mouseY;
        }
        return cursorIndicator;
    }
}
