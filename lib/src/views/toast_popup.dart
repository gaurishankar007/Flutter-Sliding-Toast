import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:flutter_sliding_toast/src/core/toast_stack.dart';
import 'package:flutter_sliding_toast/src/views/toast_dialog.dart';
import 'package:flutter_sliding_toast/src/widgets/toast_container_widget.dart';
import 'package:flutter_sliding_toast/src/widgets/toast_pending_count_widget.dart';
import 'package:flutter_sliding_toast/src/widgets/toast_position_widget.dart';
import 'package:flutter_sliding_toast/src/widgets/toast_stack_widget.dart';

/// A sliding message to show the toast
class const ToastPopup({
  super.key,

  /// The toast controller for removing the overlay
  required final ToastController toastController,

  /// The widget to display at the start of the message
  required final Widget? leading,

  /// The Message to be displayed at the toast
  /// It's width is expanded whenever leading or trailing widget is present
  required final Widget title,

  /// A widget displayed at the right side of the toast
  required final Widget? trailing,

  /// The setting for the sliding animation
  required final PopupToastSetting toastSetting,

  /// The style of the toast
  required final ToastStyle toastStyle,

  /// The message displayed in the dialog shown on tap instead of [title]
  final Widget? dialogTitle,

  /// Function to be called when the toast is clicked
  final void Function()? onTapped,

  /// The number of toasts waiting behind this one,
  /// given only when it's shown one by one
  final ValueListenable<int>? pendingCount,

  /// The stack the toast is shown in, given only when it's stacked
  final ToastStack? stack,
}) extends StatefulWidget {
  @override
  State<ToastPopup> createState() => _ToastPopupState();
}

class _ToastPopupState extends State<ToastPopup> with TickerProviderStateMixin {
  late final PopupToastSetting toastSetting;
  late final ToastStyle toastStyle;
  late final AnimationController fadeController;
  late final AnimationController scaleController;
  late final AnimationController timeController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;

  /// If at least one animation is allowed to show
  bool showAnimation = true;

  /// Is the toast clicked by the user
  bool isToastTapped = false;

  /// Whether the toast may count down, false while it's behind
  /// another toast in its stack or the stack is spread out
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    toastSetting = widget.toastSetting;
    toastStyle = widget.toastStyle;
    showAnimation = toastSetting.showFading || toastSetting.showScaling;

    /// For sliding effect
    fadeController = AnimationController(
      vsync: this,
      duration: toastSetting.animationDuration,
    );

    /// For displaying the toast and also for progress bar
    scaleController = AnimationController(
      vsync: this,
      duration: toastSetting.animationDuration,
    );

    /// For tracking the animation and display duration
    Duration duration = toastSetting.displayDuration;
    if (showAnimation) {
      duration += toastSetting.animationDuration;
    }
    timeController = AnimationController(vsync: this, duration: duration);

    // Create a curved tween animation for the slide
    fadeAnimation = Tween<double>(begin: .1, end: 1).animate(
      CurvedAnimation(parent: fadeController, curve: toastSetting.fadingCurve),
    );

    // Create a size animation for the progress bar
    scaleAnimation = Tween<double>(begin: .5, end: 1).animate(
      CurvedAnimation(
        parent: scaleController,
        curve: toastSetting.scalingCurve,
      ),
    );

    // Start the animation
    fadeController.forward();

    // Start the size animation
    scaleController.forward();

