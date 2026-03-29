import 'package:flutter/foundation.dart';

/// Simple global unread message counter service.
/// Use UnreadMessageService.instance to read/update the value.
class UnreadMessageService extends ChangeNotifier {
  UnreadMessageService._internal();

  static final UnreadMessageService _instance =
      UnreadMessageService._internal();

  static UnreadMessageService get instance => _instance;

  int _count = 0;

  int get count => _count;

  set count(int v) {
    if (v != _count) {
      _count = v;
      notifyListeners();
    }
  }

  void increment([int by = 1]) {
    count = _count + by;
  }

  void clear() {
    if (_count != 0) {
      _count = 0;
      notifyListeners();
    }
  }
}
