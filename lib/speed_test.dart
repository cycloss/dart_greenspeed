/// Support for doing something awesome.
///
/// More dartdocs go here.
library dart_librespeed;

import 'src/dlulIsolate.dart';
import 'src/downloadWorker.dart';
import 'src/pingJitterWorker.dart';
import 'src/pjIsolate.dart';
import 'src/uploadWorker.dart';

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
    var downloaderTask = DownloadWorker.startDownload;
    return DLULIsolate(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        task: downloaderTask);
  }
}

abstract class UploadTest {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;

  Future<void> start();
  Future<void> abort();
  void close();

  factory UploadTest(
      {required String serverAddress,
      required int updateIntervalMs,
      required int testDurationMs}) {
    var downloaderTask = UploadWorker.startUpload;
    return DLULIsolate(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        task: downloaderTask);
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
      required int testDurationMs}) {
    var pjTask = PingJitterWorker.startPJTest;
    return PJIsolate(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        task: pjTask);
  }
}
