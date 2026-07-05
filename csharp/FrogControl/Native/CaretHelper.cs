using System.Runtime.InteropServices;

namespace FrogControl.Native;

/// <summary>Best-effort caret screen position (A_CaretX / A_CaretY) for the date/time input tooltip.</summary>
public static class CaretHelper
{
    [StructLayout(LayoutKind.Sequential)]
    private struct GUITHREADINFO
    {
        public int cbSize;
        public uint flags;
        public IntPtr hwndActive;
        public IntPtr hwndFocus;
        public IntPtr hwndCapture;
        public IntPtr hwndMenuOwner;
        public IntPtr hwndMoveSize;
        public IntPtr hwndCaret;
        public Win32.RECT rcCaret;
    }

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetGUIThreadInfo(uint idThread, ref GUITHREADINFO lpgui);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ClientToScreen(IntPtr hWnd, ref Win32.POINT lpPoint);

    /// <summary>Returns true and (x,y) screen coords of the caret; false if no caret is exposed.</summary>
    public static bool TryGetCaret(out int x, out int y)
    {
        x = y = 0;
        IntPtr fg = Win32.GetForegroundWindow();
        uint tid = Win32.GetWindowThreadProcessId(fg, out _);
        var gti = new GUITHREADINFO { cbSize = Marshal.SizeOf<GUITHREADINFO>() };
        if (!GetGUIThreadInfo(tid, ref gti) || gti.hwndCaret == IntPtr.Zero)
            return false;
        var pt = new Win32.POINT(gti.rcCaret.Left, gti.rcCaret.Top);
        if (!ClientToScreen(gti.hwndCaret, ref pt))
            return false;
        // reject a degenerate (0,0) caret rect that some apps report
        if (gti.rcCaret.Left == 0 && gti.rcCaret.Top == 0 && gti.rcCaret.Right == 0 && gti.rcCaret.Bottom == 0)
            return false;
        x = pt.X; y = pt.Y;
        return true;
    }
}
