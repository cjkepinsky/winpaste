using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Windows.Input;
using System.Windows.Interop;

namespace WinPaste.App.Services;

public sealed class GlobalHotKey : IDisposable
{
    private const int WmHotKey = 0x0312;
    private const uint ModAlt = 0x0001;
    private const uint ModControl = 0x0002;
    private const uint ModShift = 0x0004;
    private const uint ModWin = 0x0008;
    private const uint ModNoRepeat = 0x4000;
    private static int _nextId;

    private readonly int _id;
    private readonly HwndSource _source;
    private bool _disposed;

    public GlobalHotKey(Key key, ModifierKeys modifiers)
    {
        _id = Interlocked.Increment(ref _nextId);

        var parameters = new HwndSourceParameters("WinPaste Global HotKey")
        {
            WindowStyle = 0
        };

        _source = new HwndSource(parameters);
        _source.AddHook(WndProc);

        var virtualKey = KeyInterop.VirtualKeyFromKey(key);
        var nativeModifiers = ToNativeModifiers(modifiers) | ModNoRepeat;
        IsRegistered = RegisterHotKey(_source.Handle, _id, nativeModifiers, (uint)virtualKey);

        if (!IsRegistered)
        {
            RegistrationError = new Win32Exception(Marshal.GetLastWin32Error()).Message;
        }
    }

    public event EventHandler? Pressed;

    public bool IsRegistered { get; }

    public string? RegistrationError { get; }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        if (IsRegistered)
        {
            UnregisterHotKey(_source.Handle, _id);
        }

        _source.RemoveHook(WndProc);
        _source.Dispose();
        _disposed = true;
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WmHotKey && wParam.ToInt32() == _id)
        {
            Pressed?.Invoke(this, EventArgs.Empty);
            handled = true;
        }

        return IntPtr.Zero;
    }

    private static uint ToNativeModifiers(ModifierKeys modifiers)
    {
        uint result = 0;

        if (modifiers.HasFlag(ModifierKeys.Alt))
        {
            result |= ModAlt;
        }

        if (modifiers.HasFlag(ModifierKeys.Control))
        {
            result |= ModControl;
        }

        if (modifiers.HasFlag(ModifierKeys.Shift))
        {
            result |= ModShift;
        }

        if (modifiers.HasFlag(ModifierKeys.Windows))
        {
            result |= ModWin;
        }

        return result;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
