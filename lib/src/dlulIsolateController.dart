import 'dart:async';

import 'package:dart_greenspeed/src/isolateController.dart';

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
  var totalMegabits = 0.0;
  var started = false;

  DLULIsolateController(
      {required String serverAddress,
      String? authToken,
      required int updateIntervalMs,
      required int testDurationMs,
      required int isolateCount,
      required Future<void> Function(SpawnBundle) task})
      : super(
            serverAddress: serverAddress,
            authToken: authToken,
            updateIntervalMs: updateIntervalMs,
            testDurationMs: testDurationMs,
            isolateCount: isolateCount,
            task: task);

  @override
  Future<void> calculateSpeed() async {
    attachErrorHandlers();
    attachIsolateListeners();

    var startTime = DateTime.now();
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
      } else {
        startTime = DateTime.now();
        totalMegabits = 0;
      }
    }
  }

  void attachIsolateListeners() {
    channels.forEach((channel) {
      channel.stream.listen((mbits) {
        if (!started) {
          started = true;
        }
        totalMegabits += mbits;
      });
      channel.sink.add(IsolateEvent.start);
    });
  }

  void attachErrorHandlers() {
    errorRPorts.forEach((rPort) {
      // errors come through as a two item array and as a standard object
      rPort.listen((message) {
        var exceptionStr = message[0] as String;
        var e = parseExecption(exceptionStr);

        _mbpsController.addError(e);
        abort();
      });
    });
  }

  @override
  Future<void> abort() async {
    await close();
    super.abort();
  }

  @override
  Future<void> close() async {
    await _mbpsController.close();
    await _percentController.close();
  }
}
