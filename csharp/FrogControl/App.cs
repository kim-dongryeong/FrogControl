using System.Collections.Concurrent;
using FrogControl.Config;

namespace FrogControl;

/// <summary>
/// Process-wide service locator + shared mutable state. Mirrors the AHK global block
/// (flags, settings) and gives features a single place to reach settings and the worker.
/// </summary>
public static class App
{
    public static Settings Settings { get; set; } = new();

    // ---- Flags ported from the AHK global block ----
    public static volatile bool FlagMouseControl;        // FLAG_MOUSECONTROL
    public static volatile bool FlagConstrainedMouse;    // FLAG_CONSTRAINEDMOUSE
    public static volatile bool FlagCoorConstrainedMouse;// FLAG_COOR_CONSTRAINED_MOUSE
    public static volatile bool FlagHalfTrans;           // FLAG_HALFTRANS
    public static int HelpLang = 1;                       // FLAG_HELP_LANG (1=en, 2=ko)

    public static volatile bool Suspended;               // tray "Disable" state

    /// <summary>Background worker: feature loops and any action that would block the hook thread.</summary>
    private static readonly BlockingCollection<Action> WorkItems = new(new ConcurrentQueue<Action>());
    private static Thread? _worker;

    // Re-entrancy guards (AHK "started_*" statics).
    private static readonly ConcurrentDictionary<string, byte> Running = new();

    public static void StartWorker()
    {
        _worker = new Thread(WorkerLoop) { IsBackground = true, Name = "FrogControl.Worker" };
        _worker.SetApartmentState(ApartmentState.STA);
        _worker.Start();
    }

    private static void WorkerLoop()
    {
        foreach (var item in WorkItems.GetConsumingEnumerable())
        {
            try { item(); }
            catch { /* keep the worker alive */ }
        }
    }

    /// <summary>Queue work on the single worker thread (serialised, like AHK threads within a mode).</summary>
    public static void Run(Action action) => WorkItems.Add(action);

    /// <summary>
    /// Run <paramref name="action"/> on a fresh dedicated thread. Use for long interactive
    /// loops (drag, rotate, seek) that must not block other quick actions on the worker.
    /// </summary>
    public static void RunDetached(string name, Action action)
    {
        var t = new Thread(() => { try { action(); } catch { } })
        {
            IsBackground = true,
            Name = "FrogControl." + name,
        };
        t.SetApartmentState(ApartmentState.STA);
        t.Start();
    }

    /// <summary>Try to enter a single-instance section (AHK started_* guard). Returns false if already running.</summary>
    public static bool TryEnter(string key) => Running.TryAdd(key, 1);
    public static void Exit(string key) => Running.TryRemove(key, out _);
    public static bool IsRunning(string key) => Running.ContainsKey(key);
}
