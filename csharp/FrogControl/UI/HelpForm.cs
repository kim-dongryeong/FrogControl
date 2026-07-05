using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

namespace FrogControl.UI;

/// <summary>
/// The help window — port of ShowHelp() from FC_Helpers.ahk. Reads the tab-separated
/// "shortcut list-{en,ko}.txt" into a two-column list. One instance per language, reused.
/// </summary>
public sealed class HelpForm : Form
{
    private static HelpForm? _en;
    private static HelpForm? _ko;

    public static void Show(string lang)
    {
        Ui.Post(() =>
        {
            bool ko = lang == "ko";
            FrogControl.App.HelpLang = ko ? 2 : 1;
            ref HelpForm? slot = ref (ko ? ref _ko : ref _en);
            if (slot == null || slot.IsDisposed)
                slot = new HelpForm(ko);
            if (!slot.Visible) slot.Show();
            slot.WindowState = FormWindowState.Normal;
            slot.BringToFront();
            slot.Activate();
        });
    }

    private HelpForm(bool ko)
    {
        string listFile = ko ? AppInfo.ShortcutListKo : AppInfo.ShortcutListEn;
        string helpTitle = ko ? "프로그 컨트롤(FrogControl) 도움말" : AppInfo.Name + " Help";
        string listLabel = ko ? "단축키 목록" : "Shortcut list";
        string authorLabel = ko ? "제작자 : " + AppInfo.Author : "Created by " + AppInfo.Author;

        Text = "FrogControl Help";
        StartPosition = FormStartPosition.CenterScreen;
        Size = new Size(900, 720);
        MinimumSize = new Size(500, 400);
        try { Icon = new Icon(AppInfo.IconPath); } catch { }

        var root = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 4, Padding = new Padding(10) };
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));

        var title = new Label { Text = helpTitle, Font = new Font("Segoe UI", 15f, FontStyle.Bold), AutoSize = true, Margin = new Padding(3, 3, 3, 8) };
        root.Controls.Add(title, 0, 0);
        root.Controls.Add(new Label { Text = listLabel, AutoSize = true, Margin = new Padding(3) }, 0, 1);

        var lv = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true,
            GridLines = false,
            Font = new Font("Consolas", 9.5f),
        };
        lv.Columns.Add("Hotkey", 320);
        lv.Columns.Add("Action", 540);
        LoadList(lv, listFile);
        root.Controls.Add(lv, 0, 2);

        var footer = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, AutoSize = true, Dock = DockStyle.Fill, Margin = new Padding(3, 8, 3, 3) };
        footer.Controls.Add(new Label { Text = $"Version {AppInfo.Version} ({AppInfo.UpdateDate}) — {AppInfo.Edition}", AutoSize = true });
        footer.Controls.Add(MakeLink(AppInfo.Site, AppInfo.Site));
        footer.Controls.Add(new Label { Text = authorLabel, AutoSize = true, Margin = new Padding(3, 8, 3, 0) });
        footer.Controls.Add(MakeLink(AppInfo.AuthorEmail, "mailto:" + AppInfo.AuthorEmail));
        footer.Controls.Add(new Label { Text = "Free software under the GNU GPL v3.", AutoSize = true });
        var ok = new Button { Text = "&OK", Width = 80, Margin = new Padding(3, 8, 3, 3) };
        ok.Click += (_, _) => Hide();
        footer.Controls.Add(ok);
        AcceptButton = ok;
        root.Controls.Add(footer, 0, 3);

        Controls.Add(root);

        FormClosing += (_, e) =>
        {
            // Hide instead of dispose so the reused instance survives (like the AHK GUI).
            if (e.CloseReason == CloseReason.UserClosing) { e.Cancel = true; Hide(); }
        };
    }

    private static void LoadList(ListView lv, string listFile)
    {
        if (!File.Exists(listFile))
        {
            lv.Items.Add(new ListViewItem(new[] { "(file not found)", listFile }));
            return;
        }
        foreach (var line in File.ReadLines(listFile))
        {
            var parts = line.Split('\t');
            string a = parts.Length > 0 ? parts[0] : "";
            string b = parts.Length > 1 ? parts[1] : "";
            lv.Items.Add(new ListViewItem(new[] { a, b }));
        }
    }

    private static LinkLabel MakeLink(string text, string url)
    {
        var link = new LinkLabel { Text = text, AutoSize = true };
        link.LinkClicked += (_, _) =>
        {
            try { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); } catch { }
        };
        return link;
    }
}
