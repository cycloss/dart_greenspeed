import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'result.dart';

class PingJitterTest {
  final StreamController<Result> _pingController = StreamController();
  final StreamController<Result> _jitterController = StreamController();
  final StreamController<Result> _percentController = StreamController();

  late bool _graceTimeOver;
  late DateTime _startTime;
  late double _secondsElapsed;

  final _graceTime = 1;
  final double _pingTime;
  final _client = HttpClient();
  final String _serverAddress;

  double _pingAverage = 0;
  double _lastPing = 0;
  int _pingCount = 0;

  double _jitterAverge = 0;

  final _rand = Random();

  Stream<Result> get pingStream => _pingController.stream;
  Stream<Result> get jitterStream => _jitterController.stream;
  Stream<Result> get percentCompleteStream => _percentController.stream;

  PingJitterTest({required String serverAddress, double pingTime = 5})
      : _serverAddress = serverAddress,
        _pingTime = pingTime;

  /// Starts the download test.
  /// Must not be called after `close` has been called
  Future<void> start() async {
    _reset();
    var pingResult = Result();
    var jitterResult = Result();
    var percentResult = Result();
    while (true) {
      var pingStart = DateTime.now();
      var req = await _makeRequest();
      var resp = await req.close();
      var pingEnd = DateTime.now();
      if (resp.statusCode != 200) {
        throw Exception(
            'Server fully operational, status code: ${resp.statusCode}');
      }
      if (pingResult.abort || jitterResult.abort || percentResult.abort) {
        break;
      }
      _updateElapsed();
      if (_graceTimeOver) {
        var currentPing = pingEnd.difference(pingStart).inMicroseconds / 1000;
        var percentDone = _calculatePercentDone();
        _pingAverage = _calculateAveragePing(currentPing);
        _jitterAverge = _calculateJitter(currentPing);
        _lastPing = currentPing;
        _pingCount++;
        pingResult.value = _pingAverage;
        jitterResult.value = _jitterAverge;

        _pingController.add(pingResult);
        _jitterController.add(jitterResult);
        if (percentDone >= 1) {
          percentResult.value = 1;
          _percentController.add(percentResult);
          break;
        } else {
          percentResult.value = percentDone;
          _percentController.add(percentResult);
        }
      } else {
        _checkGraceTime();
      }
    }
  }

  void _reset() {
    _pingController.add(Result());
    _jitterController.add(Result());
    _percentController.add(Result());
    _graceTimeOver = false;
    _startTime = DateTime.now();
    _secondsElapsed = 0;
    _pingAverage = 0;
    _pingCount = 0;
    _lastPing = 0;
    _jitterAverge = 0;
  }

  Future<HttpClientRequest> _makeRequest() => _client
      .getUrl(Uri.parse('$_serverAddress/empty.php?r=${_rand.nextDouble()}'));

  double _calculateAveragePing(double currentPing) {
    var currentWeight = 1 / (_pingCount + 1);
    var pastWeight = 1 - currentWeight;
    var weightedAverage =
        (currentPing * currentWeight) + (_pingAverage * pastWeight);
    return weightedAverage;
  }

  double _calculateJitter(double currentPing) {
    var currentWeight = 1 / (_pingCount + 1);
    var pastWeight = 1 - currentWeight;
    var diff = (currentPing - _lastPing).abs();
    var weightedAverage = (diff * currentWeight) + (_jitterAverge * pastWeight);
    return weightedAverage;
  }

  double _calculatePercentDone() {
    return _secondsElapsed / _pingTime;
  }

  void _updateElapsed() {
    _secondsElapsed =
        DateTime.now().difference(_startTime).inMilliseconds / 1000;
  }

  void _checkGraceTime() {
    if (!_graceTimeOver) {
      if (_secondsElapsed >= _graceTime) {
        _graceTimeOver = true;
        _startTime = DateTime.now();
      }
    }
  }

  void close() {
    _pingController.close();
    _percentController.close();
    _client.close();
  }
}
