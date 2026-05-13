using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.IO;
using System.Windows.Media.Imaging;
using WinPaste.App.Models;

namespace WinPaste.App.Services;

public sealed class ClipboardHistoryStore
{
    private const int DefaultMaxItems = 100;

    private readonly string _historyFile;
    private readonly string _imagesDirectory;
    private readonly JsonSerializerOptions _jsonOptions = new() { WriteIndented = true };
    private readonly List<ClipItem> _items = [];

    public ClipboardHistoryStore()
    {
        RootDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WinPaste");

        _historyFile = Path.Combine(RootDirectory, "history.json");
        _imagesDirectory = Path.Combine(RootDirectory, "images");
    }

    public event EventHandler? Changed;

    public string RootDirectory { get; }

    public int MaxItems { get; init; } = DefaultMaxItems;

    public IReadOnlyList<ClipItem> Items => _items;

    public void Load()
    {
        Directory.CreateDirectory(RootDirectory);
        Directory.CreateDirectory(_imagesDirectory);

        if (!File.Exists(_historyFile))
        {
            return;
        }

        try
        {
            var json = File.ReadAllText(_historyFile);
            var items = JsonSerializer.Deserialize<List<ClipItem>>(json, _jsonOptions) ?? [];

            _items.Clear();
            _items.AddRange(items
                .Where(IsUsable)
                .OrderByDescending(item => item.CreatedAt)
                .Take(MaxItems));
        }
        catch (JsonException)
        {
            _items.Clear();
        }
        catch (IOException)
        {
            _items.Clear();
        }
    }

    public ClipItem? AddText(string text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return null;
        }

        var bytes = Encoding.UTF8.GetBytes(text);
        var hash = ComputeHash(bytes);
        var existing = FindDuplicate(ClipKind.Text, hash);

        if (existing is not null)
        {
            if (ReferenceEquals(existing, _items.FirstOrDefault()))
            {
                return existing;
            }

            Promote(existing);
            return existing;
        }

        var item = new ClipItem
        {
            Kind = ClipKind.Text,
            Text = text,
            ContentHash = hash
        };

        AddNew(item);
        return item;
    }

    public ClipItem? AddImage(BitmapSource image)
    {
        var pngBytes = EncodePng(image);
        var hash = ComputeHash(pngBytes);
        var existing = FindDuplicate(ClipKind.Image, hash);

        if (existing is not null)
        {
            if (ReferenceEquals(existing, _items.FirstOrDefault()))
            {
                return existing;
            }

            Promote(existing);
            return existing;
        }

        var fileName = $"{Guid.NewGuid():N}.png";
        File.WriteAllBytes(Path.Combine(_imagesDirectory, fileName), pngBytes);

        var item = new ClipItem
        {
            Kind = ClipKind.Image,
            ImageFileName = fileName,
            ContentHash = hash
        };

        AddNew(item);
        return item;
    }

    public string? GetImagePath(ClipItem item)
    {
        return string.IsNullOrWhiteSpace(item.ImageFileName)
            ? null
            : Path.Combine(_imagesDirectory, item.ImageFileName);
    }

    private bool IsUsable(ClipItem item)
    {
        if (item.Kind == ClipKind.Text)
        {
            return !string.IsNullOrEmpty(item.Text);
        }

        var imagePath = GetImagePath(item);
        return imagePath is not null && File.Exists(imagePath);
    }

    private ClipItem? FindDuplicate(ClipKind kind, string hash)
    {
        return _items.FirstOrDefault(item => item.Kind == kind && item.ContentHash == hash);
    }

    private void Promote(ClipItem item)
    {
        _items.Remove(item);
        item.CreatedAt = DateTimeOffset.Now;
        _items.Insert(0, item);
        Save();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    private void AddNew(ClipItem item)
    {
        item.CreatedAt = DateTimeOffset.Now;
        _items.Insert(0, item);
        Trim();
        Save();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    private void Trim()
    {
        while (_items.Count > MaxItems)
        {
            var removed = _items[^1];
            _items.RemoveAt(_items.Count - 1);

            if (removed.Kind == ClipKind.Image && removed.ImageFileName is not null)
            {
                DeleteImageIfUnreferenced(removed.ImageFileName);
            }
        }
    }

    private void DeleteImageIfUnreferenced(string fileName)
    {
        if (_items.Any(item => item.ImageFileName == fileName))
        {
            return;
        }

        var path = Path.Combine(_imagesDirectory, fileName);
        try
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
        catch (IOException)
        {
        }
        catch (UnauthorizedAccessException)
        {
        }
    }

    private void Save()
    {
        Directory.CreateDirectory(RootDirectory);
        Directory.CreateDirectory(_imagesDirectory);

        var tempFile = $"{_historyFile}.tmp";
        var json = JsonSerializer.Serialize(_items, _jsonOptions);
        File.WriteAllText(tempFile, json);
        File.Move(tempFile, _historyFile, overwrite: true);
    }

    private static string ComputeHash(byte[] bytes)
    {
        return Convert.ToHexString(SHA256.HashData(bytes));
    }

    private static byte[] EncodePng(BitmapSource image)
    {
        var encoder = new PngBitmapEncoder();
        encoder.Frames.Add(BitmapFrame.Create(image));

        using var stream = new MemoryStream();
        encoder.Save(stream);
        return stream.ToArray();
    }
}
