import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration for all tests
/// This file is automatically loaded by the test runner

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Set a consistent test window size for widget tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure golden file comparator for consistent results
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = LocalFileComparator(testUrl);
  }

  await testMain();
}
