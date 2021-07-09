import 'dart:async';
import 'dart:io';

import 'package:dart_librespeed/speed_test.dart';

// TODO add abort method
class DownloadTest {
  final StreamController<Result> _mbpsController = StreamController();
  final StreamController<Result> _percentController = StreamController();

  late bool _graceTimeOver;
  late DateTime _startTime;
  late double _secondsElapsed;
  late int _bytesDownloaded;

  final _ckSize = 100;
  final _graceTime = 1;
  final double _dlTime;
  final _client = HttpClient();
  final String _serverAddress;

  Stream<Result> get mbpsStream => _mbpsController.stream;
  Stream<Result> get percentCompleteStream => _percentController.stream;

  DownloadTest({required String serverAddress, double downloadTime = 10})
      : _serverAddress = serverAddress,
        _dlTime = downloadTime;

  /// Starts the download test.
  /// Must not be called after `close` has been called
  Future<void> start() async {
    _reset();
    var resp = await _makeRequest();
    var mbpsResult = Result();
    var percentResult = Result();
    await for (var data in resp) {
      if (mbpsResult.abort || percentResult.abort) {
        break;
      }
      _updateElapsed();
      if (_graceTimeOver) {
        _bytesDownloaded += data.length;
        mbpsResult.value = _calculateSpeed();
        _mbpsController.add(mbpsResult);
        var percentDone = _calculatePercentDone();

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
    _percentController.add(Result());
    _mbpsController.add(Result());
    _graceTimeOver = false;
    _startTime = DateTime.now();
    _secondsElapsed = 0;
    _bytesDownloaded = 0;
  }

  Future<HttpClientResponse> _makeRequest() async {
    var req = await _client
        .getUrl(Uri.parse('$_serverAddress/garbage.php?ckSize=$_ckSize'));
    return req.close();
  }

  double _calculateSpeed() {
    var megabits = (_bytesDownloaded / 1000000) * 8;
    var seconds = _secondsElapsed;
    return megabits / seconds;
  }

  double _calculatePercentDone() {
    return _secondsElapsed / _dlTime;
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
    _mbpsController.close();
    _percentController.close();
    _client.close();
  }
}
