import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/main.dart';
import 'package:diurnul/screens/today_screen.dart';

void main() {
  test('application and Today screen can be constructed', () {
    expect(const DiurnalApp(), isA<StatefulWidget>());
    expect(const TodayScreen(), isA<StatefulWidget>());
  });
}
