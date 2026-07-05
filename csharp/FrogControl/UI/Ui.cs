using System.Windows.Forms;

namespace FrogControl.UI;

/// <summary>
/// Marshals work onto the WinForms UI thread. Feature loops run on worker threads;
/// anything touching a Form/NotifyIcon must go through here.
/// </summary>
public static class Ui
{
    private static Control? _marshal;
    private static SynchronizationContext? _ctx;

    public static void Init(Control marshal)
    {
        _marshal = marshal;
        _ctx = SynchronizationContext.Current;
    }

    /// <summary>Fire-and-forget onto the UI thread.</summary>
    public static void Post(Action action)
    {
        var m = _marshal;
        if (m != null && m.IsHandleCreated && !m.IsDisposed)
        {
            try { m.BeginInvoke(action); return; }
            catch { }
        }
        _ctx?.Post(_ => Safe(action), null);
    }

    /// <summary>Run on the UI thread and wait for the result.</summary>
    public static void Send(Action action)
    {
        var m = _marshal;
        if (m != null && m.IsHandleCreated && !m.IsDisposed && m.InvokeRequired)
        {
            try { m.Invoke(action); return; }
            catch { return; }
        }
        Safe(action);
    }

    public static T Send<T>(Func<T> func)
    {
        T result = default!;
        Send(() => { result = func(); });
        return result;
    }

    private static void Safe(Action a) { try { a(); } catch { } }
}
