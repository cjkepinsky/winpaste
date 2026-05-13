using Microsoft.Win32;
using System.Windows;
using System.Windows.Media;
using MediaColor = System.Windows.Media.Color;
using WpfApplication = System.Windows.Application;

namespace WinPaste.App.Services;

public sealed class ThemeManager : IDisposable
{
    private const string PersonalizeKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize";
    private const string AppsUseLightThemeValue = "AppsUseLightTheme";

    private bool _disposed;

    public ThemeManager()
    {
        ApplySystemTheme();
        SystemEvents.UserPreferenceChanged += OnUserPreferenceChanged;
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        SystemEvents.UserPreferenceChanged -= OnUserPreferenceChanged;
        _disposed = true;
    }

    private void OnUserPreferenceChanged(object sender, UserPreferenceChangedEventArgs e)
    {
        if (e.Category is UserPreferenceCategory.General
            or UserPreferenceCategory.VisualStyle
            or UserPreferenceCategory.Color)
        {
            WpfApplication.Current.Dispatcher.BeginInvoke(ApplySystemTheme);
        }
    }

    private static void ApplySystemTheme()
    {
        ApplyPalette(IsSystemDarkMode() ? ThemePalette.Dark : ThemePalette.Light);
    }

    private static bool IsSystemDarkMode()
    {
        using var key = Registry.CurrentUser.OpenSubKey(PersonalizeKeyPath);
        var value = key?.GetValue(AppsUseLightThemeValue);
        return value is int intValue && intValue == 0;
    }

    private static void ApplyPalette(ThemePalette palette)
    {
        SetBrush("PanelBackgroundBrush", palette.PanelBackground);
        SetBrush("PanelBorderBrush", palette.PanelBorder);
        SetBrush("TextPrimaryBrush", palette.TextPrimary);
        SetBrush("TextSecondaryBrush", palette.TextSecondary);
        SetBrush("AccentBrush", palette.Accent);
        SetBrush("CardBackgroundBrush", palette.CardBackground);
        SetBrush("CardBorderBrush", palette.CardBorder);
        SetBrush("PreviewBackgroundBrush", palette.PreviewBackground);
        SetBrush("HoverBorderBrush", palette.HoverBorder);
        WpfApplication.Current.Resources["PanelShadowColor"] = palette.PanelShadow;
    }

    private static void SetBrush(string key, MediaColor color)
    {
        WpfApplication.Current.Resources[key] = new SolidColorBrush(color);
    }

    private sealed record ThemePalette(
        MediaColor PanelBackground,
        MediaColor PanelBorder,
        MediaColor TextPrimary,
        MediaColor TextSecondary,
        MediaColor Accent,
        MediaColor CardBackground,
        MediaColor CardBorder,
        MediaColor PreviewBackground,
        MediaColor HoverBorder,
        MediaColor PanelShadow)
    {
        public static ThemePalette Light { get; } = new(
            MediaColor.FromRgb(248, 249, 251),
            MediaColor.FromRgb(203, 210, 220),
            MediaColor.FromRgb(24, 32, 43),
            MediaColor.FromRgb(104, 115, 132),
            MediaColor.FromRgb(36, 116, 216),
            Colors.White,
            MediaColor.FromRgb(216, 222, 232),
            MediaColor.FromRgb(238, 242, 246),
            MediaColor.FromRgb(140, 183, 234),
            MediaColor.FromRgb(36, 42, 51));

        public static ThemePalette Dark { get; } = new(
            MediaColor.FromRgb(28, 31, 36),
            MediaColor.FromRgb(67, 73, 84),
            MediaColor.FromRgb(241, 244, 248),
            MediaColor.FromRgb(166, 176, 190),
            MediaColor.FromRgb(95, 168, 255),
            MediaColor.FromRgb(38, 42, 49),
            MediaColor.FromRgb(76, 84, 96),
            MediaColor.FromRgb(22, 25, 30),
            MediaColor.FromRgb(111, 178, 255),
            Colors.Black);
    }
}
