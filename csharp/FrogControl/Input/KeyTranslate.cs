using System.Runtime.InteropServices;
using System.Text;

namespace FrogControl.Input;

/// <summary>Translates a virtual-key + shift state into the character it would type (for the modal modes).</summary>
public static class KeyTranslate
{
    [DllImport("user32.dll")]
    private static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState,
        [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags);

    [DllImport("user32.dll")]
    private static extern uint MapVirtualKey(uint uCode, uint uMapType);

    public static char VkToChar(int vk, bool shift)
    {
        var keyState = new byte[256];
        if (shift) keyState[0x10] = 0x80;      // VK_SHIFT down
        uint sc = MapVirtualKey((uint)vk, 0);
        var sb = new StringBuilder(8);
        int rc = ToUnicode((uint)vk, sc, keyState, sb, sb.Capacity, 0);
        if (rc > 0 && sb.Length > 0)
        {
            char c = sb[0];
            if (!char.IsControl(c)) return c;
        }
        return '\0';
    }
}
