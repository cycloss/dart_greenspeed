library dart_greenspeed;

import 'package:dart_greenspeed/src/uploadWorker.dart';

import 'src/dlulIsolateController.dart';
import 'src/downloadWorker.dart';
import 'src/pingJitterWorker.dart';
import 'src/pjIsolateController.dart';

abstract class SpeedTest {
  /// Starts a test, causing that test's `Stream`s to begin emitting events.
  /// Must **not** be called multiple times. Instantiate a new test object if you want to restart a test.
  /// Returns a future that completes when a test has finished.
  Future<void> start();

  /// Aborts a running test, closing its worker isolates and stream resources. (Implicitly calls `close`).
  Future<void> abort();

  /// Releases a test object's stream resources. Must not be called before `start`'s future has returned.
  Future<void> close();
}

abstract class DownloadTest implements SpeedTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;

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

abstract class UploadTest implements SpeedTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;

  factory UploadTest({
    required String serverAddress,
    String? authToken,
    required int updateIntervalMs,
    required int testDurationMs,
    int isolateCount = 2,
  }) {
    var uploaderTask = UploadWorker.startUpload;
    return DLULIsolateController(
        serverAddress: serverAddress,
        authToken: authToken,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        isolateCount: isolateCount,
        task: uploaderTask);
  }
}

abstract class PingJitterTest implements SpeedTest {
  Stream<double> get pingStream;
  Stream<double> get jitterStream;
  Stream<double> get percentStream;

  factory PingJitterTest({
    required String serverAddress,
    String? authToken,
    required int updateIntervalMs,
    required int testDurationMs,
    int isolateCount = 2,
  }) {
    var pjTask = PingJitterWorker.startPJTest;
    return PJIsolateController(
        serverAddress: serverAddress,
        authToken: authToken,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        isolateCount: isolateCount,
        task: pjTask);
  }
}

class SpeedTestAuthException implements Exception {
  final String? _message;
  SpeedTestAuthException([String? message]) : _message = message;

  @override
  String toString() {
    var error = 'SpeedTestAuthException';
    if (_message != null) {
      return '$error: $_message';
    }
    return error;
  }
}
