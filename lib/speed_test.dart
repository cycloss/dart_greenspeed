/// Support for doing something awesome.
///
/// More dartdocs go here.
library dart_librespeed;

import 'src/downloadWorker.dart';
import 'src/isolateTest.dart';
import 'src/uploadWorker.dart';

export 'src/pingJitterTest.dart';
export 'src/result.dart';

abstract class Test {
  Stream<double> get mbpsStream;
  Stream<double> get percentCompleteStream;
  Future<void> start();
  Future<void> abort();
  void close();

  factory Test.download(
      {required String serverAddress,
      required int updateIntervalMs,
      required int testDurationMs}) {
    var downloaderTask = DownloadWorker.startDownload;
    return IsolatedTest(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        task: downloaderTask);
  }

  factory Test.upload(
      {required String serverAddress,
      required int updateIntervalMs,
      required int testDurationMs}) {
    var uploaderTask = UploadWorker.startUpload;
    return IsolatedTest(
        serverAddress: serverAddress,
        updateIntervalMs: updateIntervalMs,
        testDurationMs: testDurationMs,
        task: uploaderTask);
  }
}
