using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using WinPaste.App.Models;
using WinPaste.App.Services;
using WinPaste.App.ViewModels;

namespace WinPaste.App;

public partial class MainWindow : Window, INotifyPropertyChanged
{
    private readonly ClipboardHistoryStore _store;
    private readonly Action<ClipItem> _selectClip;
    private string _countLabel = "0 clipów";

    public MainWindow(ClipboardHistoryStore store, Action<ClipItem> selectClip)
    {
        _store = store;
        _selectClip = selectClip;

        InitializeComponent();
        DataContext = this;

        _store.Changed += (_, _) => Dispatcher.Invoke(RefreshItems);
        RefreshItems();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public ObservableCollection<ClipCardViewModel> Clips { get; } = [];

    public string CountLabel
    {
        get => _countLabel;
        private set
        {
            if (_countLabel == value)
            {
                return;
            }

            _countLabel = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CountLabel)));
        }
    }

    public void ShowPicker()
    {
        RefreshItems();
        PositionNearTaskbar();
        Show();
        Activate();
        ClipList.Focus();

        if (Clips.Count > 0)
        {
            ClipList.SelectedIndex = 0;
            ClipList.ScrollIntoView(ClipList.SelectedItem);
        }
    }

    private void RefreshItems()
    {
        Clips.Clear();

        foreach (var item in _store.Items.Take(100))
        {
            Clips.Add(new ClipCardViewModel(item, _store));
        }

        CountLabel = $"{Clips.Count} {PluralizeClips(Clips.Count)}";
        EmptyState.Visibility = Clips.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        ClipList.Visibility = Clips.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
    }

    private void SelectCurrent()
    {
        if (ClipList.SelectedItem is ClipCardViewModel viewModel)
        {
            _selectClip(viewModel.Item);
        }
    }

    private void PositionNearTaskbar()
    {
        var workArea = SystemParameters.WorkArea;
        Width = workArea.Width;
        Height = 300;
        Left = workArea.Left;
        Top = Math.Max(workArea.Top + 24, workArea.Bottom - Height - 24);
    }

    private void Window_OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            Hide();
            e.Handled = true;
            return;
        }

        if (e.Key == Key.Enter)
        {
            SelectCurrent();
            e.Handled = true;
        }
    }

    private void Window_OnDeactivated(object sender, EventArgs e)
    {
        Hide();
    }

    private void ClipList_OnMouseDoubleClick(object sender, MouseButtonEventArgs e)
    {
        SelectCurrent();
    }

    private void ClipList_OnPreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
    {
        var item = FindAncestor<System.Windows.Controls.ListBoxItem>(e.OriginalSource as DependencyObject);
        if (item?.DataContext is ClipCardViewModel viewModel)
        {
            ClipList.SelectedItem = viewModel;
            _selectClip(viewModel.Item);
            e.Handled = true;
        }
    }

    private static T? FindAncestor<T>(DependencyObject? current)
        where T : DependencyObject
    {
        while (current is not null)
        {
            if (current is T result)
            {
                return result;
            }

            current = VisualTreeHelper.GetParent(current);
        }

        return null;
    }

    private static string PluralizeClips(int count)
    {
        if (count == 1)
        {
            return "clip";
        }

        var lastTwo = count % 100;
        var last = count % 10;

        if (lastTwo is >= 12 and <= 14)
        {
            return "clipów";
        }

        return last is >= 2 and <= 4 ? "clipy" : "clipów";
    }
}
