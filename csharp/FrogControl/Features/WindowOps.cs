using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>One-shot window operations (transparency, always-on-top, style, minimize, close, etc.).</summary>
public static class WindowOps
{
    // ---- Always on top ----
    public static void ToggleAlwaysOnTopActive()
    {
        IntPtr h = WindowManager.Active;
        WindowManager.SetAlwaysOnTop(h, true);   // AHK: WinSet AlwaysOnTop (no arg) = ON for #a
        ReportAlwaysOnTop(h);
    }

    public static void ToggleAlwaysOnTopUnderMouse()
    {
        IntPtr h = WindowUnderCursor();
        WindowManager.ToggleAlwaysOnTop(h);
        ReportAlwaysOnTop(h);
    }

    private static void ReportAlwaysOnTop(IntPtr h)
    {
        string state = WindowManager.IsTopmost(h) ? "On" : "Off";
        TrayTipService.Show($"Always On Top - {state}", WindowManager.GetTitle(h));
    }

    // ---- Transparency ----
    public static void AdjustTransparencyActive(int delta)
    {
        IntPtr h = WindowManager.Active;
        int cur = WindowManager.GetTransparency(h) ?? 255;   // AHK: unset -> treat as 255
        cur = Math.Clamp(cur + delta, 0, 255);
        WindowManager.SetTransparency(h, cur);
    }

    public static void TransColorUnderMouse()
    {
        InputSimulator.GetCursor(out int mx, out int my);
        uint color = SystemParams.PixelGetColor(mx, my);
        WindowManager.SetTransColor(WindowUnderCursor(), color);
    }

    // ---- Style toggles ----
    public static void ToggleCaption() => WindowManager.ToggleStyle(WindowManager.Active, 0xC00000); // WS_CAPTION
    public static void ToggleBorder() => WindowManager.ToggleStyle(WindowManager.Active, 0x800000);  // WS_BORDER

    // ---- Minimize / bottom / close ----
    public static void MinimizeUnderMouse() => WindowManager.Minimize(WindowUnderCursor());

    public static void SendToBottomUnderMouse()
    {
        IntPtr h = WindowUnderCursor();
        if (WindowManager.IsTopmost(h)) return;   // AHK bails on topmost windows
        WindowManager.SetBottom(h);
        WindowManager.ActivateTaskbar();
    }

    public static void CloseWindowUnderMouseForce() => WindowManager.Close(WindowUnderCursor());

    /// <summary>Ctrl+Shift+RightClick: close the current TAB of the window under the mouse (Ctrl+W).</summary>
    public static void CloseTabUnderMouse()
    {
        uint beep = SystemParams.GetBeep();
        SystemParams.SetBeep(0);
        try
        {
            IntPtr mouseWin = WindowUnderCursor();
            WindowManager.Activate(mouseWin);
            if (WaitActive(mouseWin, 0.5))
                InputSimulator.KeyCombo(0x57 /*W*/, Win32.VK_CONTROL);
        }
        finally { SystemParams.SetBeep(beep); }
    }

    /// <summary>Ctrl+Shift+Alt+RightClick: close the window under the mouse (Alt+F4).</summary>
    public static void CloseWindowUnderMouse()
    {
        IntPtr mouseWin = WindowUnderCursor();
        if (mouseWin == IntPtr.Zero) return;
        WindowManager.Activate(mouseWin);
        if (WaitActive(mouseWin, 0.5))
            InputSimulator.KeyCombo(0x73 /*F4*/, Win32.VK_MENU);
    }

    // ---- Move helpers ----
    public static void MoveActiveToCursor()
    {
        IntPtr h = WindowManager.Active;
        InputSimulator.GetCursor(out int x, out int y);
        WindowManager.GetPos(h, out _, out _, out int w, out int hgt);
        WindowManager.Move(h, x - w / 2.0, y - hgt / 2.0);
    }

    public static void MoveCursorToActiveCenter()
    {
        IntPtr h = WindowManager.Active;
        WindowManager.GetPos(h, out int x, out int y, out int w, out int hgt);
        InputSimulator.MoveCursor(x + w / 2, y + hgt / 2);
    }

    public static void SendEnter() => InputSimulator.KeyPress(Win32.VK_RETURN);

    // ---- Same-type (class) window rotation ----
    public static void NextSameType(bool sendBottom)
    {
        IntPtr active = WindowManager.Active;
        string cls = WindowManager.GetClass(active);
        var wins = WindowEnumerator.ByClass(cls);
        if (wins.Count > 1 && sendBottom)
            WindowManager.SetBottom(active);
        // activate the topmost window of that class
        if (wins.Count > 0)
        {
            var top = WindowEnumerator.ByClass(cls);   // re-query after the SetBottom
            if (top.Count > 0) WindowManager.Activate(top[0]);
        }
    }

    public static void PrevSameType()
    {
        IntPtr active = WindowManager.Active;
        string cls = WindowManager.GetClass(active);
        var wins = WindowEnumerator.ByClass(cls);
        if (wins.Count > 1)
            WindowManager.Activate(wins[^1]);   // WinActivateBottom: bottom-most of the class
    }

    // ---- Misc sends ----
    public static void CtrlPageDown() => InputSimulator.KeyCombo(0x22 /*PgDn*/, Win32.VK_CONTROL);
    public static void CtrlPageUp() => InputSimulator.KeyCombo(0x21 /*PgUp*/, Win32.VK_CONTROL);

    /// <summary>#^!+1 / ^!+2 : switch to the next virtual desktop (RWin+Ctrl+Right).</summary>
    public static void VirtualDesktopRight()
    {
        InputSimulator.KeyDown((ushort)Win32.VK_RWIN);
        InputSimulator.KeyDown((ushort)Win32.VK_CONTROL);
        InputSimulator.KeyPress((ushort)Win32.VK_RIGHT);
        InputSimulator.KeyUp((ushort)Win32.VK_CONTROL);
        InputSimulator.KeyUp((ushort)Win32.VK_RWIN);
    }

    public static void ShowAltTabList()
    {
        var list = WindowEnumerator.List(out var active);
        DebugListView.Show(list, active, "List of programs on the Alt Tab list");
    }

    // ---- Utilities ----
    private static IntPtr WindowUnderCursor()
    {
        Win32.GetCursorPos(out var p);
        IntPtr h = Win32.WindowFromPoint(p);
        if (h != IntPtr.Zero)
        {
            IntPtr root = Win32.GetAncestor(h, Win32.GA_ROOT);
            if (root != IntPtr.Zero) h = root;
        }
        return h;
    }

    private static bool WaitActive(IntPtr hwnd, double timeoutSec)
    {
        int ms = (int)(timeoutSec * 1000);
        int waited = 0;
        while (WindowManager.Active != hwnd)
        {
            Thread.Sleep(10);
            waited += 10;
            if (waited >= ms) return WindowManager.Active == hwnd;
        }
        return true;
    }
}
