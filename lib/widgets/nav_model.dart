import 'package:flutter/material.dart';

class NavModel extends ChangeNotifier {
  int index = 0;
  void set(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
