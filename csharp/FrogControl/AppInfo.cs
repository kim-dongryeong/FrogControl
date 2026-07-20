namespace FrogControl;

/// <summary>Application metadata — the C# analogue of the AppName/AppVersion/... block.</summary>
public static class AppInfo
{
    public const string Name = "FrogControl";
    public const string Author = "Kim Dongryeong";
    public const string AuthorEmail = "kdr@kdr.kr";
    public const string UpdateDate = "2026-07-05";
    public const string Version = "2.1.0";
    public const string Site = "https://github.com/kim-dongryeong/FrogControl";
    public const string Edition = ".NET (C#) native port";

    /// <summary>Directory the exe lives in (help data + icon are copied next to it).</summary>
    public static string BaseDir => AppContext.BaseDirectory;

    public static string IconPath => Path.Combine(BaseDir, "frog face icon 3.ico");
    public static string ShortcutListEn => Path.Combine(BaseDir, "shortcut list-en.txt");
    public static string ShortcutListKo => Path.Combine(BaseDir, "shortcut list-ko.txt");
    public static string SettingsPath => Path.Combine(BaseDir, "frogcontrol.settings.json");
}
