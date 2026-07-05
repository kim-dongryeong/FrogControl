using System.Drawing;
using System.Windows.Forms;
using FrogControl.Windows;

namespace FrogControl.UI;

/// <summary>Port of Print_Windows_ListView(): a debug grid of the enumerated windows (Win+Ctrl+L).</summary>
public static class DebugListView
{
    public static void Show(List<WindowInfo> windows, WindowInfo? active, string title)
    {
        Ui.Post(() =>
        {
            var form = new Form
            {
                Text = title,
                Size = new Size(1200, 700),
                StartPosition = FormStartPosition.CenterScreen,
            };
            try { form.Icon = new Icon(AppInfo.IconPath); } catch { }

            var lv = new ListView { Dock = DockStyle.Fill, View = View.Details, FullRowSelect = true, GridLines = true };
            foreach (var col in new[] { "#", "ID", "PID", "Style", "ExStyle", "Parent", "x", "y", "w", "h", "area", "Topmost", "ProcessName", "class", "Title", "ProcessPath" })
                lv.Columns.Add(col, -2);

            void AddRow(WindowInfo w, string tag)
            {
                lv.Items.Add(new ListViewItem(new[]
                {
                    tag,
                    "0x" + w.Id.ToString("X"),
                    w.Pid.ToString(),
                    "0x" + w.Style.ToString("X"),
                    "0x" + w.ExStyle.ToString("X"),
                    "0x" + w.ParentId.ToString("X"),
                    w.X.ToString(), w.Y.ToString(), w.Width.ToString(), w.Height.ToString(),
                    w.Area.ToString(),
                    w.Topmost ? "1" : "0",
                    w.ProcessName, w.Class, w.Title, w.ProcessPath,
                }));
            }

            foreach (var w in windows) AddRow(w, w.Index.ToString());
            if (active != null) AddRow(active, "A");
            lv.AutoResizeColumns(ColumnHeaderAutoResizeStyle.ColumnContent);

            form.Controls.Add(lv);
            form.Show();
        });
    }
}
