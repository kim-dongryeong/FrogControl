using FrogControl.Native;

namespace FrogControl.UI;

/// <summary>
/// Port of SystemCursor() from FC_Helpers.ahk: during a keyboard/mouse resize-drag it
/// temporarily replaces every system cursor with the appropriate resize cursor, then
/// restores the saved defaults. Toggle() flips between the two states.
/// </summary>
public static class SystemCursorService
{
    // OCR_* ids in the exact order the AHK array used (index 1-based below).
    private static readonly int[] CursorIds =
        { 32646, 32645, 32643, 32644, 32642, 32512, 32513, 32514, 32515, 32516, 32648, 32649, 32650 };

    private static readonly IntPtr[] SavedDefaults = new IntPtr[CursorIds.Length];
    private static bool _initialized;
    private static bool _defaultsActive = true;  // AHK $: true = saved cursors in effect
    private static readonly object Sync = new();

    private static void EnsureInit()
    {
        if (_initialized) return;
        for (int i = 0; i < CursorIds.Length; i++)
        {
            IntPtr h = Win32.LoadCursor(IntPtr.Zero, CursorIds[i]);
            SavedDefaults[i] = Win32.CopyImage(h, Win32.IMAGE_CURSOR, 0, 0, 0);
        }
        _initialized = true;
    }

    /// <summary>
    /// Toggle system cursors. When defaults are active, replaces all cursors with a copy of
    /// the cursor at <paramref name="cursorIndicator"/> (1-based). Otherwise restores defaults.
    /// </summary>
    public static void Toggle(int cursorIndicator)
    {
        lock (Sync)
        {
            EnsureInit();
            int idx = Math.Clamp(cursorIndicator, 1, CursorIds.Length) - 1;
            if (_defaultsActive)
            {
                for (int i = 0; i < CursorIds.Length; i++)
                {
                    IntPtr copy = Win32.CopyImage(SavedDefaults[idx], Win32.IMAGE_CURSOR, 0, 0, 0);
                    Win32.SetSystemCursor(copy, (uint)CursorIds[i]);
                }
                _defaultsActive = false;
            }
            else
            {
                RestoreInternal();
            }
        }
    }

    /// <summary>Force-restore the default cursors (safety net when a drag ends abnormally).</summary>
    public static void Restore()
    {
        lock (Sync)
        {
            if (!_initialized || _defaultsActive) return;
            RestoreInternal();
        }
    }

    private static void RestoreInternal()
    {
        for (int i = 0; i < CursorIds.Length; i++)
        {
            IntPtr copy = Win32.CopyImage(SavedDefaults[i], Win32.IMAGE_CURSOR, 0, 0, 0);
            Win32.SetSystemCursor(copy, (uint)CursorIds[i]);
        }
        _defaultsActive = true;
    }
}
