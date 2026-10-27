import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

class const MyApp({super.key}) extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool colorChanged = false;
  Color color = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sliding Toast Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: color),
        appBarTheme: AppBarTheme(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(changeColor: changeColor),
    );
  }

  void changeColor() => setState(() {
    colorChanged ? color = Colors.deepPurple : color = Colors.green;
    colorChanged = !colorChanged;
  });
}

class const MyHomePage({super.key, required final VoidCallback changeColor})
    extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ToastDisplayMode displayMode = InteractiveToast.displayMode;

  @override
  void initState() {
    super.initState();

    /// Setup overlay state when the UI build is finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InteractiveToast.initializeOverlayState(Overlay.of(context));
      // Or setup context
      // InteractiveToast.setupContext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Sliding & Popup Toast'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const .symmetric(horizontal: 15, vertical: 20),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const SizedBox(width: double.maxFinite),
              SegmentedButton<ToastDisplayMode>(
                segments: const [
                  ButtonSegment(value: .allAtOnce, label: Text('All at once')),
                  ButtonSegment(value: .oneByOne, label: Text('One by one')),
                  ButtonSegment(value: .stacked, label: Text('Stacked')),
                ],
                selected: {displayMode},
                onSelectionChanged: (selection) {
                  setState(() => displayMode = selection.single);
                  InteractiveToast.setDisplayMode(displayMode);
                },
              ),
              const SizedBox(height: 10),
              Text(switch (displayMode) {
                .allAtOnce => 'Every toast shows right away.',
                .oneByOne => 'Toasts wait in a queue, the badge counting the waiting ones.',
                .stacked =>
                  'Later toasts peek out behind the first one. '
                      'Tap them to spread the stack out.',
              }, textAlign: .center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showFiveToasts,
                child: _textWidget('Show five toasts'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showSlidingToasts,
                child: _textWidget('Sliding toasts'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showStatusToasts,
                child: _textWidget('Status toasts'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showPopupToasts,
                child: _textWidget('Popup toasts'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: InteractiveToast.closeAllToast,
                child: _textWidget('Close all toasts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the [toasts] one after another, a moment apart.
  Future<void> _showInTurn(List<VoidCallback> toasts) async {
    for (final showToast in toasts) {
      if (!mounted) {
        return;
      }
      showToast();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  /// A simple toast at the bottom center, a glassy one at the top center,
  /// and one decorated with an image at the center left.
  Future<void> _showSlidingToasts() => _showInTurn([
    () => InteractiveToast.slide(
      context: context,
      leading: _leadingWidget(),
      title: const Text(
        "Hi there! I'm a simple toast 😎."
        ' Dismiss me by sliding downward.',
      ),
      trailing: _trailingWidget(),
      toastStyle: const ToastStyle(titleLeadingGap: 10),
      toastSetting: const SlidingToastSetting(
        displayDuration: Duration(seconds: 2),
      ),
    ),
    () => InteractiveToast.slide(
      title: const Text(
        "Hi there! I'm a glassy toast 🦄. "
        'Dismiss me by sliding upward.',
      ),
      trailing: _trailingWidget(),
      toastSetting: const SlidingToastSetting(
        displayDuration: Duration(seconds: 2),
        toastStartPosition: .top,
        toastAlignment: .topCenter,
        progressBarHeight: 4,
      ),
      toastStyle: const ToastStyle(glassBlur: 4, backgroundColorOpacity: .3),
    ),
    () => InteractiveToast.slide(
      title: const Text(
        "I'm a bit more modified toast 🐷 with only title widget, "
        'without progressBar and reverse animation.',
        textAlign: .center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      toastSetting: const SlidingToastSetting(
        maxHeight: 140,
        animationDuration: Duration(seconds: 2),
        displayDuration: Duration(seconds: 3),
        showReverseAnimation: false,
        showProgressBar: false,
        toastStartPosition: .left,
        toastAlignment: .center,
      ),
      toastStyle: ToastStyle(
        image: const DecorationImage(
          image: AssetImage('assets/image.jpg'),
          fit: .cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(51),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
    ),
  ]);

  /// A success toast at the top right, an error toast at the bottom left,
  /// and a long message at the bottom center that's read in full on tap.
  Future<void> _showStatusToasts() {
    final overlayState = Overlay.of(context);
    return _showInTurn([
      () => InteractiveToast.slide(
        title: const Text("Hi there! I'm a success toast 🦁"),
        toastSetting: const SlidingToastSetting(
          toastStartPosition: .right,
          toastAlignment: .topRight,
        ),
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
        toastStyle: _statusStyle(Colors.green),
      ),
      () => InteractiveToast.slide(
        overlayState: overlayState,
        title: const Text(
          "Hi there! I'm a error toast 😈. "
          'Dismiss me by sliding horizontally.',
        ),
        toastSetting: const SlidingToastSetting(
          toastStartPosition: .left,
          toastAlignment: .bottomLeft,
          displayDuration: Duration(seconds: 2),
        ),
        trailing: const Icon(Icons.warning_rounded, color: Colors.red),
        toastStyle: _statusStyle(Colors.red),
      ),
      _showLongMessageToast,
    ]);
  }

  /// A popup toast at the bottom center that changes the theme color on tap,
  /// one at the top right without animations, and a small gradient one
  /// at the center.
  Future<void> _showPopupToasts() => _showInTurn([
    () => InteractiveToast.pop(
      title: const Text(
        "Hi! I'm a popup toast with onTap callback 🐺. "
        'Tap me to change theme color.',
      ),
      trailing: _trailingWidget(),
      toastSetting: const PopupToastSetting(
        animationDuration: Duration(seconds: 1),
        displayDuration: Duration(seconds: 3),
      ),
      onTapped: widget.changeColor,
    ),
    () => InteractiveToast.pop(
      context: context,
      title: const Text(
        "Hello! I'm a popup toast 🤡 with no fading and scaling.",
      ),
      trailing: _trailingWidget(),
      toastSetting: const PopupToastSetting(
        showFading: false,
        showScaling: false,
        animationDuration: Duration(seconds: 1),
        displayDuration: Duration(seconds: 3),
        toastAlignment: .topRight,
      ),
    ),
    () => InteractiveToast.pop(
      title: const Text(
        'Title is not expanded.',
        style: TextStyle(color: Colors.white),
      ),
      toastSetting: const PopupToastSetting(
        showFading: false,
        showScaling: false,
        animationDuration: Duration(seconds: 2),
        displayDuration: Duration(seconds: 3),
        toastAlignment: .center,
      ),
      toastStyle: const ToastStyle(
        expandedTitle: false,
        gradient: LinearGradient(colors: [Colors.purple, Color(0xFF03589E)]),
      ),
    ),
  ]);

  /// A colored shadow and progress bar for the status toasts.
  ToastStyle _statusStyle(Color color) => ToastStyle(
    boxShadow: [
      BoxShadow(
        color: color.withAlpha(32),
        blurRadius: 5,
        spreadRadius: 3,
        offset: const Offset(2, 2),
      ),
    ],
    progressBarColor: color,
  );

  /// Shows five toasts at the same spot, shown all at once, one by one,
  /// or stacked depending on the display mode.
  Future<void> _showFiveToasts() async {
    const colors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.orange,
      Colors.green,
      Colors.red,
    ];
    for (var i = 0; i < colors.length; i++) {
      InteractiveToast.slide(
        title: Text(
          "I'm toast number ${i + 1} 🍞",
          style: const TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.notifications, color: Colors.white),
        toastSetting: const SlidingToastSetting(
          displayDuration: Duration(milliseconds: 1500),
          toastStartPosition: .top,
          toastAlignment: .topCenter,
        ),
        toastStyle: ToastStyle(
          backgroundColor: colors[i],
          progressBarColor: Colors.white,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Shows a toast with a long message cut short,
  /// tapping it shows the whole message in a dialog.
  void _showLongMessageToast() {
    const message =
        "Hi there! I'm a toast with a long message 📜. "
        'A toast only has room for a line or two, so the rest of this '
        'message is cut short. Tap me to read the whole message in a '
        'dialog styled just like me. The toast is paused while the dialog '
        'is open and continues once the dialog is closed. If the message '
        'is longer than the dialog, it scrolls, so even a really long '
        'error report or release note can be read in full without leaving '
        'the screen you are on.';
    const textStyle = TextStyle(color: Colors.white);

    InteractiveToast.slide(
      leading: const Icon(Icons.article_rounded, color: Colors.white),
      title: const Text(
        message,
        maxLines: 2,
        overflow: .ellipsis,
        style: textStyle,
      ),
      dialogTitle: const Text(message, style: textStyle),
      toastSetting: const SlidingToastSetting(
        displayDuration: Duration(seconds: 4),
        showDialogOnTap: true,
        dialogSetting: ToastDialogSetting(maxHeight: 300),
      ),
      toastStyle: const ToastStyle(
        backgroundColor: Color(0xFF263238),
        progressBarColor: Colors.amber,
        titleLeadingGap: 10,
        widgetCrossAxisAlignment: .start,
      ),
    );
  }

  Container _leadingWidget() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: .circle,
        color: Colors.purple,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            spreadRadius: 3,
            blurRadius: 4,
          ),
        ],
      ),
      alignment: .center,
      child: const Text('🦄', style: TextStyle(fontSize: 20)),
    );
  }

  Text _textWidget(String text) =>
      Text(text, style: const TextStyle(fontSize: 16));

  Icon _trailingWidget() =>
      Icon(Icons.person, color: Theme.of(context).colorScheme.primary);
}
