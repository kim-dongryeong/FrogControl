using System.Globalization;
using FrogControl.Input;
using FrogControl.Native;
using FrogControl.UI;
using FrogControl.Windows;

namespace FrogControl.Features;

/// <summary>
/// Port of the AHK "Date and Time Input Mode" (CapsLock &amp; o). Opens a modal loop that lets the
/// user compose the current date or time interactively (toggle year length, switch to time, rotate
/// field order, pick a separator) with a live tooltip, then types the result on Enter.
///
/// The engine captures/suppresses every physical key-down while a mode is active and pushes it to a
/// <see cref="KeyInputChannel"/> (via <see cref="ModeHost"/>), replacing AHK's blocking Input command.
/// </summary>
public static class DateTimeInputMode
{
    // Symbols usable as a separator, mirroring the AHK InStr(".,<>/:'`~[]{}\|=+-_!@#$%^&*()""", ...).
    private const string SymbolSet = ".,<>/:'`~[]{}\\|=+-_!@#$%^&*()\"";

    // Verbatim help text (AHK date_help). `n newlines become \n.
    private const string HelpText =
        "Date and Time Input Help\n\nPress a keyboard as bellow to change\n\n" +
        "O: YY ↔ YYYY\n" +
        "0: YY/MM/DD → DD/MM/YY → MM/DD/YY\n" +
        "P: HH:mm ↔ HH:mm:ss\n" +
        "Any symbol for separator(/.-: etc. ex) 12/04/26, 12-04-26)\n" +
        "Enter: enter the date or time\n" +
        "Esc: cancel\n\nFrogControl";

    // Virtual-key codes of the AHK Input end keys.
    private const int VkBackSpace = 0x08;
    private const int VkEnter = 0x0D;
    private const int VkEscape = 0x1B;

    /// <summary>
    /// Runs the whole modal input loop on the CURRENT thread (the engine calls this on a detached
    /// thread). Blocks on <see cref="KeyInputChannel.Read"/> between keystrokes.
    /// </summary>
    public static void Start()
    {
        var ch = ModeHost.Begin();

        // Save + suppress the system beep (SPI_GETBEEP / SPI_SETBEEP) and remember the real CapsLock
        // toggle state so both can be restored on exit.
        uint beep = SystemParams.GetBeep();
        bool capsInitial = CapsLockState.IsOn;
        SystemParams.SetBeep(0);

        bool escaped = false;
        string output = "";

        try
        {
            // Capture the moment once so the composed value never drifts mid-session.
            DateTime now = DateTime.Now;
            string yearShort = now.ToString("yy", CultureInfo.InvariantCulture);
            string yearLong = now.ToString("yyyy", CultureInfo.InvariantCulture);
            string monthStr = now.ToString("MM", CultureInfo.InvariantCulture);
            string dayStr = now.ToString("dd", CultureInfo.InvariantCulture);
            string hourStr = now.ToString("HH", CultureInfo.InvariantCulture);
            string minStr = now.ToString("mm", CultureInfo.InvariantCulture);
            string secStr = now.ToString("ss", CultureInfo.InvariantCulture);

            bool dateShort = true;       // true => 2-digit year, false => 4-digit year
            bool dateTimeShort = false;  // false => hh,mm,ss ; true => hh,mm
            string separator = "";
            string date1 = yearShort;
            string date2 = monthStr;
            string date3 = dayStr;

            // Base position (caret, else mouse) used to pick the monitor for the help tooltip and as
            // the last-known position when the caret can't be read on a later iteration.
            int cx, cy;
            if (!CaretHelper.TryGetCaret(out cx, out cy))
                InputSimulator.GetCursor(out cx, out cy);

            var mon = MonitorInfo.Collect();
            var m = mon.FromPointOrPrimary(cx, cy);
            int helpX = (m.WorkRight - m.WorkLeft) / 2;
            int helpY = m.WorkBottom - 300;

            while (true)
            {
                // Compose the current output and show it near the caret.
                output = date1 + separator + date2 + (date3 != "" ? separator + date3 : "");

                if (CaretHelper.TryGetCaret(out int ncx, out int ncy)) { cx = ncx; cy = ncy; }
                int yAdjust = cy < 30 ? 40 : -30;
                ToolTipService.Show(output + "     (Press ? for help)", 1, cx, cy + yAdjust);

                var kp = ch.Read();
                if (kp == null) continue; // (won't happen with the default -1 timeout, but stay safe)

                int vk = kp.Value.Vk;
                char rawc = kp.Value.Ch;

                // End keys (AHK ErrorLevel EndKey:*).
                if (vk == VkBackSpace) { separator = ""; continue; }
                if (vk == VkEnter) { escaped = false; break; }
                if (vk == VkEscape) { escaped = true; break; }

                char lc = char.ToLowerInvariant(rawc);
                if (lc == 'o')
                {
                    // Toggle 2-/4-digit year (and reset to the date fields).
                    dateShort = !dateShort;
                    date1 = dateShort ? yearShort : yearLong;
                    date2 = monthStr;
                    date3 = dayStr;
                }
                else if (lc == 'p')
                {
                    // Switch the three fields to time; short omits seconds.
                    dateTimeShort = !dateTimeShort;
                    date1 = hourStr;
                    date2 = minStr;
                    date3 = dateTimeShort ? "" : secStr;
                }
                else if (rawc != '\0' && SymbolSet.IndexOf(rawc) >= 0)
                {
                    separator = rawc.ToString();
                }
                else if (rawc == ';')
                {
                    separator = ":";
                }
                else if (rawc == '0')
                {
                    // Rotate YY/MM/DD -> DD/MM/YY -> MM/DD/YY (faithful port of the AHK chain,
                    // comparing each field to the captured day string).
                    if (date3 == dayStr) { date3 = date1; date1 = dayStr; }
                    else if (date1 == dayStr) { date1 = date2; date2 = dayStr; }
                    else if (date2 == dayStr) { date1 = date3; date2 = monthStr; date3 = dayStr; }
                }
                else if (rawc == '?')
                {
                    ToolTipService.ShowTimed(HelpText, App.Settings.TooltipDurationLongMs, 2, helpX, helpY);
                }
            }

            // Normal exit: clear the tooltips and type the result unless the user cancelled.
            ToolTipService.Hide(1);
            ToolTipService.Hide(2);
            if (!escaped)
                InputSimulator.SendUnicodeString(output); // SendRaw: literal, no key translation
        }
        finally
        {
            // Guaranteed cleanup (also covers an unexpected exception mid-loop).
            ToolTipService.Hide(1);
            ToolTipService.Hide(2);
            SystemParams.SetBeep(beep);
            CapsLockState.Set(capsInitial);
            ModeHost.End(ch);
        }
    }
}
