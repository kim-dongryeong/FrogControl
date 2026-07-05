using System.Diagnostics;
using System.Windows.Forms;
using FrogControl.Config;
using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;

namespace FrogControl;

internal static class Program
{
    private static Mutex? _mutex;
    private const string MutexName = "FrogControl.SingleInstance.Mutex.v2";

    [STAThread]
    private static void Main()
    {
        // Per-monitor-v2 DPI so mouse/window coordinates are physical pixels everywhere
        // (mirrors the AHK SetThreadDpiAwarenessContext(-4) calls).
        Win32.SetThreadDpiAwarenessContext(Win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        if (!AcquireSingleInstance())
        {
            // Another instance is already running (and didn't exit within the grace window).
            return;
        }

        App.Settings = Settings.Load();
        App.StartWorker();

        using var ctx = new FrogControlContext();
        Application.Run(ctx);

        GC.KeepAlive(_mutex);
    }

    /// <summary>
    /// Acquire the single-instance mutex, retrying briefly so a Reload (which starts a new
    /// process before the old one has fully exited) succeeds instead of aborting.
    /// </summary>
    private static bool AcquireSingleInstance()
    {
        _mutex = new Mutex(false, MutexName);
        var deadline = Environment.TickCount + 3000;
        do
        {
            try { if (_mutex.WaitOne(0)) return true; }
            catch (AbandonedMutexException) { return true; }
            Thread.Sleep(100);
        } while (Environment.TickCount < deadline);
        return false;
    }

    internal static void ReleaseMutex()
    {
        try { _mutex?.ReleaseMutex(); } catch { }
        _mutex?.Dispose();
        _mutex = null;
    }
}

/// <summary>The application context: hidden marshaling window, tray icon, and hook engine.</summary>
internal sealed class FrogControlContext : ApplicationContext
{
    private readonly Form _marshalForm;
    private readonly HotkeyEngine _engine;

    public FrogControlContext()
    {
        // Hidden form used only to marshal work to the UI thread and pump hook messages.
        _marshalForm = new Form
        {
            ShowInTaskbar = false,
            WindowState = FormWindowState.Minimized,
            FormBorderStyle = FormBorderStyle.FixedToolWindow,
            Opacity = 0,
        };
        _marshalForm.Load += (_, _) => _marshalForm.Hide();
        _marshalForm.CreateControl();
        var handle = _marshalForm.Handle; // force handle creation
        _ = handle;
        Ui.Init(_marshalForm);

        TrayIconHost.Init(ToggleSuspend, Reload, ExitApp);

        _engine = new HotkeyEngine();
        try
        {
            _engine.Start();
        }
        catch (Exception ex)
        {
            MessageBox.Show("FrogControl could not install its keyboard/mouse hooks:\n\n" + ex.Message,
                "FrogControl", MessageBoxButtons.OK, MessageBoxIcon.Error);
            ExitApp();
            return;
        }

        TrayTipService.Show("FrogControl", $"Running ({AppInfo.Edition}). Right-click the tray icon for help.");
    }

    private void ToggleSuspend() => _engine.ToggleSuspend();

    private void Reload()
    {
        try
        {
            string? exe = Process.GetCurrentProcess().MainModule?.FileName;
            if (!string.IsNullOrEmpty(exe))
                Process.Start(new ProcessStartInfo(exe) { UseShellExecute = true });
        }
        catch { }
        ExitApp();
    }

    private void ExitApp()
    {
        _engine.Dispose();
        TrayIconHost.Dispose();
        Program.ReleaseMutex();
        try { _marshalForm.Close(); } catch { }
        ExitThread();
        Environment.Exit(0);
    }
}
