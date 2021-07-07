import 'package:speed_test/speed_test.dart';

void main() async {
  var dlTest =
      DownloadTest(serverAddress: 'http://speedtest.wessexinternet.com');
  dlTest.mbpsController.stream.listen((event) {
    print(event);
  });
  await dlTest.start();
}
