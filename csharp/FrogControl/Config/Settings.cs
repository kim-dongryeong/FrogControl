using System.Text.Json;
using System.Text.Json.Serialization;

namespace FrogControl.Config;

/// <summary>
/// The "A/B/C" technology/behaviour options the port exposes so they can be tested and
/// swapped without recompiling. Written to frogcontrol.settings.json next to the exe on
/// first run; edit that file (or use the tray menu for the common toggles) and Reload.
/// </summary>
public sealed class Settings
{
    // ---- Constants ported from the AHK SETTING_CONSTANT_* block ----
    public int HalfTrans { get; set; } = 100;                 // SETTING_CONSTANT_HALFTRANS
    public int FocusTrans { get; set; } = 250;                // SETTING_CONSTANT_FOCUSTRANS
    public int TooltipDurationShortMs { get; set; } = 1000;   // SETTING_CONSTANT_TOOLTIPDUR_S
    public int TooltipDurationLongMs { get; set; } = 10000;   // SETTING_CONSTANT_TOOLTIPDUR_L
    public int WinMovePxLarge { get; set; } = 200;            // SETTING_CONSTANT_WINMOV_PX_L
    public int WinMovePxSmall { get; set; } = 20;             // SETTING_CONSTANT_WINMOV_PX_S
    public double WinMoveStepRepSec { get; set; } = 0.2;      // SETTING_CONSTANT_WINMOV_STEP_REP
    public double WinMovePxLRepSec { get; set; } = 0.05;
    public double WinMovePxSRepSec { get; set; } = 0.006;
    public int CapsMoveCorner { get; set; } = 180;            // SETTING_CONSTANT_CAPSMOVE_CORNER
    public int CapsMoveLrb { get; set; } = 150;               // SETTING_CONSTANT_CAPSMOVE_LRB
    public int CapsMoveHalfTop { get; set; } = 150;           // SETTING_CONSTANT_CAPSMOVE_HALFTOP
    public int CapsMoveTop { get; set; } = 60;                // SETTING_CONSTANT_CAPSMOVE_TOP
    public int WheelScrollSpeedUpDefault { get; set; } = 4;

    // ---- A/B/C behaviour switches ----

    /// <summary>
    /// How "move mouse by keyboard" (mouse-control mode arrow holding) moves the cursor.
    /// The AHK code experimented with both SetCursorPos and MouseMove; try each.
    /// </summary>
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public MouseMoveBackend MouseMoveBackend { get; set; } = MouseMoveBackend.SetCursorPos;

    /// <summary>How windows are activated. Attach = AttachThreadInput trick (robust); Plain = SetForegroundWindow only.</summary>
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public ActivationBackend ActivationBackend { get; set; } = ActivationBackend.AttachThreadInput;

    /// <summary>When true, tapping CapsLock alone still toggles the real CapsLock LED (AHK behaviour).</summary>
    public bool CapsLockTapToggles { get; set; } = true;

    /// <summary>When true, CapsLock acts purely as a prefix and its normal toggle is suppressed (AHK behaviour).</summary>
    public bool SuppressCapsLock { get; set; } = true;

    /// <summary>Default help language: "en" or "ko".</summary>
    public string DefaultHelpLanguage { get; set; } = "en";

    /// <summary>Window-rotation "popup" mode was marked unstable in AHK; keep it available but toggleable.</summary>
    public bool EnableUnstableRotation { get; set; } = true;

    // ---- Load / save ----
    public static Settings Load()
    {
        try
        {
            if (File.Exists(AppInfo.SettingsPath))
            {
                string json = File.ReadAllText(AppInfo.SettingsPath);
                var s = JsonSerializer.Deserialize<Settings>(json, JsonOpts);
                if (s != null) return s;
            }
        }
        catch { /* fall through to defaults */ }

        var def = new Settings();
        try { def.Save(); } catch { }
        return def;
    }

    public void Save()
    {
        try
        {
            File.WriteAllText(AppInfo.SettingsPath, JsonSerializer.Serialize(this, JsonOpts));
        }
        catch { }
    }

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true,
    };
}

public enum MouseMoveBackend
{
    /// <summary>DllCall("SetCursorPos") — the AHK default for the fine control paths.</summary>
    SetCursorPos,
    /// <summary>SendInput relative mouse move.</summary>
    SendInputRelative,
}

public enum ActivationBackend
{
    AttachThreadInput,
    Plain,
}
