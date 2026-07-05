// FrogControl .NET port — integration smoke test.
//
// Drives the real feature code against spawned/created windows and asserts the observable
// effect (position, size, z-order, foreground, transparency, style, mode-channel release).
// The engine ignores injected input by design, so hotkeys can't be driven via SendInput;
// this exercises the feature entry points directly, plus faked KeyState for the loop features.
//
// Run:  dotnet run -c Release   (stop any running FrogControl.exe first so the referenced
//       project can rebuild). It spawns and moves windows — expect flicker.
// It makes itself Per-Monitor-V2 DPI aware (like the real app) so DWM/window/monitor
// coordinates are all physical pixels and agree.
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using FrogControl;
using FrogControl.Config;
using FrogControl.Features;
using FrogControl.Input;
using FrogControl.Windows;

internal static class Test
{
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
    [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINTS p);
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [StructLayout(LayoutKind.Sequential)] struct POINTS { public int X, Y; }

    static int passed = 0, failed = 0;
    static readonly List<string> fails = new();

    static void Check(string name, bool ok, string detail = "")
    {
        if (ok) { passed++; Console.WriteLine($"  PASS  {name}"); }
        else { failed++; fails.Add(name + (detail != "" ? " :: " + detail : "")); Console.WriteLine($"  FAIL  {name}  {detail}"); }
    }

    static void Section(string s) => Console.WriteLine($"\n== {s} ==");

    static void Pump(int ms) { int end = Environment.TickCount + ms; while (Environment.TickCount < end) { Application.DoEvents(); Thread.Sleep(8); } }
    static bool Near(double a, double b, double tol = 8) => Math.Abs(a - b) <= tol;

    static readonly List<Form> allForms = new();
    static Form NewForm(string title, int x, int y, int w, int h)
    {
        var f = new Form { Text = title, StartPosition = FormStartPosition.Manual, Bounds = new Rectangle(x, y, w, h), ShowInTaskbar = true, FormBorderStyle = FormBorderStyle.Sizable };
        f.Show();
        allForms.Add(f);
        Pump(120);
        return f;
    }

    [STAThread]
    static int Main()
    {
        SetThreadDpiAwarenessContext(new IntPtr(-4)); // PER_MONITOR_AWARE_V2, matching the real app
        Application.EnableVisualStyles();
        App.Settings = new Settings();
        SystemParametersInfo(0x2001, 0, IntPtr.Zero, 0);

        var mon = MonitorInfo.Collect();
        var prm = mon.Primary;
        Console.WriteLine($"Monitors={mon.Count} primary work=({prm.WorkLeft},{prm.WorkTop},{prm.WorkRight},{prm.WorkBottom})");

        try { TestWindowManager(); } catch (Exception e) { Check("WindowManager suite", false, e.Message); }
        try { TestMonitorDwm(mon); } catch (Exception e) { Check("Monitor/DWM suite", false, e.Message); }
        try { TestWindowOps(); } catch (Exception e) { Check("WindowOps suite", false, e.Message); }
        try { TestResizeToEdge(mon); } catch (Exception e) { Check("ResizeToEdge suite", false, e.Message); }
        try { TestVolume(); } catch (Exception e) { Check("Volume suite", false, e.Message); }
        try { TestArrange(mon); } catch (Exception e) { Check("Arrange suite", false, e.Message); }
        try { TestSameTypeRotation(); } catch (Exception e) { Check("SameType rotation", false, e.Message); }
        try { TestInteractiveLoops(mon); } catch (Exception e) { Check("Interactive loops suite", false, e.Message); }
        try { TestModes(); } catch (Exception e) { Check("Modes suite", false, e.Message); }

        // cleanup
        foreach (var f in allForms) { try { f.Close(); } catch { } }
        Pump(100);
        KillSpawned();

        Console.WriteLine($"\n=== SUMMARY: {passed} passed, {failed} failed ===");
        foreach (var f in fails) Console.WriteLine("  FAILED: " + f);
        return failed == 0 ? 0 : 1;
    }

