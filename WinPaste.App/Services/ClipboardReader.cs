using System.Runtime.InteropServices;
using System.Windows;
using WinPaste.App.Models;
using WpfClipboard = System.Windows.Clipboard;
using WpfTextDataFormat = System.Windows.TextDataFormat;

namespace WinPaste.App.Services;

public static class ClipboardReader
{
    public static ClipboardSnapshot? TryRead()
    {
        for (var attempt = 0; attempt < 6; attempt++)
        {
            try
            {
                if (WpfClipboard.ContainsImage())
                {
                    var image = WpfClipboard.GetImage();
                    if (image is not null)
                    {
                        if (image.CanFreeze)
                        {
                            image.Freeze();
                        }

                        return new ClipboardSnapshot(ClipKind.Image, null, image);
                    }
                }

                if (WpfClipboard.ContainsText(WpfTextDataFormat.UnicodeText))
                {
                    var text = WpfClipboard.GetText(WpfTextDataFormat.UnicodeText);
                    if (!string.IsNullOrEmpty(text))
                    {
                        return new ClipboardSnapshot(ClipKind.Text, text, null);
                    }
                }

                return null;
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

        return null;
    }
}
