import 'dart:async';


class DataEvents {
  DataEvents._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
