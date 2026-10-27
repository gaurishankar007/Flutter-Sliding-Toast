import 'package:flutter/widgets.dart';

/// Where a toast sits in its [ToastStack].
typedef ToastStackLayout = ({
  /// Vertical shift away from the stack's anchor
  double dy,
  double scale,

  /// The size the toast is squeezed into, the front toast's size
  /// for the toasts peeking behind it
  Size? size,
  bool isVisible,

  /// Whether tapping the toast spreads the stack out
  /// instead of tapping the toast itself
  bool expandsOnTap,
});

/// The toasts shown in `ToastDisplayMode.stacked` at one alignment of an
/// overlay, the oldest in front and the newer ones peeking out behind it,
/// coming forward one by one as the toasts in front close.
class ToastStack(
  final OverlayState overlayState,

  /// Whether the toasts behind peek out above the front one,
  /// true for toasts aligned to the bottom
  final bool peeksUp,
) extends ChangeNotifier {
  /// How many toasts are visible while the stack is collapsed,
  /// the front one included
  static const visibleCount = 3;
  static const peekOffset = 14.0;
  static const scaleStep = .05;

  /// Space between the toasts while the stack is spread out
  static const expandedGap = 8.0;

  /// Toast ids, oldest (the front one) first
  final _ids = <String>[];
  final _entries = <String, OverlayEntry>{};
  final _sizes = <String, Size>{};
  bool _isExpanded = false;

  /// Collapses the spread out stack when tapped outside of it
  OverlayEntry? _barrier;

  bool get isEmpty => _ids.isEmpty;
  bool get isExpanded => _isExpanded;

  /// The entry of the toast at the back, which a new toast is inserted
  /// below so that it shows up behind the toasts already in the stack.
  OverlayEntry? get backEntry => _ids.isEmpty ? null : _entries[_ids.last];

  void add(String id, OverlayEntry entry) {
    _ids.add(id);
    _entries[id] = entry;
    notifyListeners();
  }

  void remove(String id) {
    if (!_ids.remove(id)) {
      return;
    }
    _entries.remove(id);
    _sizes.remove(id);
    if (_ids.length < 2) {
      _removeBarrier();
    }
    notifyListeners();
  }

  /// Records the toast's own size, used to size the toasts behind it
  /// and to lay the stack out when it's spread out.
  void setSize(String id, Size size) {
    if (!_ids.contains(id) || _sizes[id] == size) {
      return;
    }
    _sizes[id] = size;
    notifyListeners();
  }

  /// How many toasts are in front of the toast, 0 for the front one.
  int depthOf(String id) => _ids.indexOf(id);

  /// How many toasts are behind the toast, counted only for the front toast
  /// of a collapsed stack since the spread out stack shows them all.
  int countBehind(String id) => isActive(id) ? _ids.length - 1 : 0;

  /// Whether the toast's timer may run, which is only the front toast's
  /// while the stack is collapsed.
  bool isActive(String id) => !_isExpanded && depthOf(id) == 0;

  /// Spreads the toasts out one below another, pausing them all.
  void expand() {
    if (_isExpanded || _ids.length < 2) {
      return;
    }
    _isExpanded = true;
    _barrier = OverlayEntry(
      builder: (_) => GestureDetector(behavior: .opaque, onTap: collapse),
    );
    overlayState.insert(_barrier!, below: backEntry);
    notifyListeners();
  }

  void collapse() {
    if (!_isExpanded) {
      return;
    }
    _removeBarrier();
    notifyListeners();
  }

  void _removeBarrier() {
    _isExpanded = false;
    final barrier = _barrier;
    _barrier = null;
    if (barrier == null) {
      return;
    }
    // Removed even before its first build, since it's in the overlay already
    barrier
      ..remove()
      ..dispose();
  }

  ToastStackLayout layoutOf(String id) {
    final double direction = peeksUp ? -1 : 1;

    if (_isExpanded) {
      // Making room for every older toast in front of this one
      double dy = 0;
      for (final olderId in _ids.take(_ids.indexOf(id))) {
        dy += (_sizes[olderId]?.height ?? 0) + expandedGap;
      }
      return (
        dy: direction * dy,
        scale: 1,
        size: null,
        isVisible: true,
        expandsOnTap: false,
      );
    }

    final depth = depthOf(id);
    final shownDepth = depth.clamp(0, visibleCount - 1);
    return (
      dy: direction * shownDepth * peekOffset,
      scale: 1 - shownDepth * scaleStep,
      size: depth == 0 ? null : _sizes[_ids.first],
      isVisible: depth < visibleCount,
      expandsOnTap: depth > 0,
    );
  }
}
