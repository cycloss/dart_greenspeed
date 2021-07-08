import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:speed_test/src/utilities.dart';

// TODO add getIP to display distance and isp

class UploadTest {
  StreamController<double> mbpsController = StreamController();
  StreamController<double> percentController = StreamController();

  late bool _graceTimeOver;
  late DateTime _startTime;
  late double _secondsElapsed;
  late int _bytesUploaded;

  final _ckSize = 100;
  final _bufferSizeBytes = 10000;
  final _graceTime = 1;
  final double _ulTime;
  final _client = HttpClient();
  final String _serverAddress;

  Stream<double> get mbpsStream => mbpsController.stream;
  Stream<double> get percentCompleteStream => percentController.stream;

  UploadTest({required String serverAddress, double uploadTime = 10})
      : _serverAddress = serverAddress,
        _ulTime = uploadTime;

  Future<void> start() async {
    _reset();
    var post = await _makePost();
    var bytes = generateRandomBytes(_ckSize * 1000000);

    for (var offset = 0;
        offset + _bufferSizeBytes < bytes.buffer.lengthInBytes;
        offset += _bufferSizeBytes) {
      var byteView = Uint8List.view(bytes.buffer, offset, _bufferSizeBytes);
      post.add(byteView);
      await post.flush(); // wait until data accepted by server
      _updateElapsed();
      if (_graceTimeOver) {
        _bytesUploaded += _bufferSizeBytes;
        var mbps = _calculateSpeed();
        mbpsController.add(mbps);
        var percentDone = _calculatePercentDone();
        if (percentDone >= 100) {
          percentController.add(100);
          await post.close();
          break;
        } else {
          percentController.add(percentDone);
        }
      } else {
        _checkGraceTime();
      }
    }
  }

  void _reset() {
    percentController.add(0);
    mbpsController.add(0);
    _graceTimeOver = false;
    _startTime = DateTime.now();
    _secondsElapsed = 0;
    _bytesUploaded = 0;
  }

  Future<HttpClientRequest> _makePost() async {
    var r = Random().nextDouble();
    var post =
        await _client.postUrl(Uri.parse('$_serverAddress/empty.php?r=$r'));
    post.headers.contentType = ContentType.binary;
    // flush the headers to the stream
    await post.flush();
    return post;
  }

  double _calculateSpeed() {
    var megabits = (_bytesUploaded / 1000000) * 8;
    var seconds = _secondsElapsed;

    return megabits / seconds;
  }

  double _calculatePercentDone() {
    return (_secondsElapsed / _ulTime) * 100;
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
    _client.close();
  }
}
