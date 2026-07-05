using System.Windows.Forms;
using FrogControl.Input;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Window bookmarks at F1..F9, list at F10 (port of FC_Bookmarks.ahk + the CapsLock &amp; F1..F10 hotkeys).
///   CapsLock + Ctrl + Fn -> bookmark the current window at Fn
///   CapsLock + Fn        -> activate the bookmark (minimise it if it is already active)
///   CapsLock + F10       -> list all window bookmarks
/// </summary>
public static class WindowBookmarks
{
    private sealed class Bookmark
    {
        public IntPtr Id;
        public string Title = "";
        public string ProcessName = "";
        public string ProcessPath = "";
        public string Class = "";
    }

    private static readonly Dictionary<string, Bookmark> Store = new();

    /// <summary>Handle CapsLock + [Ctrl] + Fn. modifierCtrl true => save; else => activate/minimise.</summary>
    public static void HandleFn(string fnKey)
    {
        if (KeyState.Ctrl)
            Setup(fnKey);
        else
            Operate(fnKey);
    }

    private static void Setup(string fnKey)
    {
        IntPtr id = WindowManager.Active;
        if (id == IntPtr.Zero || string.IsNullOrEmpty(WindowManager.GetTitle(id)))
        {
            TrayTipService.Show($"Window bookmark - {fnKey} is not saved", "Please select a window first.");
            return;
        }
        var bm = new Bookmark
        {
            Id = id,
            Title = WindowManager.GetTitle(id),
            ProcessName = WindowManager.GetProcessName(id),
            ProcessPath = WindowManager.GetProcessPath(id),
            Class = WindowManager.GetClass(id),
        };
        Store[fnKey] = bm;
        string procShort = bm.ProcessName.Split('.')[0];
        TrayTipService.Show($"Window bookmark - {fnKey} saved", $"{procShort} ({bm.Title})");
    }

    private static void Operate(string fnKey)
    {
        if (!Store.TryGetValue(fnKey, out var bm) || bm.Id == IntPtr.Zero)
        {
            TrayTipService.Show($"There is no window bookmark at {fnKey}.",
                $"You can bookmark a window by pressing CapsLock + Ctrl + {fnKey}");
            return;
        }
        if (bm.Id == WindowManager.Active)
            WindowManager.Minimize(bm.Id);
        else if (WindowManager.Exists(bm.Id))
            WindowManager.Activate(bm.Id);
        else
            TrayTipService.Show($"Window bookmark {fnKey} no longer exists", bm.Title);
    }

    public static void ListAll()
    {
        var sb = new System.Text.StringBuilder();
        for (int i = 1; i <= 9; i++)
        {
            string fn = "F" + i;
            if (Store.TryGetValue(fn, out var bm) && bm.Id != IntPtr.Zero)
                sb.AppendLine($"CapsLock + {fn} = 0x{bm.Id.ToString("X")} - {bm.Title}");
            else
                sb.AppendLine($"CapsLock + {fn} = (empty)");
        }
        Ui.Post(() => MessageBox.Show(sb.ToString(), "CapsLock + F1 ~ F9"));
    }
}
