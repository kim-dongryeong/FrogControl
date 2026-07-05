using System.Text;
using FrogControl.Native;

namespace FrogControl.Windows;

/// <summary>
/// Port of AltTab_window_list() / AltTab_List_SameType() from FC_AltTab.ahk:
/// builds the list of "real" alt-tabbable windows using the same exclusion rules.
/// </summary>
public static class WindowEnumerator
{
    /// <summary>
    /// Enumerate the alt-tab candidate windows. .Index is 1-based (matches AHK's
    /// AltTab_ID_List_&lt;n&gt;). The foreground window (if in the list) is returned in <paramref name="active"/>.
    /// </summary>
    public static List<WindowInfo> List(out WindowInfo? active)
    {
        var result = new List<WindowInfo>();
        IntPtr foreground = Win32.GetForegroundWindow();
        WindowInfo? act = null;

        Win32.EnumWindowsProc cb = (hwnd, _) =>
        {
            if (!Win32.IsWindowVisible(hwnd))
                return true;

            string title = WindowManager.GetTitle(hwnd);
            long style = WindowManager.GetStyle(hwnd);

            // skip disabled or title-less windows
            if ((style & Win32.WS_DISABLED) != 0 || string.IsNullOrEmpty(title))
                return true;

            long ex = WindowManager.GetExStyle(hwnd);
            if ((ex & Win32.WS_EX_TOOLWINDOW) != 0)
                return true;

            IntPtr parent = Win32.GetParent(hwnd);
            string cls = WindowManager.GetClass(hwnd);
            long parentStyle = parent != IntPtr.Zero ? WindowManager.GetStyle(parent) : 0;
            string proc = WindowManager.GetProcessName(hwnd);

            // controlparent child windows (unless they look like real app windows)
            if ((ex & Win32.WS_EX_CONTROLPARENT) != 0
                && (style & Win32.WS_POPUP) == 0
                && cls != "#32770"
                && (ex & Win32.WS_EX_APPWINDOW) == 0)
                return true;

            // popups owned by an enabled parent (dialogs like Notepad's Find) — except PS/AI canvases
            if ((style & Win32.WS_POPUP) != 0
                && parent != IntPtr.Zero
                && (parentStyle & Win32.WS_DISABLED) == 0
                && proc != "Photoshop.exe"
                && proc != "Illustrator.exe")
                return true;

            if (title == "Windows Shell Experience Host")
                return true;

            if ((title == "Xbox" || title == "Movies & TV" || title == "Photos")
                && (cls == "Windows.UI.Core.CoreWindow" || cls == "ApplicationFrameWindow"))
                return true;

            WindowManager.GetPos(hwnd, out int x, out int y, out int w, out int h);
            var info = new WindowInfo
            {
                Id = hwnd,
                Title = title,
                Class = cls,
                Style = style,
                ExStyle = ex,
                ProcessName = proc,
                ProcessPath = WindowManager.GetProcessPath(hwnd),
                Pid = WindowManager.GetPid(hwnd),
                X = x, Y = y, Width = w, Height = h,
                ParentId = parent,
                Topmost = (ex & Win32.WS_EX_TOPMOST) != 0,
                Index = result.Count + 1,
            };
            result.Add(info);
            if (hwnd == foreground)
                act = info;
            return true;
        };
        Win32.EnumWindows(cb, IntPtr.Zero);
        active = act;
        return result;
    }

    public static List<WindowInfo> List() => List(out _);

    /// <summary>Visible top-level windows of a class, in Z order (first = topmost). For same-class rotation.</summary>
    public static List<IntPtr> ByClass(string cls)
    {
        var res = new List<IntPtr>();
        Win32.EnumWindowsProc cb = (h, _) =>
        {
            if (Win32.IsWindowVisible(h) && WindowManager.GetClass(h) == cls)
                res.Add(h);
            return true;
        };
        Win32.EnumWindows(cb, IntPtr.Zero);
        return res;
    }

    public static WindowInfo? FindById(IntPtr id)
    {
        foreach (var w in List())
            if (w.Id == id) return w;
        return null;
    }

    /// <summary>
    /// AltTab_List_SameType: windows of the same process (+class when an ID is given).
    /// Each returned clone gets .MomIndex = its 1-based position in the full alt-tab list.
    /// </summary>
    public static List<WindowInfo> SameType(IntPtr id, string processName)
    {
        var toReturn = new List<WindowInfo>();
        var list = List();

        if (id != IntPtr.Zero)
        {
            string proc = "";
            string cls = "";
            foreach (var w in list)
            {
                if (w.Id == id) { proc = w.ProcessName; cls = w.Class; break; }
            }
            for (int i = 0; i < list.Count; i++)
            {
                var w = list[i];
                if (w.ProcessName == proc && w.Class == cls)
                {
                    var clone = w.Clone();
                    clone.MomIndex = i + 1;
                    toReturn.Add(clone);
                }
            }
        }
        else if (!string.IsNullOrEmpty(processName))
        {
            for (int i = 0; i < list.Count; i++)
            {
                var w = list[i];
                if (w.ProcessName == processName)
                {
                    var clone = w.Clone();
                    clone.MomIndex = i + 1;
                    toReturn.Add(clone);
                }
            }
        }
        return toReturn;
    }
}
