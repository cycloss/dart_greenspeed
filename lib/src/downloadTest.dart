import 'dart:async';
import 'dart:io';

// TODO add getIP to display distance and isp

class DownloadTest {
  StreamController<double> mbpsController = StreamController();
  StreamController<double> percentController = StreamController();

  bool graceTimeOver = false;
  late DateTime startTime;
  double secondsElapsed = 0;
  final ckSize = 100;
  final graceTime = 1;
  final dlTime = 10;
  final client = HttpClient();
  final String serverAddress;

  DownloadTest({required this.serverAddress});

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
      updateElapsed();
    }

    client.close();
  }

  void _checkGraceTime() {
    if (!graceTimeOver) {
      if (secondsElapsed >= graceTime) {
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
    return (secondsElapsed / dlTime) * 100;
  }

  double calculateSpeed(int totalDownloaded) {
    var megabits = (totalDownloaded / 1000000) * 8;
    var seconds = secondsElapsed;
    print(seconds);
    return megabits / seconds;
  }

  void updateElapsed() {
    secondsElapsed = DateTime.now().difference(startTime).inMilliseconds / 1000;
  }
}
