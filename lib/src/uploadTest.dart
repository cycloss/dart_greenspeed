import 'dart:async';
import 'dart:io';

// TODO add getIP to display distance and isp

class UploadTest {
  StreamController<double> mbpsController = StreamController();
  StreamController<double> percentController = StreamController();

  bool graceTimeOver = false;
  late DateTime startTime;

  final ckSize = 100;
  final graceTime = 2;
  final dlTime = 10;
  final client = HttpClient();
  final String serverAddress;

  UploadTest({required this.serverAddress});

  Future<void> start() async {
    var resp = await makeRequest();
    startTime = DateTime.now();
    var totalBytes = 0;
    await for (var data in resp) {
      if (graceTimeOver) {
        totalBytes += data.length;
        var mbps = calculateSpeed(totalBytes);
        mbpsController.add(mbps);
        var percentDone = calculatePercentDone();
        if (percentDone >= 100) {
          percentController.add(100);
          break;
        } else {
          percentController.add(percentDone);
        }
      } else {
        _checkGraceTime();
      }
    }

    client.close();
  }

  double getSecondsElapsed() =>
      DateTime.now().difference(startTime).inMilliseconds / 1000;

  void _checkGraceTime() {
    if (!graceTimeOver) {
      if (getSecondsElapsed() >= graceTime) {
        graceTimeOver = true;
        startTime = DateTime.now();
      }
    }
  }

  Future<HttpClientResponse> makeRequest() async {
    var req = await client
        .getUrl(Uri.parse('$serverAddress/garbage.php?ckSize=$ckSize'));
    return req.close();
  }

  double calculatePercentDone() {
    return getSecondsElapsed() / dlTime;
  }

  double calculateSpeed(int totalDownloaded) {
    var megabits = (totalDownloaded / 1000000) * 8;
    return megabits / getSecondsElapsed();
  }
}
