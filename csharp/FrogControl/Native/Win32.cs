using System.Runtime.InteropServices;
using System.Text;

namespace FrogControl.Native;

/// <summary>
/// Central P/Invoke surface for FrogControl. Everything the AHK build did through
/// DllCall / WinGet / WinMove / SysGet is expressed here as thin managed wrappers.
/// </summary>
internal static class Win32
{
    // ---------------------------------------------------------------------
    // Structs
    // ---------------------------------------------------------------------
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
        public POINT(int x, int y) { X = x; Y = y; }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
        public int Width => Right - Left;
        public int Height => Bottom - Top;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MONITORINFO
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
    }

    // Low-level keyboard hook payload (WH_KEYBOARD_LL).
    [StructLayout(LayoutKind.Sequential)]
    public struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    // Low-level mouse hook payload (WH_MOUSE_LL).
    [StructLayout(LayoutKind.Sequential)]
    public struct MSLLHOOKSTRUCT
    {
        public POINT pt;
        public uint mouseData;   // high word = wheel delta / xbutton id
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT
    {
        public uint type;
        public InputUnion U;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion
    {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
        [FieldOffset(0)] public HARDWAREINPUT hi;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct HARDWAREINPUT
    {
        public uint uMsg;
        public ushort wParamL;
        public ushort wParamH;
    }

    // ---------------------------------------------------------------------
    // Constants
    // ---------------------------------------------------------------------
    public const int WH_KEYBOARD_LL = 13;
    public const int WH_MOUSE_LL = 14;

    public const int WM_KEYDOWN = 0x0100;
    public const int WM_KEYUP = 0x0101;
    public const int WM_SYSKEYDOWN = 0x0104;
    public const int WM_SYSKEYUP = 0x0105;

    public const int WM_MOUSEMOVE = 0x0200;
    public const int WM_LBUTTONDOWN = 0x0201;
    public const int WM_LBUTTONUP = 0x0202;
    public const int WM_RBUTTONDOWN = 0x0204;
    public const int WM_RBUTTONUP = 0x0205;
    public const int WM_MBUTTONDOWN = 0x0207;
    public const int WM_MBUTTONUP = 0x0208;
    public const int WM_MOUSEWHEEL = 0x020A;
    public const int WM_MOUSEHWHEEL = 0x020E;
    public const int WM_XBUTTONDOWN = 0x020B;
    public const int WM_XBUTTONUP = 0x020C;

    public const uint LLKHF_INJECTED = 0x00000010;
    public const uint LLMHF_INJECTED = 0x00000001;

    // GetWindowLong indexes
    public const int GWL_STYLE = -16;
    public const int GWL_EXSTYLE = -20;

    // Window styles
    public const long WS_DISABLED = 0x08000000L;
    public const long WS_POPUP = 0x80000000L;
    public const long WS_MAXIMIZE = 0x01000000L;
    public const long WS_MINIMIZE = 0x20000000L;

    // Extended window styles
    public const long WS_EX_TOPMOST = 0x00000008L;
    public const long WS_EX_TOOLWINDOW = 0x00000080L;
    public const long WS_EX_APPWINDOW = 0x00040000L;
    public const long WS_EX_CONTROLPARENT = 0x00010000L;
    public const long WS_EX_LAYERED = 0x00080000L;

    // SetWindowPos flags
    public const uint SWP_NOSIZE = 0x0001;
    public const uint SWP_NOMOVE = 0x0002;
    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_NOOWNERZORDER = 0x0200;
    public const uint SWP_ASYNCWINDOWPOS = 0x4000;

    public static readonly IntPtr HWND_TOP = IntPtr.Zero;
    public static readonly IntPtr HWND_BOTTOM = new IntPtr(1);
    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    // ShowWindow
    public const int SW_HIDE = 0;
    public const int SW_SHOWNORMAL = 1;
    public const int SW_SHOWMINIMIZED = 2;
    public const int SW_SHOWMAXIMIZED = 3;
    public const int SW_MAXIMIZE = 3;
    public const int SW_MINIMIZE = 6;
    public const int SW_RESTORE = 9;
    public const int SW_SHOW = 5;

    // Layered window attributes
    public const uint LWA_COLORKEY = 0x00000001;
    public const uint LWA_ALPHA = 0x00000002;

    // SendInput
    public const uint INPUT_MOUSE = 0;
    public const uint INPUT_KEYBOARD = 1;

    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint KEYEVENTF_SCANCODE = 0x0008;
    public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;

    public const uint MOUSEEVENTF_MOVE = 0x0001;
    public const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    public const uint MOUSEEVENTF_RIGHTUP = 0x0010;
    public const uint MOUSEEVENTF_MIDDLEDOWN = 0x0020;
    public const uint MOUSEEVENTF_MIDDLEUP = 0x0040;
    public const uint MOUSEEVENTF_WHEEL = 0x0800;
    public const uint MOUSEEVENTF_HWHEEL = 0x01000;
    public const int WHEEL_DELTA = 120;

    // SystemParametersInfo
    public const uint SPI_GETBEEP = 0x0001;
    public const uint SPI_SETBEEP = 0x0002;
    public const uint SPI_GETWHEELSCROLLLINES = 0x0068;
    public const uint SPI_SETWHEELSCROLLLINES = 0x0069;

    // DWM
    public const uint DWMWA_EXTENDED_FRAME_BOUNDS = 9;

    // Virtual key codes we reference a lot
    public const int VK_LBUTTON = 0x01;
    public const int VK_RBUTTON = 0x02;
    public const int VK_MBUTTON = 0x04;
    public const int VK_BACK = 0x08;
    public const int VK_TAB = 0x09;
    public const int VK_RETURN = 0x0D;
    public const int VK_SHIFT = 0x10;
    public const int VK_CONTROL = 0x11;
    public const int VK_MENU = 0x12;   // Alt
    public const int VK_CAPITAL = 0x14;
    public const int VK_ESCAPE = 0x1B;
    public const int VK_SPACE = 0x20;
    public const int VK_LEFT = 0x25;
    public const int VK_UP = 0x26;
    public const int VK_RIGHT = 0x27;
    public const int VK_DOWN = 0x28;
    public const int VK_LWIN = 0x5B;
    public const int VK_RWIN = 0x5C;
    public const int VK_LSHIFT = 0xA0;
    public const int VK_RSHIFT = 0xA1;
    public const int VK_LCONTROL = 0xA2;
    public const int VK_RCONTROL = 0xA3;
    public const int VK_LMENU = 0xA4;
    public const int VK_RMENU = 0xA5;
    public const int VK_OEM_4 = 0xDB;   // [ {
    public const int VK_OEM_6 = 0xDD;   // ] }
    public const int VK_OEM_PLUS = 0xBB; // = +
    public const int VK_OEM_3 = 0xC0;   // ` ~
    public const int VK_OEM_2 = 0xBF;   // / ?

    // ---------------------------------------------------------------------
    // Hooks
    // ---------------------------------------------------------------------
    public delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string? lpModuleName);

    // ---------------------------------------------------------------------
    // Window enumeration / info
    // ---------------------------------------------------------------------
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsZoomed(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextLengthW(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetClassNameW(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern IntPtr GetParent(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    // 64-bit safe long variants.
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW", SetLastError = true)]
    private static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "GetWindowLongW", SetLastError = true)]
    private static extern int GetWindowLong32(IntPtr hWnd, int nIndex);

    public static long GetWindowLongEx(IntPtr hWnd, int nIndex)
    {
        if (IntPtr.Size == 8)
            return GetWindowLongPtr64(hWnd, nIndex).ToInt64();
        return GetWindowLong32(hWnd, nIndex);
    }

    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW", SetLastError = true)]
    private static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    [DllImport("user32.dll", EntryPoint = "SetWindowLongW", SetLastError = true)]
    private static extern int SetWindowLong32(IntPtr hWnd, int nIndex, int dwNewLong);

    public static long SetWindowLongEx(IntPtr hWnd, int nIndex, long dwNewLong)
    {
        if (IntPtr.Size == 8)
            return SetWindowLongPtr64(hWnd, nIndex, new IntPtr(dwNewLong)).ToInt64();
        return SetWindowLong32(hWnd, nIndex, (int)dwNewLong);
    }

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetLayeredWindowAttributes(IntPtr hwnd, out uint pcrKey, out byte pbAlpha, out uint pdwFlags);

    // ---------------------------------------------------------------------
    // Cursor / mouse
    // ---------------------------------------------------------------------
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern IntPtr WindowFromPoint(POINT Point);

    [DllImport("user32.dll")]
    public static extern IntPtr GetAncestor(IntPtr hwnd, uint gaFlags);
    public const uint GA_ROOT = 2;

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern short GetKeyState(int nVirtKey);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    public static extern IntPtr LoadCursor(IntPtr hInstance, int lpCursorName);

    [DllImport("user32.dll")]
    public static extern IntPtr CopyImage(IntPtr hImage, uint uType, int cxDesired, int cyDesired, uint fuFlags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetSystemCursor(IntPtr hcur, uint id);

    public const uint IMAGE_CURSOR = 2;

    // ---------------------------------------------------------------------
    // Monitors
    // ---------------------------------------------------------------------
    public delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);

    [DllImport("user32.dll")]
    public static extern IntPtr MonitorFromPoint(POINT pt, uint dwFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint dwFlags);

    public const uint MONITOR_DEFAULTTONULL = 0;
    public const uint MONITOR_DEFAULTTOPRIMARY = 1;
    public const uint MONITOR_DEFAULTTONEAREST = 2;
    public const uint MONITORINFOF_PRIMARY = 0x00000001;

    // ---------------------------------------------------------------------
    // DWM
    // ---------------------------------------------------------------------
    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hwnd, uint dwAttribute, out RECT pvAttribute, int cbAttribute);

    // ---------------------------------------------------------------------
    // System parameters (beep, wheel scroll lines)
    // ---------------------------------------------------------------------
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref uint pvParam, uint fWinIni);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    // ---------------------------------------------------------------------
    // DPI awareness (mirrors DllCall("SetThreadDpiAwarenessContext", "ptr", -4))
    // ---------------------------------------------------------------------
    [DllImport("user32.dll")]
    public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);

    public static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new IntPtr(-4);

    // ---------------------------------------------------------------------
    // Foreground-window helpers (AttachThreadInput trick for reliable activation)
    // ---------------------------------------------------------------------
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    public static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string? lpClassName, string? lpWindowName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    public const uint WM_CLOSE = 0x0010;
}
