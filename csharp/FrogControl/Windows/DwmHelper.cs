using System.Runtime.InteropServices;
using FrogControl.Native;

namespace FrogControl.Windows;

/// <summary>
/// DWM invisible-border compensation, ported from FC_Helpers.ahk
/// (DWM_WinMove, DWM_GetBorders, DWM_GetVisibleRect).
///
/// Windows 10/11 report a window rect (GetWindowRect) that is ~7 px larger on the
/// left/right/bottom than what the user actually sees; the visible frame is
/// DWMWA_EXTENDED_FRAME_BOUNDS. These helpers make snapped/gridded windows sit flush.
/// </summary>
public static class DwmHelper
{
    /// <summary>Invisible border thickness on each side (0 if DWM info is unavailable).</summary>
    public static bool GetBorders(IntPtr hwnd, out int bL, out int bT, out int bR, out int bB)
    {
        bL = bT = bR = bB = 0;
        if (!Win32.GetWindowRect(hwnd, out var rect))
            return false;
        if (Win32.DwmGetWindowAttribute(hwnd, Win32.DWMWA_EXTENDED_FRAME_BOUNDS, out var ext, Marshal.SizeOf<Win32.RECT>()) != 0)
            return false;
        bL = ext.Left - rect.Left;
        bT = ext.Top - rect.Top;
        bR = rect.Right - ext.Right;
        bB = rect.Bottom - ext.Bottom;
        return true;
    }

    /// <summary>
    /// If DWM info is available, overwrite x/y/w/h with the VISIBLE frame rect
    /// (DWMWA_EXTENDED_FRAME_BOUNDS); otherwise leave them untouched.
    /// </summary>
    public static void GetVisibleRect(IntPtr hwnd, ref int x, ref int y, ref int w, ref int h)
    {
        if (Win32.DwmGetWindowAttribute(hwnd, Win32.DWMWA_EXTENDED_FRAME_BOUNDS, out var ext, Marshal.SizeOf<Win32.RECT>()) == 0)
        {
            x = ext.Left;
            y = ext.Top;
            w = ext.Right - x;
            h = ext.Bottom - y;
        }
    }

    /// <summary>
    /// Move/resize so the window's VISIBLE frame lands exactly on the given rectangle.
    /// Null parameters leave that dimension unchanged (like WinMove with a blank arg).
    /// Port of DWM_WinMove().
    /// </summary>
    public static void WinMove(IntPtr hwnd, double? x, double? y, double? w = null, double? h = null)
    {
        if (hwnd == IntPtr.Zero || !Win32.IsWindow(hwnd))
            return;

        if (!GetBorders(hwnd, out int bL, out int bT, out int bR, out int bB))
        {
            // DWM unavailable: behave like a plain WinMove.
            WindowManager.Move(hwnd, x, y, w, h);
            return;
        }

        double? nx = x.HasValue ? x.Value - bL : null;
        double? ny = y.HasValue ? y.Value - bT : null;
        double? nw = w.HasValue ? w.Value + bL + bR : null;
        double? nh = h.HasValue ? h.Value + bT + bB : null;
        WindowManager.Move(hwnd, nx, ny, nw, nh);
    }
}
