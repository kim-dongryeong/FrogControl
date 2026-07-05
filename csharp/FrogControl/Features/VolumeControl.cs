using System.Runtime.InteropServices;
using FrogControl.UI;

namespace FrogControl.Features;

/// <summary>
/// Master volume control via the Core Audio API (IAudioEndpointVolume) — the equivalent
/// of AHK's SoundSet/SoundGet. Adjust("+10") raises master volume by 10 percentage points.
/// </summary>
public static class VolumeControl
{
    public static void Adjust(int deltaPercent)
    {
        try
        {
            var ep = GetEndpoint();
            if (ep == null) return;
            ep.GetMasterVolumeLevelScalar(out float cur);
            float target = Math.Clamp(cur + deltaPercent / 100f, 0f, 1f);
            Guid ctx = Guid.Empty;
            ep.SetMasterVolumeLevelScalar(target, ref ctx);
            ep.GetMasterVolumeLevelScalar(out float now);
            Marshal.ReleaseComObject(ep);
            ToolTipService.ShowTimed($"volume: {Math.Round(now * 100)}", FrogControl.App.Settings.TooltipDurationShortMs);
        }
        catch { }
    }

    private static IAudioEndpointVolume? GetEndpoint()
    {
        var enumType = Type.GetTypeFromCLSID(new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E"));
        if (enumType == null) return null;
        var enumerator = (IMMDeviceEnumerator?)Activator.CreateInstance(enumType);
        if (enumerator == null) return null;
        try
        {
            enumerator.GetDefaultAudioEndpoint(EDataFlow.eRender, ERole.eMultimedia, out IMMDevice dev);
            var iid = typeof(IAudioEndpointVolume).GUID;
            dev.Activate(ref iid, 1 /*CLSCTX_INPROC_SERVER*/, IntPtr.Zero, out object o);
            Marshal.ReleaseComObject(dev);
            return (IAudioEndpointVolume)o;
        }
        finally { Marshal.ReleaseComObject(enumerator); }
    }

    // ---- Minimal Core Audio COM interfaces ----
    private enum EDataFlow { eRender, eCapture, eAll }
    private enum ERole { eConsole, eMultimedia, eCommunications }

    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDeviceEnumerator
    {
        int NotImpl1();
        [PreserveSig] int GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice ppDevice);
    }

    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDevice
    {
        [PreserveSig] int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
    }

    [ComImport, Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioEndpointVolume
    {
        [PreserveSig] int RegisterControlChangeNotify(IntPtr pNotify);
        [PreserveSig] int UnregisterControlChangeNotify(IntPtr pNotify);
        [PreserveSig] int GetChannelCount(out uint pnChannelCount);
        [PreserveSig] int SetMasterVolumeLevel(float fLevelDB, ref Guid pguidEventContext);
        [PreserveSig] int SetMasterVolumeLevelScalar(float fLevel, ref Guid pguidEventContext);
        [PreserveSig] int GetMasterVolumeLevel(out float pfLevelDB);
        [PreserveSig] int GetMasterVolumeLevelScalar(out float pfLevel);
        // remaining methods unused
    }
}
