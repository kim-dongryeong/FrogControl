namespace FrogControl.Windows;

/// <summary>
/// Mirrors one entry of the AHK altTab_List[] object plus the fields WindowInfo() produced.
/// Mutable on purpose: the arrange engine annotates .Mon / .WidthNorm etc. during layout,
/// exactly like the AHK objects.
/// </summary>
public sealed class WindowInfo
{
    public IntPtr Id;
    public string Title = "";
    public string Class = "";
    public long Style;
    public long ExStyle;
    public string ProcessName = "";
    public string ProcessPath = "";
    public uint Pid;
    public int X, Y, Width, Height;
    public IntPtr ParentId;
    public int Index;            // 1-based position within the enumeration
    public bool Topmost;
    public long Area => (long)Width * Height;

    // Scratch fields used by the arrange engine (mirror the annotated AHK objects)
    public int Mon;
    public double WidthNorm;
    public double HeightNorm;
    public int MomIndex;         // index within the full alt-tab list (AltTab_List_SameType)

    public WindowInfo Clone() => (WindowInfo)MemberwiseClone();
}
