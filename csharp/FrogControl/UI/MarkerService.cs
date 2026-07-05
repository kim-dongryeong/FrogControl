using System.Drawing;
using System.Windows.Forms;

namespace FrogControl.UI;

/// <summary>
/// Small pink squares shown at mouse-bookmark positions (port of the mousePosBookmark GUI squares).
/// Shown for a fixed duration then auto-removed.
/// </summary>
public static class MarkerService
{
    private sealed class Marker : Form
    {
        public Marker(int x, int y)
        {
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            StartPosition = FormStartPosition.Manual;
            BackColor = Color.FromArgb(0xEE, 0xAA, 0x99);
            Size = new Size(11, 11);
            Location = new Point(x - 5, y - 5);
        }
        protected override bool ShowWithoutActivation => true;
        protected override CreateParams CreateParams
        {
            get { var cp = base.CreateParams; cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008; return cp; }
        }
    }

    public static void ShowPoints(IEnumerable<(int x, int y)> points, int ms)
    {
        Ui.Post(() =>
        {
            var markers = new List<Marker>();
            foreach (var (x, y) in points)
            {
                var m = new Marker(x, y);
                m.Show();
                markers.Add(m);
            }
            var timer = new System.Windows.Forms.Timer { Interval = Math.Max(1, ms) };
            timer.Tick += (_, _) =>
            {
                timer.Stop();
                foreach (var m in markers) { if (!m.IsDisposed) m.Close(); }
            };
            timer.Start();
        });
    }
}
