import 'package:audio_relay_x_server/config.dart';
import 'package:audio_relay_x_server/data/server.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

class Player {
  static Future<void> init(
    dynamic pcmInstance,
    Future<void> Function(int remainingFrames) onFeed,
  ) async {
    await pcmInstance.init(
      sampleRate: defaultSampleRate,
      channelCount: defaultChannels,
    );

    pcmInstance.setFeedCallback(onFeed);
    await pcmInstance.start();
  }
}

class UniversalPlayer extends Player {
  static Future<void> init() async {
    await Player.init(
      FlutterPcmSound,
      _onFeed,
    );
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
