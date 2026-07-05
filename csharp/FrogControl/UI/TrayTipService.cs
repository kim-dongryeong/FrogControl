using System.Windows.Forms;

namespace FrogControl.UI;

/// <summary>Balloon notifications via the tray icon — the equivalent of AHK's TrayTip.</summary>
public static class TrayTipService
{
    private static NotifyIcon? _icon;

    public static void Init(NotifyIcon icon) => _icon = icon;

    public static void Show(string title, string text)
    {
        Ui.Post(() =>
        {
            if (_icon == null) return;
            _icon.BalloonTipTitle = string.IsNullOrEmpty(title) ? AppInfo.Name : title;
            _icon.BalloonTipText = string.IsNullOrEmpty(text) ? " " : text;
            _icon.ShowBalloonTip(3000);
        });
    }
}
