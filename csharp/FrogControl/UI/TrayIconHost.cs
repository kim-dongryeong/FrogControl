using System.Drawing;
using System.Windows.Forms;

namespace FrogControl.UI;

/// <summary>
/// The tray icon + menu (port of the AHK Menu, Tray block). Holds the NotifyIcon and the
/// Enable/Disable toggle, the About (Korean/English) items, Reload and Exit.
/// </summary>
public static class TrayIconHost
{
    private static NotifyIcon? _icon;
    private static ToolStripMenuItem? _toggleItem;

    public static void Init(Action toggleSuspend, Action reload, Action exit)
    {
        _icon = new NotifyIcon
        {
            Text = $"{AppInfo.Name} {AppInfo.Version}",
            Visible = true,
            Icon = LoadIcon(),
        };
        TrayTipService.Init(_icon);

        var menu = new ContextMenuStrip();
        _toggleItem = new ToolStripMenuItem("Disable", null, (_, _) => toggleSuspend());
        menu.Items.Add(_toggleItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem("About (Korean)", null, (_, _) => HelpForm.Show("ko")));
        menu.Items.Add(new ToolStripMenuItem("About (English)", null, (_, _) => HelpForm.Show("en")));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(new ToolStripMenuItem("Reload", null, (_, _) => reload()));
        menu.Items.Add(new ToolStripMenuItem("Exit", null, (_, _) => exit()));
        _icon.ContextMenuStrip = menu;

        // Double-click opens help in the last-used language.
        _icon.DoubleClick += (_, _) => HelpForm.Show(FrogControl.App.HelpLang == 2 ? "ko" : "en");
    }

    public static void UpdateSuspendState()
    {
        Ui.Post(() =>
        {
            if (_toggleItem != null)
                _toggleItem.Text = FrogControl.App.Suspended ? "Enable" : "Disable";
        });
    }

    public static void Dispose()
    {
        if (_icon != null)
        {
            _icon.Visible = false;
            _icon.Dispose();
            _icon = null;
        }
    }

    private static Icon LoadIcon()
    {
        try
        {
            if (File.Exists(AppInfo.IconPath))
                return new Icon(AppInfo.IconPath);
        }
        catch { }
        return SystemIcons.Application;
    }
}
