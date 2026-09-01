import 'package:audio_relay_x_server/data/server.dart';
import 'package:bootstrap/bootstrap.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

class UniversalPlayer {
  static Future<void> init() async {
    await FlutterPcmSound.setup(
      sampleRate: defaultSampleRate,
      channelCount: defaultChannels,
    );

    FlutterPcmSound.setFeedCallback(_onFeed);

    FlutterPcmSound.start();
  }

  static Future<void> _onFeed(int remainingFrames) async {
    final frame = Server.getPlaybackFrame();

    if (frame.isEmpty) {
      return;
    }
    await FlutterPcmSound.feed(
      PcmArrayInt16.fromList(frame),
    );
  }
}
