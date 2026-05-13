using System.Text.Json.Serialization;

namespace WinPaste.App.Models;

public sealed class ClipItem
{
    public string Id { get; init; } = Guid.NewGuid().ToString("N");

    public ClipKind Kind { get; init; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.Now;

    public string? Text { get; init; }

    public string? ImageFileName { get; init; }

    public string ContentHash { get; init; } = string.Empty;

    [JsonIgnore]
    public bool IsText => Kind == ClipKind.Text;

    [JsonIgnore]
    public bool IsImage => Kind == ClipKind.Image;
}
