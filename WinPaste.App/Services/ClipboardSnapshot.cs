using System.Windows.Media.Imaging;
using WinPaste.App.Models;

namespace WinPaste.App.Services;

public sealed record ClipboardSnapshot(ClipKind Kind, string? Text, BitmapSource? Image);
