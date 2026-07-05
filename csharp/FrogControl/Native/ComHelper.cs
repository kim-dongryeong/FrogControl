using System.Runtime.InteropServices;

namespace FrogControl.Native;

/// <summary>
/// Minimal replacement for AHK's ComObjActive(): grabs a running COM automation object
/// from the Running Object Table (used for Excel/Word horizontal scrolling). Returns null
/// if the app isn't running or automation is unavailable.
/// </summary>
public static class ComHelper
{
    [DllImport("oleaut32.dll", PreserveSig = false)]
    private static extern void GetActiveObject(ref Guid rclsid, IntPtr pvReserved,
        [MarshalAs(UnmanagedType.IUnknown)] out object ppunk);

    [DllImport("ole32.dll")]
    private static extern int CLSIDFromProgID([MarshalAs(UnmanagedType.LPWStr)] string lpszProgID, out Guid pclsid);

    public static object? GetActive(string progId)
    {
        try
        {
            if (CLSIDFromProgID(progId, out Guid clsid) != 0)
                return null;
            GetActiveObject(ref clsid, IntPtr.Zero, out object obj);
            return obj;
        }
        catch { return null; }
    }
}
