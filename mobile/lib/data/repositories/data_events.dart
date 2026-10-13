import 'dart:async';

/// Tiny change bus. Repositories and the sync engine call [notify] after they
/// touched the database; BLoCs listen and reload their lists.
class DataEvents {
  DataEvents._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