    static void TestWindowManager()
    {
        Section("WindowManager primitives");
        var f = NewForm("WM-test", 200, 150, 500, 400);
        IntPtr h = f.Handle;

        WindowManager.Move(h, 320, 210, 480, 360);
        Pump(120);
        WindowManager.GetPos(h, out int x, out int y, out int w, out int hh);
        Check("Move", Near(x, 320) && Near(y, 210) && Near(w, 480) && Near(hh, 360), $"got ({x},{y},{w},{hh})");

        WindowManager.Maximize(h); Pump(120);
        Check("Maximize", WindowManager.MinMax(h) == 1, "MinMax=" + WindowManager.MinMax(h));
        WindowManager.Restore(h); Pump(120);
        Check("Restore", WindowManager.MinMax(h) == 0, "MinMax=" + WindowManager.MinMax(h));

        WindowManager.Minimize(h); Pump(120);
        Check("Minimize", WindowManager.MinMax(h) == -1, "MinMax=" + WindowManager.MinMax(h));
        WindowManager.Restore(h); Pump(120);

        WindowManager.SetAlwaysOnTop(h, true); Pump(60);
        Check("AlwaysOnTop On", WindowManager.IsTopmost(h));
        WindowManager.SetAlwaysOnTop(h, false); Pump(60);
        Check("AlwaysOnTop Off", !WindowManager.IsTopmost(h));

        WindowManager.SetTransparency(h, 128); Pump(60);
        Check("Transparency set 128", WindowManager.GetTransparency(h) == 128, "got " + WindowManager.GetTransparency(h));
        WindowManager.SetTransparency(h, 255); Pump(60);

        long before = WindowManager.GetStyle(h);
        WindowManager.ToggleStyle(h, 0xC00000); Pump(60);
        long after = WindowManager.GetStyle(h);
        Check("ToggleStyle changes WS_CAPTION", (before & 0xC00000) != (after & 0xC00000), $"before=0x{before:X} after=0x{after:X}");
        WindowManager.ToggleStyle(h, 0xC00000); Pump(60);

        var f2 = NewForm("WM-close", 100, 100, 200, 200);
        IntPtr h2 = f2.Handle;
        WindowManager.Close(h2); Pump(200);
        Check("Close", !WindowManager.Exists(h2));
    }

    static void TestMonitorDwm(MonitorSet mon)
    {
        Section("MonitorInfo / DwmHelper / EdgeScan");
        Check("Monitor count >= 1", mon.Count >= 1);
        var p = mon.Primary;
        Check("Primary work area sane", p.WorkRight > p.WorkLeft && p.WorkBottom > p.WorkTop, $"({p.WorkLeft},{p.WorkTop},{p.WorkRight},{p.WorkBottom})");

        var f = NewForm("DWM-test", 250, 200, 400, 300);
        IntPtr h = f.Handle;
        bool gb = DwmHelper.GetBorders(h, out int bL, out int bT, out int bR, out int bB);
        Check("GetBorders returns", gb, $"borders L{bL} T{bT} R{bR} B{bB}");

        DwmHelper.WinMove(h, 300, 250, 420, 320); Pump(150);
        int vx = 0, vy = 0, vw = 0, vh = 0;
        WindowManager.GetPos(h, out vx, out vy, out vw, out vh);
        DwmHelper.GetVisibleRect(h, ref vx, ref vy, ref vw, ref vh);
        Check("DWM_WinMove lands visible frame", Near(vx, 300) && Near(vy, 250) && Near(vw, 420) && Near(vh, 320), $"visible=({vx},{vy},{vw},{vh})");

        var es = mon.EdgeScan("right_edge", p.WorkLeft + 50, p.WorkTop + 50, 200, 200);
        Check("EdgeScan right_edge = work right", es != null && Near(es.Value, p.WorkRight, 2), "got " + es);
        var esl = mon.EdgeScan("left_edge", p.WorkLeft + 300, p.WorkTop + 50, 200, 200);
        Check("EdgeScan left_edge = work left", esl != null && Near(esl.Value, p.WorkLeft, 2), "got " + esl);
    }

