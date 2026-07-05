using System.Diagnostics;
using System.Text;
using FrogControl.Native;

namespace FrogControl.Windows;

/// <summary>
/// The managed equivalent of AHK's Win* commands (WinMove, WinGetPos, WinActivate,
/// WinRestore, WinMaximize, WinMinimize, WinSet Bottom/Top/AlwaysOnTop/Transparent/Style,
/// WinGet Class/ProcessName/…). Every method takes an HWND, mirroring "ahk_id %id%".
/// </summary>
public static class WindowManager
{
    // --------------------------------------------------------------------
    // Query
    // --------------------------------------------------------------------
    public static IntPtr Active => Win32.GetForegroundWindow();

    public static bool Exists(IntPtr hwnd) => hwnd != IntPtr.Zero && Win32.IsWindow(hwnd);

    public static string GetTitle(IntPtr hwnd)
    {
        int len = Win32.GetWindowTextLengthW(hwnd);
        if (len <= 0) return "";
        var sb = new StringBuilder(len + 2);
        Win32.GetWindowTextW(hwnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static string GetClass(IntPtr hwnd)
    {
        var sb = new StringBuilder(256);
        Win32.GetClassNameW(hwnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static long GetStyle(IntPtr hwnd) => Win32.GetWindowLongEx(hwnd, Win32.GWL_STYLE);
    public static long GetExStyle(IntPtr hwnd) => Win32.GetWindowLongEx(hwnd, Win32.GWL_EXSTYLE);

    public static bool IsTopmost(IntPtr hwnd) => (GetExStyle(hwnd) & Win32.WS_EX_TOPMOST) != 0;

    /// <summary>AHK MinMax: 1 = maximized, -1 = minimized, 0 = normal.</summary>
    public static int MinMax(IntPtr hwnd)
    {
        if (Win32.IsIconic(hwnd)) return -1;
        if (Win32.IsZoomed(hwnd)) return 1;
        return 0;
    }

    public static uint GetPid(IntPtr hwnd)
    {
        Win32.GetWindowThreadProcessId(hwnd, out uint pid);
        return pid;
    }

    public static string GetProcessName(IntPtr hwnd)
    {
        try
        {
            uint pid = GetPid(hwnd);
            if (pid == 0) return "";
            using var p = Process.GetProcessById((int)pid);
            return p.ProcessName + ".exe";
        }
        catch { return ""; }
    }

    public static string GetProcessPath(IntPtr hwnd)
    {
        try
        {
            uint pid = GetPid(hwnd);
            if (pid == 0) return "";
            using var p = Process.GetProcessById((int)pid);
            return p.MainModule?.FileName ?? "";
        }
        catch { return ""; }
    }

    /// <summary>WinGetPos: raw window rect (matches GetWindowRect / AHK on Win10+).</summary>
    public static bool GetPos(IntPtr hwnd, out int x, out int y, out int w, out int h)
    {
        x = y = w = h = 0;
        if (!Win32.GetWindowRect(hwnd, out var r))
            return false;
        x = r.Left; y = r.Top; w = r.Width; h = r.Height;
        return true;
    }

    // --------------------------------------------------------------------
    // Move / size (plain, no DWM compensation — see DwmHelper for that)
    // --------------------------------------------------------------------
    public static void Move(IntPtr hwnd, double? x, double? y, double? w = null, double? h = null)
    {
        if (!Exists(hwnd)) return;
        if (!Win32.GetWindowRect(hwnd, out var r)) return;
        int nx = x.HasValue ? Round(x.Value) : r.Left;
        int ny = y.HasValue ? Round(y.Value) : r.Top;
        int nw = w.HasValue ? Round(w.Value) : r.Width;
        int nh = h.HasValue ? Round(h.Value) : r.Height;
        Win32.SetWindowPos(hwnd, IntPtr.Zero, nx, ny, nw, nh,
            Win32.SWP_NOZORDER | Win32.SWP_NOACTIVATE | Win32.SWP_NOOWNERZORDER);
    }

    private static int Round(double v) => (int)Math.Round(v, MidpointRounding.AwayFromZero);

    // --------------------------------------------------------------------
    // State changes
    // --------------------------------------------------------------------
    public static void Restore(IntPtr hwnd) { if (Exists(hwnd)) Win32.ShowWindow(hwnd, Win32.SW_RESTORE); }
    public static void Maximize(IntPtr hwnd) { if (Exists(hwnd)) Win32.ShowWindow(hwnd, Win32.SW_MAXIMIZE); }
    public static void Minimize(IntPtr hwnd) { if (Exists(hwnd)) Win32.ShowWindow(hwnd, Win32.SW_MINIMIZE); }

    public static void SetBottom(IntPtr hwnd)
    {
        // WinSet, Bottom — also revokes WS_EX_TOPMOST, exactly like AHK notes.
        if (!Exists(hwnd)) return;
        Win32.SetWindowPos(hwnd, Win32.HWND_BOTTOM, 0, 0, 0, 0,
            Win32.SWP_NOSIZE | Win32.SWP_NOMOVE | Win32.SWP_NOACTIVATE);
    }

    public static void SetTop(IntPtr hwnd)
    {
        if (!Exists(hwnd)) return;
        Win32.SetWindowPos(hwnd, Win32.HWND_TOP, 0, 0, 0, 0,
            Win32.SWP_NOSIZE | Win32.SWP_NOMOVE | Win32.SWP_NOACTIVATE);
    }

    public static void SetAlwaysOnTop(IntPtr hwnd, bool on)
    {
        if (!Exists(hwnd)) return;
        Win32.SetWindowPos(hwnd, on ? Win32.HWND_TOPMOST : Win32.HWND_NOTOPMOST, 0, 0, 0, 0,
            Win32.SWP_NOSIZE | Win32.SWP_NOMOVE | Win32.SWP_NOACTIVATE);
    }

    public static void ToggleAlwaysOnTop(IntPtr hwnd) => SetAlwaysOnTop(hwnd, !IsTopmost(hwnd));

    /// <summary>PulseTop(): raise a window by briefly making it topmost, then releasing.</summary>
    public static void PulseTop(IntPtr hwnd)
    {
        SetAlwaysOnTop(hwnd, true);
        SetAlwaysOnTop(hwnd, false);
    }

    // --------------------------------------------------------------------
    // Transparency  (WinSet, Transparent / TransColor)
    // --------------------------------------------------------------------
    /// <summary>WinGet Transparent: null means "no alpha set" (AHK treats that as opaque/255).</summary>
    public static int? GetTransparency(IntPtr hwnd)
    {
        if ((GetExStyle(hwnd) & Win32.WS_EX_LAYERED) == 0)
            return null;
        if (Win32.GetLayeredWindowAttributes(hwnd, out _, out byte alpha, out uint flags) && (flags & Win32.LWA_ALPHA) != 0)
            return alpha;
        return null;
    }

    public static void SetTransparency(IntPtr hwnd, int alpha)
    {
        if (!Exists(hwnd)) return;
        alpha = Math.Clamp(alpha, 0, 255);
        long ex = GetExStyle(hwnd);
        if ((ex & Win32.WS_EX_LAYERED) == 0)
            Win32.SetWindowLongEx(hwnd, Win32.GWL_EXSTYLE, ex | Win32.WS_EX_LAYERED);
        Win32.SetLayeredWindowAttributes(hwnd, 0, (byte)alpha, Win32.LWA_ALPHA);
    }

    public static void SetTransColor(IntPtr hwnd, uint colorRef)
    {
        if (!Exists(hwnd)) return;
        long ex = GetExStyle(hwnd);
        if ((ex & Win32.WS_EX_LAYERED) == 0)
            Win32.SetWindowLongEx(hwnd, Win32.GWL_EXSTYLE, ex | Win32.WS_EX_LAYERED);
        Win32.SetLayeredWindowAttributes(hwnd, colorRef, 0, Win32.LWA_COLORKEY);
    }

    // --------------------------------------------------------------------
    // Style toggling  (WinSet, Style, ^0x...)
    // --------------------------------------------------------------------
    public static void ToggleStyle(IntPtr hwnd, long styleBits)
    {
        if (!Exists(hwnd)) return;
        long s = GetStyle(hwnd);
        s ^= styleBits;
        Win32.SetWindowLongEx(hwnd, Win32.GWL_STYLE, s);
        // Force the frame to redraw.
        Win32.SetWindowPos(hwnd, IntPtr.Zero, 0, 0, 0, 0,
            Win32.SWP_NOMOVE | Win32.SWP_NOSIZE | Win32.SWP_NOZORDER | Win32.SWP_NOACTIVATE | 0x0020 /*SWP_FRAMECHANGED*/);
    }

    // --------------------------------------------------------------------
    // Close
    // --------------------------------------------------------------------
    public static void Close(IntPtr hwnd)
    {
        if (Exists(hwnd)) Win32.PostMessage(hwnd, Win32.WM_CLOSE, IntPtr.Zero, IntPtr.Zero);
    }

    // --------------------------------------------------------------------
    // Activation
    // --------------------------------------------------------------------
    /// <summary>
    /// Reliable WinActivate: uses the AttachThreadInput trick so foreground stealing
    /// restrictions don't silently fail (a common problem SetForegroundWindow alone has).
    /// </summary>
    public static void Activate(IntPtr hwnd)
    {
        if (!Exists(hwnd)) return;
        if (Win32.IsIconic(hwnd))
            Win32.ShowWindow(hwnd, Win32.SW_RESTORE);

        IntPtr fg = Win32.GetForegroundWindow();
        if (fg == hwnd) return;

        // Plain backend (A/B option): just SetForegroundWindow, no thread-attach trickery.
        if (FrogControl.App.Settings.ActivationBackend == FrogControl.Config.ActivationBackend.Plain)
        {
            Win32.BringWindowToTop(hwnd);
            Win32.SetForegroundWindow(hwnd);
            return;
        }

        uint fgThread = Win32.GetWindowThreadProcessId(fg, out _);
        uint targetThread = Win32.GetWindowThreadProcessId(hwnd, out _);
        uint thisThread = Win32.GetCurrentThreadId();

        bool attach1 = fgThread != 0 && fgThread != thisThread && Win32.AttachThreadInput(thisThread, fgThread, true);
        bool attach2 = targetThread != 0 && targetThread != thisThread && targetThread != fgThread && Win32.AttachThreadInput(thisThread, targetThread, true);
        try
        {
            Win32.BringWindowToTop(hwnd);
            Win32.SetForegroundWindow(hwnd);
        }
        finally
        {
            if (attach1) Win32.AttachThreadInput(thisThread, fgThread, false);
            if (attach2) Win32.AttachThreadInput(thisThread, targetThread, false);
        }
    }

    /// <summary>
    /// Activate the taskbar (ahk_class Shell_TrayWnd). The AHK script does this to
    /// "deactivate" the current window so a rotation/seek doesn't leave it foreground.
    /// </summary>
    public static void ActivateTaskbar()
    {
        IntPtr tray = Win32.FindWindow("Shell_TrayWnd", null);
        if (tray != IntPtr.Zero) Activate(tray);
    }
}
