/// How toasts behave when a new one is shown while others are on screen.
enum ToastDisplayMode {
  /// Every toast is shown right away, stacking on the ones already on screen.
  allAtOnce,

  /// Toasts are shown one at a time, the next one waiting in a queue
  /// until the one on screen is closed.
  oneByOne,

  /// Every toast is shown right away like notifications, the first one in
  /// front and the later ones at the same alignment peeking out behind it.
  /// Only the toast in front counts down, the next one coming forward when
  /// it closes, and tapping the toasts behind it spreads the stack out,
  /// pausing every toast until it's collapsed.
  stacked,
}
