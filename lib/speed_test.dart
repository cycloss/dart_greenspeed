/// Support for doing something awesome.
///
/// More dartdocs go here.
library dart_librespeed;

import 'package:dart_librespeed/src/isolateDownloadTest.dart';

export 'src/pingJitterTest.dart';
export 'src/result.dart';
export 'src/uploadTest.dart';

abstract class DownloadTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;
  Future<void> start();
  Future<void> abort();
  void close();

  factory DownloadTest(
      {required String serverAddress,
      required int updateIntervalMs,
      required int testDurationMs}) {
    return IsolateDownloadTest(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs);
  }
}
