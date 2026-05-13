import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('architecture guard passes with hidden presentation leak checks', () async {
    final result = await Process.run(
      'python3',
      ['tools/architecture_guard.py'],
      workingDirectory: Directory.current.path,
    );

    expect(
      result.exitCode,
      0,
      reason: '${result.stdout}\n${result.stderr}',
    );
  });
}