    static void TestWindowOps()
    {
        Section("WindowOps one-shots (on active window)");
        var f = NewForm("Ops-test", 260, 220, 500, 380);
        IntPtr h = f.Handle;
        WindowManager.Activate(h); Pump(200);
        bool isActive = WindowManager.Active == h;
        Console.WriteLine($"    (active==form: {isActive})");

        WindowManager.SetTransparency(h, 255); Pump(40);
        WindowOps.AdjustTransparencyActive(-20); Pump(60);
        if (isActive)
            Check("AdjustTransparencyActive -20 => 235", WindowManager.GetTransparency(h) == 235, "got " + WindowManager.GetTransparency(h));
        else Console.WriteLine("  SKIP  AdjustTransparency (form not active)");
        WindowManager.SetTransparency(h, 255);

        // Move active to cursor
        SetCursorPos(700, 500); Pump(30);
        WindowManager.Activate(h); Pump(120);
        if (WindowManager.Active == h)
        {
            WindowOps.MoveActiveToCursor(); Pump(120);
            WindowManager.GetPos(h, out int x, out int y, out int w, out int hh);
            Check("MoveActiveToCursor centers on (700,500)", Near(x + w / 2.0, 700, 10) && Near(y + hh / 2.0, 500, 10), $"center=({x + w / 2},{y + hh / 2})");
        }
        else Console.WriteLine("  SKIP  MoveActiveToCursor (form not active)");

        // Cursor to active center
        WindowManager.Move(h, 300, 200, 400, 300); Pump(80);
        WindowManager.Activate(h); Pump(120);
        if (WindowManager.Active == h)
        {
            WindowOps.MoveCursorToActiveCenter(); Pump(80);
            GetCursorPos(out var cp);
            Check("MoveCursorToActiveCenter", Near(cp.X, 500, 12) && Near(cp.Y, 350, 12), $"cursor=({cp.X},{cp.Y})");
        }
        else Console.WriteLine("  SKIP  MoveCursorToActiveCenter (form not active)");
    }

    static void TestResizeToEdge(MonitorSet mon)
    {
        Section("WindowResizer.ResizeToEdge");
        var p = mon.Primary;
        var f = NewForm("Edge-test", p.WorkLeft + 200, p.WorkTop + 150, 400, 300);
        IntPtr h = f.Handle;
        WindowManager.Activate(h); Pump(150);
        if (WindowManager.Active != h) { Console.WriteLine("  SKIP  ResizeToEdge (form not active)"); return; }

        WindowResizer.ResizeToEdge('R'); Pump(150);
        int vx = 0, vy = 0, vw = 0, vh = 0; WindowManager.GetPos(h, out vx, out vy, out vw, out vh);
        DwmHelper.GetVisibleRect(h, ref vx, ref vy, ref vw, ref vh);
        Check("ResizeToEdge R: visible right at work right", Near(vx + vw, p.WorkRight, 3), $"visibleRight={vx + vw} workRight={p.WorkRight}");

        WindowManager.Move(h, p.WorkLeft + 300, p.WorkTop + 150, 400, 300); Pump(120);
        WindowManager.Activate(h); Pump(120);
        WindowResizer.ResizeToEdge('L'); Pump(150);
        vx = 0; WindowManager.GetPos(h, out vx, out vy, out vw, out vh);
        DwmHelper.GetVisibleRect(h, ref vx, ref vy, ref vw, ref vh);
        Check("ResizeToEdge L: visible left at work left", Near(vx, p.WorkLeft, 3), $"visibleLeft={vx} workLeft={p.WorkLeft}");
    }

    static void TestVolume()
    {
        Section("VolumeControl");
        try
        {
            VolumeControl.Adjust(+3); Pump(60);
            VolumeControl.Adjust(-3); Pump(60);
            Check("Volume Adjust +3/-3 no throw", true);
        }
        catch (Exception e) { Check("Volume Adjust", false, e.Message); }
    }

