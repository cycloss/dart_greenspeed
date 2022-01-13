# Dart Speed Test

A web socket based speed testing library. Built for use in Flutter or the command line.

Supports testing ping (ms), jitter (ms), download speed (megabits/sec) and upload speed (megabits/sec). Also shows the percentage completetion for each test.

## Installing

This library is not available on pub.dev, so add the following to your `pubspec.yaml` dependencies:

```yaml
dart_librespeed:
    git:
      url: https://github.com/cycloss/dart_librespeed
      ref: main
```

A server side installation will also be required to accept and handle incoming websocket communications.

## Simple Usage Example

- `start()` may be called multiple times, and returns a future that completes once a test has completed.
- `abort()` may be called to immediately stop a test. `start()` can be called again after an abort.
- `close()` should be called once the test is no longer needed. This will release resources like streams. Once `close()` has been called on a test object, `start()` cannot be called on that object again.
- Providing an optional `authToken` to a test constructor, will cause an `Authorize` header to be passed with the token into the initial http request to the server to upgrade to a websocket. This is appropriate if the server is expecting an authentication token to permit testing.
- `isolateCount` specifies how many isolates a test should run with. Defaults to `2`.

```dart
import 'package:dart_librespeed/speed_test.dart';

Future<void> main() async {
  var baseAddress = 'http://mydomain.com';

  print('Starting download test');

  var dlTest = DownloadTest(
      serverAddress: '$baseAddress/download',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 4);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);

  await dlTest.start();
  await dlTest.close();

  print('Starting upload test');

  var ulTest = UploadTest(
      serverAddress: '$baseAddress/upload',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 2);
  ulTest.mbpsStream.listen(print);
  ulTest.percentCompleteStream.listen(print);

  await ulTest.start();
  await ulTest.close();

  print('Starting ping jitter test');

  var pingJitterTest = PingJitterTest(
      serverAddress: '$baseAddress/ping',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 1);
  pingJitterTest.pingStream
      .listen((pingMs) => print('${pingMs.toStringAsFixed(2)} ms ping'));
  pingJitterTest.jitterStream
      .listen((jitterMs) => print('$jitterMs ms jitter'));
  pingJitterTest.percentStream.listen(print);

  await pingJitterTest.start();
  await pingJitterTest.close();
}
```
