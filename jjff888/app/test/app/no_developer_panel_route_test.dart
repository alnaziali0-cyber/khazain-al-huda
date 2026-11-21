import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile source contains no developer panel route or hidden entry point', () {
    final appRoot = Directory('lib');
    final dartFiles = appRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final sources = dartFiles.map((file) => file.readAsStringSync()).join('\n');

    expect(sources, isNot(contains("path: '/developer'")));
    expect(sources, isNot(contains("context.push('/developer')")));
    expect(sources, isNot(contains('DeveloperPanelScreen')));
  });
}
