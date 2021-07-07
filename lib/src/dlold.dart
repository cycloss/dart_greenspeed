import 'dart:async';
import 'dart:io';

// TODO add typedefs for functions
// TODO add getIP to display distance and isp

typedef OnProgress = void Function(double mbps, double percentDone);

class SpeedTest {
  late DownloadTest _downloadTest;

  Future<void> startDownloadTest(
      {required String serverAddress, required OnProgress onProgress}) {
    _downloadTest =
        DownloadTest(serverAddress: serverAddress, onProgress: onProgress);
    return _downloadTest.start();
  }
}

class DownloadTest {
  bool graceTimeOver = false;
  int totalBytesDownloaded = 0;
  double elapsedSeconds = 0;
  late DateTime startTime;
  late DateTime latestUpdate;
  final ckSize = 100;
  final graceTime = 2;
  final dlTime = 10;
  final client = HttpClient();
  final String _serverAddress;
  final OnProgress onProgress;

  DownloadTest({required serverAddress, required this.onProgress})
      : _serverAddress = serverAddress;

  Future<void> start() async {
    await _resetTest();

    var resp = await makeRequest();
    await for (var data in resp) {
      if (graceTimeOver) {
        totalBytesDownloaded += data.length;
        _checkOnProgress();
        elapsedSeconds =
            DateTime.now().difference(startTime).inMilliseconds / 1000;
        if (elapsedSeconds >= dlTime) {
          printResult();
          break;
        }
      } else {
        _checkGraceTime();
      }
    }

    client.close();
  }

  void printResult() {
    print('Test time: $elapsedSeconds');
    var mbs = totalBytesDownloaded / 1000000 * 8;
    print('Megabits downloaded: $mbs');
    print('Connection speed: ${mbs / elapsedSeconds}');
  }

  Future<void> _resetTest() async {
    graceTimeOver = false;
    startTime = DateTime.now();
    totalBytesDownloaded = 0;
    elapsedSeconds = 0;
  }

  void _checkGraceTime() {
    if (!graceTimeOver) {
      var graceSecs =
          DateTime.now().difference(startTime).inMilliseconds / 1000;
      if (graceSecs >= graceTime) {
        graceTimeOver = true;
        startTime = latestUpdate = DateTime.now();
        print('grace time over');
      }
    }
  }

  Future<HttpClientResponse> makeRequest() async {
    var req = await client
        .getUrl(Uri.parse('$_serverAddress/garbage.php?ckSize=$ckSize'));
    return req.close();
  }

  void _checkOnProgress() {
    var now = DateTime.now();
    if (now.difference(latestUpdate).inMilliseconds > 200) {
      onProgress(calculateSpeed(), calculatePercentDone());
      latestUpdate = now;
    }
  }

  double calculatePercentDone() {
    return elapsedSeconds / dlTime;
  }

  double calculateSpeed() {
    var megabits = totalBytesDownloaded / 1000000 * 8;
    return megabits / elapsedSeconds;
  }
}

//   static const _defaultUlServerAddress = 'http://ipv4.ikoula.testdebit.info/';

void main() async {
  var st = SpeedTest();
  await st.startDownloadTest(
      serverAddress: 'http://speedtest.wessexinternet.com',
      onProgress: (mbps, pc) {
        print('speed: ${mbps.toStringAsFixed(2)} mb/s');
        print('percent done: ${(pc * 100).toStringAsFixed(2)}%');
      });
}
