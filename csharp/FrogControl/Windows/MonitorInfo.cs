using FrogControl.Native;

namespace FrogControl.Windows;

/// <summary>
/// One monitor. Field names mirror the AHK monitor_&lt;i&gt;_* pseudo-array so the ported
/// layout maths reads the same. Indices are 1-based, matching AHK's SysGet.
/// </summary>
public sealed class Monitor
{
    public int Index;          // 1-based
    public bool IsPrimary;
    public IntPtr Handle;

    // Full monitor rect
    public int Left, Top, Right, Bottom;
    // Work area rect (screen minus taskbar / appbars)
    public int WorkLeft, WorkTop, WorkRight, WorkBottom;

    public double WorkWidth => WorkRight - WorkLeft;
    public double WorkHeight => WorkBottom - WorkTop;
    public double WorkRatio => WorkHeight / WorkWidth;     // matches monitor_*_workarea_ratio
    public double WorkCenterX => (WorkRight + WorkLeft) / 2.0;
    public double WorkCenterY => (WorkBottom + WorkTop) / 2.0;
}

/// <summary>Snapshot of all monitors. Equivalent to running CollectMonitorInfo().</summary>
public sealed class MonitorSet
{
    public List<Monitor> Monitors { get; } = new();
    public int Count => Monitors.Count;
    public int PrimaryIndex { get; set; } = 1;   // 1-based
    public Monitor Primary => Get(PrimaryIndex);

    public Monitor Get(int index1Based)
    {
        if (index1Based >= 1 && index1Based <= Monitors.Count)
            return Monitors[index1Based - 1];
        return Monitors.Count > 0 ? Monitors[0] : new Monitor { Index = 1 };
    }

    /// <summary>Half-open containment test, matching AHK's left &lt;= x &lt; right and top &lt;= y &lt; bottom.</summary>
    public Monitor? FromPoint(double x, double y)
    {
        foreach (var m in Monitors)
        {
            if (m.Left <= x && x < m.Right && m.Top <= y && y < m.Bottom)
                return m;
        }
        return null;
    }

    public Monitor FromPointOrPrimary(double x, double y) => FromPoint(x, y) ?? Primary;

    /// <summary>Monitor whose full bounds contain the rect's centre (falls back to primary).</summary>
    public Monitor FromRectCenter(double x, double y, double w, double h)
        => FromPointOrPrimary(x + w / 2.0, y + h / 2.0);

    /// <summary>
    /// Port of Monitor_EdgeScan(): nearest relevant work-area edge for moving/resizing the
    /// rect (X,Y,W,H) toward a direction, or null if no monitor qualifies.
    ///   *_edge = attach the window's own side to that screen edge
    ///   *_gap  = jump to the facing edge of the next monitor in that direction
    /// </summary>
    public double? EdgeScan(string mode, double X, double Y, double W, double H)
    {
        double? result = null;
        foreach (var m in Monitors)
        {
            bool vOv = m.WorkTop < Y + H && Y < m.WorkBottom;   // vertical overlap
            bool hOv = m.WorkLeft < X + W && X < m.WorkRight;   // horizontal overlap
            double? cand = mode switch
            {
                "right_edge" when vOv && X + W < m.WorkRight => m.WorkRight,
                "right_gap" when vOv && X < m.WorkLeft => m.WorkLeft,
                "left_edge" when vOv && m.WorkLeft < X => m.WorkLeft,
                "left_gap" when vOv && m.WorkRight < X + W => m.WorkRight,
                "up_edge" when hOv && m.WorkTop < Y => m.WorkTop,
                "up_gap" when hOv && m.WorkBottom < Y + H => m.WorkBottom,
                "down_edge" when hOv && Y + H < m.WorkBottom => m.WorkBottom,
                "down_gap" when hOv && Y < m.WorkTop => m.WorkTop,
                _ => (double?)null,
            };
            if (cand is null) continue;
            if (result is null)
                result = cand;
            else if (mode.Contains("right") || mode.Contains("down"))
                result = cand < result ? cand : result;   // toward increasing coords: nearest = min
            else
                result = cand > result ? cand : result;   // toward decreasing coords: nearest = max
        }
        return result;
    }
}

public static class MonitorInfo
{
    /// <summary>Enumerate every monitor into a MonitorSet (equivalent to CollectMonitorInfo()).</summary>
    public static MonitorSet Collect()
    {
        var set = new MonitorSet();
        int i = 0;
        Win32.MonitorEnumProc cb = (IntPtr hMon, IntPtr hdc, ref Win32.RECT rc, IntPtr data) =>
        {
            var mi = new Win32.MONITORINFO { cbSize = System.Runtime.InteropServices.Marshal.SizeOf<Win32.MONITORINFO>() };
            if (Win32.GetMonitorInfo(hMon, ref mi))
            {
                i++;
                bool primary = (mi.dwFlags & Win32.MONITORINFOF_PRIMARY) != 0;
                var m = new Monitor
                {
                    Index = i,
                    Handle = hMon,
                    IsPrimary = primary,
                    Left = mi.rcMonitor.Left,
                    Top = mi.rcMonitor.Top,
                    Right = mi.rcMonitor.Right,
                    Bottom = mi.rcMonitor.Bottom,
                    WorkLeft = mi.rcWork.Left,
                    WorkTop = mi.rcWork.Top,
                    WorkRight = mi.rcWork.Right,
                    WorkBottom = mi.rcWork.Bottom,
                };
                set.Monitors.Add(m);
                if (primary)
                    set.PrimaryIndex = i;
            }
            return true;
        };
        Win32.EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, cb, IntPtr.Zero);

        if (set.Monitors.Count == 0)
        {
            // Extreme fallback: one virtual monitor covering the primary screen.
            var b = System.Windows.Forms.Screen.PrimaryScreen!.Bounds;
            var w = System.Windows.Forms.Screen.PrimaryScreen!.WorkingArea;
            set.Monitors.Add(new Monitor
            {
                Index = 1,
                IsPrimary = true,
                Left = b.Left, Top = b.Top, Right = b.Right, Bottom = b.Bottom,
                WorkLeft = w.Left, WorkTop = w.Top, WorkRight = w.Right, WorkBottom = w.Bottom,
            });
            set.PrimaryIndex = 1;
        }
        return set;
    }
}
