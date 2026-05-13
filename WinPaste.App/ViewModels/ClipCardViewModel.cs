using System.IO;
using WinPaste.App.Models;
using WinPaste.App.Services;

namespace WinPaste.App.ViewModels;

public sealed class ClipCardViewModel
{
    private readonly ClipboardHistoryStore _store;

    public ClipCardViewModel(ClipItem item, ClipboardHistoryStore store)
    {
        Item = item;
        _store = store;
    }

    public ClipItem Item { get; }

    public bool IsImage => Item.Kind == ClipKind.Image;

    public string DisplayText => Item.Kind == ClipKind.Text
        ? NormalizePreview(Item.Text)
        : "Obraz ze schowka";

    public string KindLabel => Item.Kind == ClipKind.Image ? "Obraz" : "Tekst";

    public string TimeLabel => Item.CreatedAt.LocalDateTime.ToString("HH:mm");

    public Uri? ImageUri
    {
        get
        {
            var path = _store.GetImagePath(Item);
            return path is not null && File.Exists(path) ? new Uri(path, UriKind.Absolute) : null;
        }
    }

    private static string NormalizePreview(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return string.Empty;
        }

        var preview = string.Join(' ', text.Split(default(string[]), StringSplitOptions.RemoveEmptyEntries));
        return preview.Length <= 260 ? preview : $"{preview[..260]}...";
    }
}