    static void TestArrange(MonitorSet mon)
    {
        Section("ArrangeEngine (grid + spread) via active-window type");
        // Close leftover forms from earlier sections so they don't pollute the same-type set.
        foreach (var f in allForms) { try { f.Close(); } catch { } }
        allForms.Clear();
        Pump(200);

        // The taskbar (Shell_TrayWnd) becomes active so arrange doesn't hit the
        // "active window is same-type -> send to bottom" toggle (taskbar isn't a form class).

        foreach (int n in new[] { 2, 3, 4, 5 })
        {
            foreach (int mode in new[] { 1, 0 }) // grid, spread — fresh forms each time
            {
                var forms = new List<Form>();
                for (int i = 0; i < n; i++)
                    forms.Add(NewForm($"Arr{n}-{mode}-{i}", 100 + i * 45, 90 + i * 35, 360 + i * 20, 280 + i * 15));
                Pump(200);
                IntPtr anchor = forms[0].Handle;
                int stc = WindowEnumerator.SameType(anchor, "").Count;

                WindowManager.ActivateTaskbar();
                Pump(250);
                IntPtr act = WindowManager.Active;
                bool actIsForm = forms.Any(f => f.Handle == act);
                Console.WriteLine($"    [n={n} mode={mode}] active={act} activeIsForm={actIsForm}");

                var before = forms.Select(f => { WindowManager.GetPos(f.Handle, out int x, out int y, out int w, out int h); return (x, y, w, h); }).ToList();
                ArrangeEngine.ShowWindows("", anchor, mode);
                Pump(500);

                int moved = 0, inBounds = 0;
                for (int i = 0; i < n; i++)
                {
                    WindowManager.GetPos(forms[i].Handle, out int x, out int y, out int w, out int hh);
                    if (x != before[i].x || y != before[i].y || w != before[i].w || hh != before[i].h) moved++;
                    double cx = x + w / 2.0, cy = y + hh / 2.0;
                    var p = mon.Primary;
                    if (cx >= p.WorkLeft - 5 && cx <= p.WorkRight + 5 && cy >= p.WorkTop - 5 && cy <= p.WorkBottom + 5) inBounds++;
                }
                string label = mode == 1 ? "grid" : "spread";
                Check($"Arrange {n}w {label}: same-type count == n", stc == n, $"got {stc}");
                Check($"Arrange {n}w {label}: all moved", moved == n, $"{moved}/{n} moved");
                Check($"Arrange {n}w {label}: centers in work area", inBounds == n, $"{inBounds}/{n} in bounds");

                foreach (var f in forms) { try { f.Close(); } catch { } allForms.Remove(f); }
                Pump(200);
            }
        }
    }

    static void TestSameTypeRotation()
    {
        Section("Same-type (class) window ops");
        var f1 = NewForm("Rot-1", 200, 200, 300, 250);
        var f2 = NewForm("Rot-2", 260, 260, 300, 250);
        Pump(150);
        var same = WindowEnumerator.ByClass(WindowManager.GetClass(f1.Handle));
        Check("ByClass finds both forms", same.Count >= 2, "count=" + same.Count);
    }

    static bool WaitFor(Func<bool> cond, int ms) { int end = Environment.TickCount + ms; while (Environment.TickCount < end) { if (cond()) return true; Application.DoEvents(); Thread.Sleep(15); } return cond(); }

    static Thread RunSta(Action a) { var t = new Thread(() => { SetThreadDpiAwarenessContext(new IntPtr(-4)); try { a(); } catch { } }); t.SetApartmentState(ApartmentState.STA); t.IsBackground = true; t.Start(); return t; }

