using System.Runtime.InteropServices;
using System.Windows;
using System.IO;
using System.Windows.Media.Imaging;
using WinPaste.App.Models;
using WpfClipboard = System.Windows.Clipboard;
using WpfTextDataFormat = System.Windows.TextDataFormat;

namespace WinPaste.App.Services;

public static class ClipboardWriter
{
    public static bool TryWrite(ClipItem item, ClipboardHistoryStore store)
    {
        for (var attempt = 0; attempt < 6; attempt++)
        {
            try
            {
                if (item.Kind == ClipKind.Text)
                {
                    WpfClipboard.SetText(item.Text ?? string.Empty, WpfTextDataFormat.UnicodeText);
                    return true;
                }

                var imagePath = store.GetImagePath(item);
                if (string.IsNullOrWhiteSpace(imagePath) || !File.Exists(imagePath))
                {
                    return false;
                }

                WpfClipboard.SetImage(LoadBitmap(imagePath));
                return true;
            }
            catch (COMException)
            {
                Thread.Sleep(50);
            }
            catch (ExternalException)
            {
                Thread.Sleep(50);
            }
            catch (InvalidOperationException)
            {
                Thread.Sleep(50);
            }
        }

        return false;
    }

    private static BitmapSource LoadBitmap(string path)
    {
        var bitmap = new BitmapImage();
        bitmap.BeginInit();
        bitmap.CacheOption = BitmapCacheOption.OnLoad;
        bitmap.UriSource = new Uri(path, UriKind.Absolute);
        bitmap.EndInit();

        if (bitmap.CanFreeze)
        {
            bitmap.Freeze();
        }

        return bitmap;
    }
}
