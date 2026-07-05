using System.Runtime.InteropServices;

namespace FrogControl.Native;

/// <summary>Wrappers for the SystemParametersInfo calls the AHK script used (beep, wheel scroll lines).</summary>
public static class SystemParams
{
    public static uint GetBeep()
    {
        uint v = 0;
        Win32.SystemParametersInfo(Win32.SPI_GETBEEP, 0, ref v, 0);
        return v;
    }

    public static void SetBeep(uint enabled)
        => Win32.SystemParametersInfo(Win32.SPI_SETBEEP, enabled, IntPtr.Zero, 0);

    public static uint GetWheelScrollLines()
    {
        uint v = 0;
        Win32.SystemParametersInfo(Win32.SPI_GETWHEELSCROLLLINES, 0, ref v, 0);
        return v;
    }

    public static void SetWheelScrollLines(uint lines)
        => Win32.SystemParametersInfo(Win32.SPI_SETWHEELSCROLLLINES, lines, IntPtr.Zero, 0);

    // ---- Pixel colour under a point (PixelGetColor) ----
    [DllImport("user32.dll")] private static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [DllImport("gdi32.dll")] private static extern uint GetPixel(IntPtr hdc, int x, int y);

    /// <summary>Returns the BGR COLORREF at screen point (x,y), as SetLayeredWindowAttributes expects.</summary>
    public static uint PixelGetColor(int x, int y)
    {
        IntPtr dc = GetDC(IntPtr.Zero);
        try { return GetPixel(dc, x, y); }
        finally { ReleaseDC(IntPtr.Zero, dc); }
    }
}
