import 'dart:async';

import 'package:dart_greenspeed/speed_test.dart';
import 'package:dart_greenspeed/src/isolateController.dart';

import 'utilities.dart';

class PJIsolateController extends IsolateController implements PingJitterTest {
  final StreamController<double> _pingController = StreamController();
  final StreamController<double> _jitterController = StreamController();
  final StreamController<double> _percentController = StreamController();

  @override
  final int msGrace = 0;

  @override
  Stream<double> get pingStream => _pingController.stream;
  @override
  Stream<double> get jitterStream => _jitterController.stream;
  @override
  Stream<double> get percentStream => _percentController.stream;

  var latestPing = 0.0;
  var latestJitter = 0.0;
  var startTime = DateTime.now();
  var started = false;

  PJIsolateController(
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
    reset();
    attachErrorHandlers();
    attachIsolateListeners();

    while (!abortTest) {
      await Future.delayed(Duration(milliseconds: updateIntervalMs));
      if (abortTest) return;
      var elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsedMs > testDurationMs) {
        _percentController.add(1.0);
        abort();
        return;
      }
      // only add if start signal has been given
      if (started) {
        _pingController.add(latestPing);
        _jitterController.add(latestJitter);
        _percentController.add(elapsedMs / testDurationMs);
      } else {
        latestPing = 0.0;
        latestJitter = 0.0;
        startTime = DateTime.now();
      }
    }
  }

  void attachIsolateListeners() {
    channels.forEach((channel) {
      channel.sink.add(IsolateEvent.start);
      channel.stream.listen((message) {
        if (!started) {
          started = true;
          startTime = DateTime.now();
        }
        var vals = (message as String).split('-');
        latestPing = double.parse(vals[0]);
        latestJitter = double.parse(vals[1]);
      });
    });
  }

  void attachErrorHandlers() {
    errorRPorts.forEach((rPort) {
      // errors come through as a two item array and as a standard object
      rPort.listen((message) {
        var exceptionStr = message[0] as String;
        var e = parseExecption(exceptionStr);
        _pingController.addError(e);
        _jitterController.addError(e);
        abort();
      });
    });
  }

  @override
  void reset() {
    latestPing = 0.0;
    latestJitter = 0.0;
    startTime = DateTime.now();
    started = false;
  }

  @override
  Future<void> close() async {
    await _pingController.close();
    await _jitterController.close();
    await _percentController.close();
  }
}