    // Start the time controller, unless the toast is behind another one,
    // and listen animation is completed or not to remove the overlay
    widget.stack?.addListener(onStackChanged);
    isActive = widget.stack?.isActive(widget.toastController.id) ?? true;
    timeController.addStatusListener(animationListener);
    if (isActive) {
      timeController.forward();
    }
  }

  Future<void> animationListener(AnimationStatus status) async {
    if (status == .completed) {
      // Wait for the reverse animation to complete
      if (showAnimation && toastSetting.showReverseAnimation) {
        await fadeController.reverse();
        await scaleController.reverse();
      }

      // Remove the overlay entry
      widget.toastController.closeToast();
    }
  }

  /// Pauses the toast while it's behind another one in the stack
  /// or the stack is spread out, resuming it once it's back in front.
  void onStackChanged() {
    final isActive = widget.stack!.isActive(widget.toastController.id);
    if (isActive == this.isActive) {
      return;
    }
    this.isActive = isActive;
    if (isActive) {
      timeController.forward();
    } else {
      timeController.stop();
    }
  }

  /// Shows the whole toast content in a dialog,
  /// pausing the toast until the dialog is closed.
  Future<void> showDialog() async {
    timeController.stop();
    await showToastDialog(
      context,
      leading: widget.leading,
      title: widget.dialogTitle ?? widget.title,
      trailing: widget.trailing,
      toastStyle: toastStyle,
      dialogSetting: toastSetting.dialogSetting,
      toastMaxWidth: toastSetting.maxWidth,
    );
    if (mounted && isActive) {
      timeController.forward();
    }
  }

  @override
  void dispose() {
    widget.stack?.removeListener(onStackChanged);
    fadeController.dispose();
    scaleController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create the toast container
    Widget child = ToastContainerWidget(
      leading: widget.leading,
      title: widget.title,
      trailing: widget.trailing,
      toastStyle: toastStyle,
      expandTitleWidth: toastStyle.expandedTitle,
    );

    // Show the clipping with border radius
    child = ClipRRect(borderRadius: toastStyle.borderRadius, child: child);

    // Show the box shadow if available
    if (toastStyle.boxShadow != null) {
      child = Container(
        decoration: BoxDecoration(boxShadow: toastStyle.boxShadow),
        child: child,
      );
    }

    // Show the number of toasts waiting in the queue or stack behind this one
    final pendingCount = widget.pendingCount;
    final stack = widget.stack;
    final toastId = widget.toastController.id;
    final (Listenable, int Function())? countSource = switch ((
      pendingCount,
      stack,
    )) {
      (final pendingCount?, _) => (pendingCount, () => pendingCount.value),
      (_, final stack?) => (stack, () => stack.countBehind(toastId)),
      _ => null,
    };
    if (countSource != null && toastSetting.showPendingCount) {
      child = Stack(
        clipBehavior: .none,
        children: [
          child,
          Positioned(
            top: -8,
            right: -8,
            child: ToastPendingCountWidget(
              listenable: countSource.$1,
              count: countSource.$2,
              toastStyle: toastStyle,
            ),
          ),
        ],
      );
    }

    if (toastSetting.showFading) {
      child = FadeTransition(opacity: fadeAnimation, child: child);
    }

    if (toastSetting.showScaling) {
      child = ScaleTransition(scale: scaleAnimation, child: child);
    }

    child = Dismissible(
      key: UniqueKey(),
      // A stacked toast is removed right away, the stack moving up itself
      resizeDuration: widget.stack == null
          ? const Duration(milliseconds: 300)
          : null,
      // Stop animations and remove the overlay on dismissed
      onDismissed: (_) {
        if (showAnimation) {
          timeController.stop();
        }
        widget.toastController.closeToast();
      },
      child: GestureDetector(
        // Execute onTapped function on tap
        onTap: () {
          if (isToastTapped) {
            return;
          }
          if (toastSetting.disableMultiTapping) {
            isToastTapped = true;
          }
          widget.onTapped?.call();
          if (toastSetting.showDialogOnTap) {
            showDialog();
          }
        },
        // Pause the animation on long press
        onLongPress: () => timeController.stop(),
        // Forward the animation when long press ends
        onLongPressEnd: (details) {
          if (isActive) {
            timeController.forward();
          }
        },
        child: child,
      ),
    );

    // Place the toast in its stack
    if (stack != null) {
      child = ToastStackCardWidget(
        stack: stack,
        toastId: toastId,
        child: child,
      );
    }

    child = ToastPositionWidget(
      alignment: toastSetting.toastAlignment,
      padding: toastSetting.padding,
      newMaxHeight: toastSetting.maxHeight,
      newMaxWidth: toastSetting.maxWidth,
      child: child,
    );

    if (stack != null) {
      child = ToastStackOffsetWidget(
        stack: stack,
        toastId: toastId,
        child: child,
      );
    }

    return child;
  }
}