    static void TestInteractiveLoops(MonitorSet mon)
    {
        Section("Interactive loops (faked key state)");
        var p = mon.Primary;

        // --- WindowMover grid (CapsLock+Ctrl+Down), gridNo=2 via one recorded Ctrl tap ---
        var f = NewForm("Mover-grid", p.WorkLeft + 300, p.WorkTop + 200, 500, 380);
        IntPtr h = f.Handle;
        WindowManager.Activate(h); Pump(150);
        KeyState.ResetTaps();
        KeyState.RecordTap("Control");                 // -> gridNo = 1 + 1 = 2
        KeyState.MarkDown(0x14); KeyState.MarkDown(0x11); KeyState.MarkDown(0x28); // Caps, Ctrl, Down
        var mover = RunSta(WindowMover.Start);
        Thread.Sleep(350);                              // let it do one grid step
        KeyState.MarkUp(0x28); KeyState.MarkUp(0x11); KeyState.MarkUp(0x14);
        mover.Join(1500);
        int vx = 0, vy = 0, vw = 0, vh = 0; WindowManager.GetPos(h, out vx, out vy, out vw, out vh);
        DwmHelper.GetVisibleRect(h, ref vx, ref vy, ref vw, ref vh);
        Check("WindowMover grid: cell ~ workarea/2", Near(vw, p.WorkWidth / 2, 12) && Near(vh, p.WorkHeight / 2, 12), $"cell=({vw}x{vh}) expected ~({p.WorkWidth / 2}x{p.WorkHeight / 2})");
        f.Close(); allForms.Remove(f); Pump(100);

        // --- WindowResizer grow (Win+Alt+Right): width should increase ---
        var f2 = NewForm("Resizer", p.WorkLeft + 200, p.WorkTop + 200, 500, 400);
        IntPtr h2 = f2.Handle;
        WindowManager.Activate(h2); Pump(150);
        WindowManager.GetPos(h2, out _, out _, out int w0, out _);
        KeyState.MarkDown(0x12); KeyState.MarkDown(0x27); // Alt, Right
        var rez = RunSta(WindowResizer.ResizeLoop);
        Thread.Sleep(120);
        KeyState.MarkUp(0x27); KeyState.MarkUp(0x12);
        rez.Join(1500);
        WindowManager.GetPos(h2, out _, out _, out int w1, out _);
        Check("WindowResizer grow: width increased", w1 > w0 + 10, $"w0={w0} w1={w1}");
        f2.Close(); allForms.Remove(f2); Pump(100);
    }

    static void TestModes()
    {
        Section("Modal modes start + release the keyboard channel (safety)");

        // DateTime input mode: begins, and Escape cancels + releases the channel (no typing).
        var t1 = RunSta(DateTimeInputMode.Start);
        bool began1 = WaitFor(() => ModeHost.ActiveChannel != null, 1500);
        Check("DateTimeInputMode begins (channel active)", began1);
        ModeHost.ActiveChannel?.Push(new KeyPress(0x1B, '\0', false)); // Escape
        bool ended1 = WaitFor(() => ModeHost.ActiveChannel == null, 1500);
        Check("DateTimeInputMode exits on Escape (keyboard released)", ended1);
        t1.Join(1500);

        Pump(150);

        // Mouse control mode: begins, Escape exits + releases the channel.
        var t2 = RunSta(MouseControlMode.Start);
        bool began2 = WaitFor(() => ModeHost.ActiveChannel != null, 1500);
        Check("MouseControlMode begins (channel active)", began2);
        Thread.Sleep(150); // let it reach the read loop
        ModeHost.ActiveChannel?.Push(new KeyPress(0x1B, '\0', false)); // Escape
        bool chanNull = WaitFor(() => ModeHost.ActiveChannel == null, 3000);
        bool flagClear = WaitFor(() => !App.FlagMouseControl, 500);
        Console.WriteLine($"    (channelNull={chanNull} flagClear={flagClear} threadAlive={t2.IsAlive})");
        Check("MouseControlMode exits on Escape (keyboard released, flag cleared)", chanNull && flagClear);
        t2.Join(2000);
    }

    static void KillSpawned()
    {
        foreach (var n in new[] { "charmap", "mspaint" })
            foreach (var p in Process.GetProcessesByName(n))
                try { if (p.StartTime > DateTime.Now.AddMinutes(-5)) p.Kill(); } catch { }
    }
}
