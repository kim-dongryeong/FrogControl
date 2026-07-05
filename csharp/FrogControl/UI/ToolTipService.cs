using System.Drawing;
using System.Windows.Forms;
using FrogControl.Native;

namespace FrogControl.UI;

/// <summary>
/// Free-floating, numbered tooltips at arbitrary screen coordinates — the managed
/// equivalent of AHK's ToolTip / RemoveToolTip / fct_RemoveToolTip_time. Slot numbers
/// match the AHK usage (1 = default, 2/3 = help/secondary). Coordinates are SCREEN coords;
/// pass null to place near the mouse cursor (AHK's default behaviour).
/// </summary>
public static class ToolTipService
{
    private sealed class TipWindow : Form
    {
        private readonly Label _label;
        public System.Windows.Forms.Timer? HideTimer;

        public TipWindow()
        {
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            StartPosition = FormStartPosition.Manual;
            BackColor = Color.FromArgb(255, 255, 225);   // classic tooltip yellow
            AutoScaleMode = AutoScaleMode.None;
            Padding = new Padding(3, 2, 3, 2);
            _label = new Label
            {
                AutoSize = true,
                Font = new Font("Segoe UI", 9f),
                ForeColor = Color.Black,
                Location = new Point(3, 2),
                Text = "",
            };
            Controls.Add(_label);
        }

        protected override bool ShowWithoutActivation => true;

        protected override CreateParams CreateParams
        {
            get
            {
                var cp = base.CreateParams;
                cp.ExStyle |= 0x08000000 /*WS_EX_NOACTIVATE*/ | 0x00000080 /*WS_EX_TOOLWINDOW*/ | 0x00000008 /*WS_EX_TOPMOST*/;
                return cp;
            }
        }

        public void Update(string text, int x, int y)
        {
            _label.Text = text;
            var sz = _label.PreferredSize;
            ClientSize = new Size(sz.Width + 6, sz.Height + 4);
            // Keep on-screen
            var screen = Screen.FromPoint(new Point(x, y)).WorkingArea;
            if (x + Width > screen.Right) x = screen.Right - Width;
            if (y + Height > screen.Bottom) y = screen.Bottom - Height;
            if (x < screen.Left) x = screen.Left;
            if (y < screen.Top) y = screen.Top;
            Location = new Point(x, y);
            if (!Visible)
                Show();
            else
                Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            ControlPaint.DrawBorder(e.Graphics, ClientRectangle, Color.FromArgb(118, 118, 118), ButtonBorderStyle.Solid);
        }
    }

    private static readonly Dictionary<int, TipWindow> Slots = new();

    public static void Show(string text, int slot = 1, int? x = null, int? y = null)
    {
        Ui.Post(() =>
        {
            int px, py;
            if (x.HasValue && y.HasValue) { px = x.Value; py = y.Value; }
            else { InputCursor(out px, out py); px += 16; py += 16; }

            if (!Slots.TryGetValue(slot, out var w) || w.IsDisposed)
            {
                w = new TipWindow();
                Slots[slot] = w;
            }
            w.HideTimer?.Stop();
            w.Update(text ?? "", px, py);
        });
    }

    /// <summary>Show, then auto-hide after <paramref name="ms"/> (SetTimer, RemoveToolTip, ms).</summary>
    public static void ShowTimed(string text, int ms, int slot = 1, int? x = null, int? y = null)
    {
        Show(text, slot, x, y);
        Ui.Post(() =>
        {
            if (Slots.TryGetValue(slot, out var w) && !w.IsDisposed)
            {
                w.HideTimer ??= new System.Windows.Forms.Timer();
                w.HideTimer.Stop();
                w.HideTimer.Interval = Math.Max(1, ms);
                w.HideTimer.Tick -= HideTick;
                w.HideTimer.Tag = slot;
                w.HideTimer.Tick += HideTick;
                w.HideTimer.Start();
            }
        });
    }

    private static void HideTick(object? sender, EventArgs e)
    {
        if (sender is System.Windows.Forms.Timer t && t.Tag is int slot)
        {
            t.Stop();
            Hide(slot);
        }
    }

    public static void Hide(int slot = 1)
    {
        Ui.Post(() =>
        {
            if (Slots.TryGetValue(slot, out var w) && !w.IsDisposed)
            {
                w.HideTimer?.Stop();
                w.Hide();
            }
        });
    }

    public static void HideAll()
    {
        Ui.Post(() =>
        {
            foreach (var w in Slots.Values)
                if (!w.IsDisposed) { w.HideTimer?.Stop(); w.Hide(); }
        });
    }

    private static void InputCursor(out int x, out int y)
    {
        Win32.GetCursorPos(out var p);
        x = p.X; y = p.Y;
    }
}
