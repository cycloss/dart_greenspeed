import 'dart:io';
import 'dart:isolate';

class Downloader {
  final receivePort = ReceivePort();
  final isolates = <Isolate>[];
  Future<void> start() async {
    for (var i = 0; i < 6; i++) {
      var isol =
          await Isolate.spawn(Downloader.downloadChunk, receivePort.sendPort);
      isolates.add(isol);
    }
    var start = DateTime.now();
    var total = 0;
    await for (var data in receivePort) {
      total += data as int;
      if (total > 60000000) {
        break;
      }
    }
    print(
        'Mbps: ${(total / 1000000 * 8) / DateTime.now().difference(start).inSeconds}');
    for (var i = 0; i < 6; i++) {
      isolates[i].kill();
    }
  }

  static void downloadChunk(SendPort sp) async {
    print('starting isolate');
    var serverAddress = 'http://speedtest.wessexinternet.com';
    var ckSize = 10;
    var client = HttpClient();
    var req = await client
        .getUrl(Uri.parse('$serverAddress/garbage.php?ckSize=$ckSize'));
    var resp = await req.close();
    await for (var data in resp) {
      sp.send(data.length);
    }
    client.close();
    print('Isolate done');
  }
}

void main() async {
  var dler = Downloader();
  await dler.start();
}
