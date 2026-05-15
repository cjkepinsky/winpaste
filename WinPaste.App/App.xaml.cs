using System.IO;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;
using WinPaste.App.Models;
using WinPaste.App.Services;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace WinPaste.App;

public partial class App : System.Windows.Application
{
    private ClipboardHistoryStore? _store;
    private ClipboardMonitor? _monitor;
    private GlobalHotKey? _hotKey;
    private ThemeManager? _themeManager;
    private MainWindow? _pickerWindow;
    private Forms.NotifyIcon? _notifyIcon;
    private DispatcherTimer? _pollTimer;
    private bool _suppressNextCapture;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        ShutdownMode = ShutdownMode.OnExplicitShutdown;

        _themeManager = new ThemeManager();

        _store = new ClipboardHistoryStore();
        _store.Load();

        _pickerWindow = new MainWindow(_store, SelectClip);
        MainWindow = _pickerWindow;

        _monitor = new ClipboardMonitor();
        _monitor.ClipboardUpdated += OnClipboardUpdated;

        _hotKey = new GlobalHotKey(Key.V, ModifierKeys.Control | ModifierKeys.Shift);
        _hotKey.Pressed += (_, _) => Dispatcher.Invoke(TogglePicker);

        CreateTrayIcon();
        StartClipboardPolling();
        CaptureCurrentClipboard();

        if (!_hotKey.IsRegistered)
        {
            _notifyIcon?.ShowBalloonTip(
                4000,
                "WinPaste",
                $"Nie udało się zarejestrować Ctrl+Shift+V. {_hotKey.RegistrationError}",
                Forms.ToolTipIcon.Warning);
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _notifyIcon?.Dispose();
        _pollTimer?.Stop();
        _themeManager?.Dispose();
        _hotKey?.Dispose();
        _monitor?.Dispose();

        base.OnExit(e);
    }

    private void OnClipboardUpdated(object? sender, EventArgs e)
    {
        Dispatcher.BeginInvoke(CaptureCurrentClipboard);
    }

    private void CaptureCurrentClipboard()
    {
        if (_store is null)
        {
            return;
        }

        if (_suppressNextCapture)
        {
            _suppressNextCapture = false;
            return;
        }

        var snapshot = ClipboardReader.TryRead();
        if (snapshot is null)
        {
            return;
        }

        if (snapshot.Kind == ClipKind.Text && snapshot.Text is not null)
        {
            _store.AddText(snapshot.Text);
            return;
        }

        if (snapshot.Kind == ClipKind.Image && snapshot.Image is not null)
        {
            _store.AddImage(snapshot.Image);
        }
    }

    private void SelectClip(ClipItem item)
    {
        if (_store is null)
        {
            return;
        }

        _suppressNextCapture = ClipboardWriter.TryWrite(item, _store);
        _pickerWindow?.Hide();
    }

    private void TogglePicker()
    {
        if (_pickerWindow is null)
        {
            return;
        }

        if (_pickerWindow.IsVisible)
        {
            _pickerWindow.Hide();
            return;
        }

        _pickerWindow.ShowPicker();
    }

    private void CreateTrayIcon()
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Pokaż WinPaste", null, (_, _) => Dispatcher.Invoke(() => _pickerWindow?.ShowPicker()));
        menu.Items.Add("Zakończ", null, (_, _) => Dispatcher.Invoke(Shutdown));

        _notifyIcon = new Forms.NotifyIcon
        {
            Icon = LoadTrayIcon(),
            Text = "WinPaste",
            ContextMenuStrip = menu,
            Visible = true
        };

        _notifyIcon.DoubleClick += (_, _) => Dispatcher.Invoke(() => _pickerWindow?.ShowPicker());
    }

    private static Drawing.Icon LoadTrayIcon()
    {
        var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico");
        return File.Exists(iconPath)
            ? new Drawing.Icon(iconPath)
            : Drawing.Icon.ExtractAssociatedIcon(Environment.ProcessPath ?? string.Empty) ?? Drawing.SystemIcons.Application;
    }

    private void StartClipboardPolling()
    {
        _pollTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromMilliseconds(800)
        };

        _pollTimer.Tick += (_, _) => CaptureCurrentClipboard();
        _pollTimer.Start();
    }
}
