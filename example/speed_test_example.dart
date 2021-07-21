import 'package:dart_librespeed/speed_test.dart';

void main() async {
  var dlTest = DownloadTest(
      serverAddress: 'http://speedtest.wessexinternet.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);
  await dlTest.start();
  return;

  var ulTest = UploadTest(serverAddress: 'http://speedtest.wessexinternet.com');
  ulTest.mbpsStream.listen((result) {
    print(result.value);
  });
  await ulTest.start();

  var pingTest =
      PingJitterTest(serverAddress: 'http://speedtest.wessexinternet.com');
  pingTest.pingStream.listen((result) {
    print('${result.value.toStringAsFixed(2)}ms ping');
  });
  pingTest.jitterStream.listen((result) {
    print('${result.value.toStringAsFixed(2)}ms jitter');
  });
  await pingTest.start();
}
