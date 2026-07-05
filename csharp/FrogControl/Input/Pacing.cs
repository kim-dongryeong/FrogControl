namespace FrogControl.Input;

/// <summary>KeyWait-style pacing helpers used by the interactive movement/resize loops.</summary>
public static class Pacing
{
    /// <summary>Wait until the key is released, or until timeout (seconds). Matches AHK KeyWait, T&lt;sec&gt;.</summary>
    public static void KeyWaitRelease(int vk, double timeoutSec)
    {
        int ms = (int)(timeoutSec * 1000);
        int waited = 0;
        while (KeyState.IsDown(vk))
        {
            Thread.Sleep(2);
            waited += 2;
            if (ms > 0 && waited >= ms) break;
        }
    }

    /// <summary>Wait until the key is pressed, or until timeout (seconds). Returns true if pressed.</summary>
    public static bool KeyWaitDown(int vk, double timeoutSec)
    {
        int ms = (int)(timeoutSec * 1000);
        int waited = 0;
        while (!KeyState.IsDown(vk))
        {
            Thread.Sleep(2);
            waited += 2;
            if (ms > 0 && waited >= ms) return false;
        }
        return true;
    }
}
