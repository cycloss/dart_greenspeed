library dart_librespeed;

import 'package:dart_librespeed/src/uploadWorker.dart';

import 'src/dlulIsolateController.dart';
import 'src/downloadWorker.dart';
import 'src/pingJitterWorker.dart';
import 'src/pjIsolateController.dart';

abstract class DownloadTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;

  Future<void> start();
  Future<void> abort();

  /// `authToken` is optional and only required if the testing server uses the `Authorize` header to secure the test to customers only.
  factory DownloadTest({
    required String serverAddress,
    String? authToken,
    required int updateIntervalMs,
    required int testDurationMs,
    int isolateCount = 2,
  }) {
    var downloaderTask = DownloadWorker.startDownload;
    return DLULIsolateController(
        serverAddress: serverAddress,
        authToken: authToken,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        isolateCount: isolateCount,
        task: downloaderTask);
  }
}

abstract class UploadTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;

  Future<void> start();
  Future<void> abort();
  void close();

  factory UploadTest({
    required String serverAddress,
    required int updateIntervalMs,
    required int testDurationMs,
    int isolateCount = 2,
  }) {
    var uploaderTask = UploadWorker.startUpload;
    return DLULIsolateController(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        isolateCount: isolateCount,
        task: uploaderTask);
  }
}

abstract class PingJitterTest {
  Stream<double> get pingStream;
  Stream<double> get jitterStream;
  Stream<double> get percentStream;

  Future<void> start();
  Future<void> abort();
  void close();

  factory PingJitterTest(
      {required String serverAddress,
      required int updateIntervalMs,
      int isolateCount = 2,
      required int testDurationMs}) {
    var pjTask = PingJitterWorker.startPJTest;
    return PJIsolateController(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        isolateCount: isolateCount,
        task: pjTask);
  }
}
