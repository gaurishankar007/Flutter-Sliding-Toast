import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:flutter_sliding_toast/src/core/toast_stack.dart';
import 'package:flutter_sliding_toast/src/widgets/toast_stack_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late BuildContext capturedContext;

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  ToastController slide(String text) => InteractiveToast.slide(
    context: capturedContext,
    title: Text(text),
    displayMode: .stacked,
    toastSetting: const SlidingToastSetting(showProgressBar: false),
  );

  /// The part of the toast that taps reach, moved with the stack.
  Rect toastRect(WidgetTester tester, String text) => tester.getRect(
    find
        .descendant(
          of: find.ancestor(
            of: find.text(text),
            matching: find.byType(ToastStackCardWidget),
          ),
          matching: find.byType(GestureDetector),
        )
        .first,
  );

  // Slide in (1s) and display (1s), then slide out (1s), pumping in steps
  // since every animation starts its clock on the frame after it's started.
  Future<void> waitForTimeout(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  tearDown(InteractiveToast.closeAllToast);

  testWidgets('shows every toast right away', (tester) async {
    await pumpApp(tester);

    slide('one');
    slide('two');
    await tester.pump();

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('only the toast in front counts down', (tester) async {
    await pumpApp(tester);

    slide('one');
    slide('two');
    await tester.pump();

    await waitForTimeout(tester);
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);

    await waitForTimeout(tester);
    expect(find.text('two'), findsNothing);
  });

  testWidgets('later toasts peek out behind the first one', (tester) async {
    await pumpApp(tester);

    slide('one');
    slide('two');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final front = toastRect(tester, 'one');
    final behind = toastRect(tester, 'two');
    expect(behind.top, lessThan(front.top));
    expect(behind.width, lessThan(front.width));
  });

  testWidgets('draws the first toast over the later ones', (tester) async {
    await pumpApp(tester);

    String? tapped;
    for (final text in ['one', 'two']) {
      InteractiveToast.slide(
        context: capturedContext,
        title: Text(text),
        displayMode: .stacked,
        onTapped: () => tapped = text,
      );
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tapAt(toastRect(tester, 'one').center);
    expect(tapped, 'one');
  });

  testWidgets('tapping a toast behind spreads the stack out and pauses it', (
    tester,
  ) async {
    await pumpApp(tester);

    slide('one');
    slide('two');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tapAt(toastRect(tester, 'two').topCenter + const Offset(0, 3));
    // The stack starts moving on the next frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      toastRect(tester, 'two').bottom,
      lessThan(toastRect(tester, 'one').top),
    );

    // Paused while spread out
    await waitForTimeout(tester);
    expect(find.text('one'), findsOneWidget);

    // Tapping outside collapses the stack, resuming the front toast
    await tester.tapAt(const Offset(10, 10));
    await waitForTimeout(tester);
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('counts the toasts behind on the front toast only', (
    tester,
  ) async {
    await pumpApp(tester);

    slide('one');
    slide('two');
    slide('three');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('+2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('one'),
          matching: find.byType(ToastStackCardWidget),
        ),
        matching: find.text('+2'),
      ),
      findsOneWidget,
    );

    // Spread out, every toast is in sight
    await tester.tapAt(toastRect(tester, 'two').topCenter + const Offset(0, 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('pauses popup toasts behind the front one too', (tester) async {
    await pumpApp(tester);

    for (final text in ['one', 'two']) {
      InteractiveToast.pop(
        context: capturedContext,
        title: Text(text),
        displayMode: .stacked,
      );
    }
    await tester.pump();

    await waitForTimeout(tester);
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('keeps toasts at different alignments in their own stacks', (
    tester,
  ) async {
    await pumpApp(tester);

    slide('bottom');
    InteractiveToast.slide(
      context: capturedContext,
      title: const Text('top'),
      displayMode: .stacked,
      toastSetting: const SlidingToastSetting(
        showProgressBar: false,
        toastStartPosition: .top,
        toastAlignment: .topCenter,
      ),
    );
    await tester.pump();

    // Both are in front of their own stacks, so both count down.
    await waitForTimeout(tester);
    expect(find.text('bottom'), findsNothing);
    expect(find.text('top'), findsNothing);
  });

  group('ToastStack', () {
    late ToastStack stack;

    Future<void> setUpStack(WidgetTester tester) async {
      await pumpApp(tester);
      stack = ToastStack(
        tester.state<OverlayState>(find.byType(Overlay)),
        true,
      );
      for (final (id, height) in [('a', 40.0), ('b', 60.0), ('c', 50.0)]) {
        final entry = OverlayEntry(builder: (_) => const SizedBox());
        addTearDown(
          () => entry
            ..remove()
            ..dispose(),
        );
        stack.overlayState.insert(entry);
        stack
          ..add(id, entry)
          ..setSize(id, Size(200, height));
      }
    }

    testWidgets('counts the toasts behind the front one', (tester) async {
      await setUpStack(tester);

      expect(stack.countBehind('a'), 2);
      expect(stack.countBehind('c'), 0);

      stack.expand();
      expect(stack.countBehind('a'), 0);
      stack.collapse();
    });

    testWidgets('peeks the toasts behind upward at the front size', (
      tester,
    ) async {
      await setUpStack(tester);

      expect(stack.depthOf('a'), 0);
      expect(stack.isActive('a'), isTrue);
      expect(stack.isActive('c'), isFalse);

      final behind = stack.layoutOf('c');
      expect(behind.dy, -2 * ToastStack.peekOffset);
      expect(behind.scale, 1 - 2 * ToastStack.scaleStep);
      expect(behind.size, const Size(200, 40));
      expect(behind.expandsOnTap, isTrue);
      expect(stack.layoutOf('a').size, isNull);
    });

    testWidgets('hides the toasts beyond the visible count', (tester) async {
      await setUpStack(tester);
      stack.add('d', OverlayEntry(builder: (_) => const SizedBox()));

      expect(stack.layoutOf('d').isVisible, isFalse);
      expect(stack.layoutOf('c').isVisible, isTrue);
    });

    testWidgets('lays every toast out below the older ones when expanded', (
      tester,
    ) async {
      await setUpStack(tester);
      stack.expand();
      await tester.pump();

      expect(stack.isActive('a'), isFalse);
      expect(stack.layoutOf('a').dy, 0);
      expect(stack.layoutOf('b').dy, -(40 + ToastStack.expandedGap));
      expect(stack.layoutOf('c').dy, -(40 + 60 + 2 * ToastStack.expandedGap));

      // Down to a single toast, there is nothing to spread out
      stack
        ..remove('b')
        ..remove('c');
      expect(stack.isExpanded, isFalse);
    });
  });
}
