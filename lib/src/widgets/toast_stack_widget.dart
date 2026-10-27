import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_sliding_toast/src/core/toast_stack.dart';

const _duration = Duration(milliseconds: 300);
const _curve = Curves.easeOutCubic;

/// Moves the positioned toast away from its stack's anchor, peeking it out
/// behind the older toasts or laying it out below them when spread out.
///
/// The toast is moved by padding around its position rather than by
/// a transform, so that taps on the part peeking out still reach it.
class const ToastStackOffsetWidget({
  super.key,
  required final ToastStack stack,
  required final String toastId,

  /// The toast wrapped in its position widget
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stack,
      child: child,
      builder: (context, child) {
        final double dy = stack.layoutOf(toastId).dy.abs();
        return AnimatedPadding(
          duration: _duration,
          curve: _curve,
          padding: stack.peeksUp ? .only(bottom: dy) : .only(top: dy),
          child: child,
        );
      },
    );
  }
}

/// Scales and squeezes the toast in its [ToastStack] into the front toast's
/// size while it peeks out behind it, or hides it if it's too far behind.
class const ToastStackCardWidget({
  super.key,
  required final ToastStack stack,
  required final String toastId,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stack,
      child: _SizeReporter(
        onSize: (size) => stack.setSize(toastId, size),
        child: child,
      ),
      builder: (context, child) {
        final layout = stack.layoutOf(toastId);
        final size = layout.size;

        return IgnorePointer(
          ignoring: !layout.isVisible,
          child: AnimatedOpacity(
            opacity: layout.isVisible ? 1 : 0,
            duration: _duration,
            child: AnimatedScale(
              scale: layout.scale,
              duration: _duration,
              curve: _curve,
              alignment: stack.peeksUp ? .bottomCenter : .topCenter,
              child: GestureDetector(
                behavior: layout.expandsOnTap ? .opaque : .deferToChild,
                onTap: layout.expandsOnTap ? stack.expand : null,
                child: IgnorePointer(
                  ignoring: layout.expandsOnTap,
                  // The widget tree stays the same whether the toast is
                  // squeezed or not, so that its state is kept
                  child: LayoutBuilder(
                    builder: (context, constraints) => SizedBox(
                      width: size?.width,
                      height: size?.height,
                      child: ClipRect(
                        clipBehavior: size == null ? .none : .hardEdge,
                        child: OverflowBox(
                          fit: .deferToChild,
                          alignment: stack.peeksUp ? .topCenter : .bottomCenter,
                          minWidth: size?.width ?? constraints.minWidth,
                          maxWidth: size?.width ?? constraints.maxWidth,
                          minHeight: constraints.minHeight,
                          maxHeight: constraints.maxHeight,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reports its child's size after every layout that changes it.
class const _SizeReporter({
  required final ValueChanged<Size> onSize,
  required Widget super.child,
}) extends SingleChildRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter(var ValueChanged<Size> onSize)
    extends RenderProxyBox {
  Size? _reportedSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reportedSize) {
      return;
    }
    _reportedSize = size;
    // Reporting after the frame, since the stack can't rebuild mid-layout
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(size));
  }
}
