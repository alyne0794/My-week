
import 'package:flutter/foundation.dart';

class CourseState extends ChangeNotifier {
  int _courseCount = 0;

  int get courseCount => _courseCount;

  void updateCourseCount(int count) {
    _courseCount = count;
    notifyListeners();
  }
}
