using System.Runtime.InteropServices;
using FrogControl.Native;

namespace FrogControl.Input;

public enum MouseEventKind
{
    Move, LeftDown, LeftUp, RightDown, RightUp, MiddleDown, MiddleUp,
    Wheel, HWheel, XDown, XUp
}

public sealed class MouseHookEventArgs
{
    public MouseEventKind Kind;
    public int X, Y;
    public int WheelDelta;     // +120 up / -120 down (or right/left for HWheel)
    public int XButton;        // 1 or 2 for XButton events
    public bool IsInjected;
    public bool Handled;
}

/// <summary>Global WH_MOUSE_LL hook (wheel, buttons, movement).</summary>
public sealed class MouseHook : IDisposable
{
    private readonly Win32.HookProc _proc;
    private IntPtr _hook;
    private readonly Action<MouseHookEventArgs> _onEvent;

    public MouseHook(Action<MouseHookEventArgs> onEvent)
    {
        _onEvent = onEvent;
        _proc = HookCallback;
    }

    public void Install()
    {
        using var proc = System.Diagnostics.Process.GetCurrentProcess();
        using var mod = proc.MainModule!;
        _hook = Win32.SetWindowsHookEx(Win32.WH_MOUSE_LL, _proc, Win32.GetModuleHandle(mod.ModuleName), 0);
        if (_hook == IntPtr.Zero)
            throw new InvalidOperationException("Failed to install mouse hook: " + Marshal.GetLastWin32Error());
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode < 0)
            return Win32.CallNextHookEx(_hook, nCode, wParam, lParam);

        var data = Marshal.PtrToStructure<Win32.MSLLHOOKSTRUCT>(lParam);
        int msg = wParam.ToInt32();
        bool injected = (data.flags & Win32.LLMHF_INJECTED) != 0 || data.dwExtraInfo == InputSimulator.FrogTag;

        MouseEventKind? kind = null;
        int wheel = 0, xbtn = 0;
        switch (msg)
        {
            case Win32.WM_MOUSEMOVE: kind = MouseEventKind.Move; break;
            case Win32.WM_LBUTTONDOWN: kind = MouseEventKind.LeftDown; break;
            case Win32.WM_LBUTTONUP: kind = MouseEventKind.LeftUp; break;
            case Win32.WM_RBUTTONDOWN: kind = MouseEventKind.RightDown; break;
            case Win32.WM_RBUTTONUP: kind = MouseEventKind.RightUp; break;
            case Win32.WM_MBUTTONDOWN: kind = MouseEventKind.MiddleDown; break;
            case Win32.WM_MBUTTONUP: kind = MouseEventKind.MiddleUp; break;
            case Win32.WM_MOUSEWHEEL: kind = MouseEventKind.Wheel; wheel = (short)((data.mouseData >> 16) & 0xFFFF); break;
            case Win32.WM_MOUSEHWHEEL: kind = MouseEventKind.HWheel; wheel = (short)((data.mouseData >> 16) & 0xFFFF); break;
            case Win32.WM_XBUTTONDOWN: kind = MouseEventKind.XDown; xbtn = (int)((data.mouseData >> 16) & 0xFFFF); break;
            case Win32.WM_XBUTTONUP: kind = MouseEventKind.XUp; xbtn = (int)((data.mouseData >> 16) & 0xFFFF); break;
        }

        // Track physical button state for real events.
        if (!injected && kind is { } k)
        {
            switch (k)
            {
                case MouseEventKind.LeftDown: KeyState.MarkDown(Win32.VK_LBUTTON); break;
                case MouseEventKind.LeftUp: KeyState.MarkUp(Win32.VK_LBUTTON); break;
                case MouseEventKind.RightDown: KeyState.MarkDown(Win32.VK_RBUTTON); break;
                case MouseEventKind.RightUp: KeyState.MarkUp(Win32.VK_RBUTTON); break;
                case MouseEventKind.MiddleDown: KeyState.MarkDown(Win32.VK_MBUTTON); break;
                case MouseEventKind.MiddleUp: KeyState.MarkUp(Win32.VK_MBUTTON); break;
            }
        }

        if (kind is { } kk)
        {
            var args = new MouseHookEventArgs
            {
                Kind = kk,
                X = data.pt.X,
                Y = data.pt.Y,
                WheelDelta = wheel,
                XButton = xbtn,
                IsInjected = injected,
                Handled = false,
            };
            try { _onEvent(args); }
            catch { }
            if (args.Handled)
                return new IntPtr(1);
        }

        return Win32.CallNextHookEx(_hook, nCode, wParam, lParam);
    }

    public void Dispose()
    {
        if (_hook != IntPtr.Zero)
        {
            Win32.UnhookWindowsHookEx(_hook);
            _hook = IntPtr.Zero;
        }
    }
}
