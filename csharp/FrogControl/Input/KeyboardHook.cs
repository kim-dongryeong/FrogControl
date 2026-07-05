using System.Runtime.InteropServices;
using FrogControl.Native;

namespace FrogControl.Input;

public sealed class KeyHookEventArgs
{
    public int Vk;
    public int ScanCode;
    public bool IsKeyDown;      // true for keydown/syskeydown
    public bool IsInjected;
    /// <summary>Set to true to swallow the key (return 1 from the hook, like AHK suppressing a hotkey).</summary>
    public bool Handled;
}

/// <summary>
/// Global WH_KEYBOARD_LL hook. Runs on the thread that constructs it (the UI thread,
/// which pumps messages). The callback must return quickly — long operations are
/// dispatched to a worker by the engine.
/// </summary>
public sealed class KeyboardHook : IDisposable
{
    private readonly Win32.HookProc _proc;   // kept alive to avoid GC of the callback
    private IntPtr _hook;
    private readonly Action<KeyHookEventArgs> _onEvent;

    public KeyboardHook(Action<KeyHookEventArgs> onEvent)
    {
        _onEvent = onEvent;
        _proc = HookCallback;
    }

    public void Install()
    {
        using var proc = System.Diagnostics.Process.GetCurrentProcess();
        using var mod = proc.MainModule!;
        _hook = Win32.SetWindowsHookEx(Win32.WH_KEYBOARD_LL, _proc, Win32.GetModuleHandle(mod.ModuleName), 0);
        if (_hook == IntPtr.Zero)
            throw new InvalidOperationException("Failed to install keyboard hook: " + Marshal.GetLastWin32Error());
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode < 0)
            return Win32.CallNextHookEx(_hook, nCode, wParam, lParam);

        var data = Marshal.PtrToStructure<Win32.KBDLLHOOKSTRUCT>(lParam);
        int msg = wParam.ToInt32();
        bool isDown = msg == Win32.WM_KEYDOWN || msg == Win32.WM_SYSKEYDOWN;
        bool injected = (data.flags & Win32.LLKHF_INJECTED) != 0 || data.dwExtraInfo == InputSimulator.FrogTag;

        // Maintain physical-state table for real events only.
        if (!injected)
        {
            if (isDown) KeyState.MarkDown((int)data.vkCode);
            else KeyState.MarkUp((int)data.vkCode);
        }

        var args = new KeyHookEventArgs
        {
            Vk = (int)data.vkCode,
            ScanCode = (int)data.scanCode,
            IsKeyDown = isDown,
            IsInjected = injected,
            Handled = false,
        };

        try { _onEvent(args); }
        catch { /* never let a handler exception tear down the hook */ }

        if (args.Handled)
            return new IntPtr(1);
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
