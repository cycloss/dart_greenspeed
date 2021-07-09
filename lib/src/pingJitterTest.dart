import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_librespeed/src/aborter.dart';

class PingJitterTest with Aborter {
  final StreamController<double> _pingController = StreamController();
  final StreamController<double> _jitterController = StreamController();
  final StreamController<double> _percentController = StreamController();

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

  Stream<double> get pingStream => _pingController.stream;
  Stream<double> get jitterStream => _jitterController.stream;
  Stream<double> get percentCompleteStream => _percentController.stream;

  PingJitterTest({required String serverAddress, double pingTime = 5})
      : _serverAddress = serverAddress,
        _pingTime = pingTime;

  /// Starts the download test.
  /// Must not be called after `close` has been called
  Future<void> start() async {
    _reset();
    while (true) {
      var pingStart = DateTime.now();
      var req = await _makeRequest();
      var resp = await req.close();
      var pingEnd = DateTime.now();
      if (resp.statusCode != 200) {
        throw Exception(
            'Server fully operational, status code: ${resp.statusCode}');
      }
      _updateElapsed();
      if (abort) {
        break;
      }
      if (_graceTimeOver) {
        var currentPing = pingEnd.difference(pingStart).inMicroseconds / 1000;
        var percentDone = _calculatePercentDone();
        _pingAverage = _calculateAveragePing(currentPing);
        _jitterAverge = _calculateJitter(currentPing);

        _lastPing = currentPing;
        _pingCount++;
        _pingController.add(_pingAverage);
        _jitterController.add(_jitterAverge);
        if (percentDone >= 1) {
          _percentController.add(1);
          break;
        } else {
          _percentController.add(percentDone);
        }
      } else {
        _checkGraceTime();
      }
    }
  }

  void _reset() {
    _percentController.add(0);
    _pingController.add(0);
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
