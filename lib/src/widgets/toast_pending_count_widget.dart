import 'package:flutter_sliding_toast/src/models/toast_style.dart';
import 'package:material_ui/material_ui.dart';

/// A badge on the toast's corner telling how many toasts
/// are waiting behind it, hidden when none are.
class const ToastPendingCountWidget({
  super.key,

  /// Notifies when [count] may have changed
  required final Listenable listenable,

  /// The number of toasts waiting behind the toast
  required final int Function() count,
  required final ToastStyle toastStyle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color =
        toastStyle.pendingCountColor ??
        toastStyle.progressBarColor ??
        theme.primaryColor;
    // Contrasting the badge, since its color may be anything (e.g. white)
    final Color textColor =
        toastStyle.pendingCountTextColor ??
        switch (ThemeData.estimateBrightnessForColor(color)) {
          .dark => Colors.white,
          .light => Colors.black87,
        };

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final count = this.count();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: count == 0
              ? const SizedBox.shrink()
              : Container(
                  // Keyed by the count so that every change pops the badge
                  key: ValueKey(count),
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const .symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const .all(.circular(11)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 3),
                    ],
                  ),
                  child: Text(
                    '+$count',
                    textAlign: .center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: .bold,
                      height: 1,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
