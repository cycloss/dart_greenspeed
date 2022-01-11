import 'dart:async';

import 'package:dart_librespeed/src/isolateController.dart';

import '../speed_test.dart';
import 'utilities.dart';

class DLULIsolateController extends IsolateController
    implements DownloadTest, UploadTest {
  final StreamController<double> _mbpsController = StreamController();
  final StreamController<double> _percentController = StreamController();

  @override
  Stream<double> get mbpsStream => _mbpsController.stream;
  @override
  Stream<double> get percentCompleteStream => _percentController.stream;

  DLULIsolateController(
      {required String serverAddress,
      required int updateIntervalMs,
      required int testDurationMs,
      required Future<void> Function(SpawnBundle) task})
      : super(
            serverAddress: serverAddress,
            updateIntervalMs: updateIntervalMs,
            testDurationMs: testDurationMs,
            task: task);

  @override
  Future<void> close() async {
    await _mbpsController.close();
    await _percentController.close();
    super.close();
  }

  @override
  Future<void> calculateSpeed() async {
    var totalMegabits = 0.0;
    var startTime = DateTime.now();
    var started = false;
    channels.forEach((channel) {
      channel.sink.add(IsolateEvent.start);
      channel.stream.listen((mbits) {
        if (!started) {
          started = true;
          startTime = DateTime.now();
        }
        totalMegabits += mbits;
      });
    });

    while (!abortTest) {
      await Future.delayed(Duration(milliseconds: updateIntervalMs));
      if (abortTest) break;
      var elapsedSecs =
          DateTime.now().difference(startTime).inMilliseconds / 1000;
      if ((elapsedSecs * 1000) > testDurationMs) {
        _percentController.add(1.0);
        await abort();
        break;
      }
      // only add if start signal has been given
      if (started) {
        _mbpsController.add(totalMegabits / elapsedSecs);
        _percentController.add((elapsedSecs * 1000) / testDurationMs);
      }
    }
    await close();
  }

  @override
  Future<void> abort() async {
    await super.abort();
    await close();
  }
}