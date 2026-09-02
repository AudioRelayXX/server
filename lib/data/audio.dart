import 'dart:typed_data';

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
    final samplesToFeed = frame.isEmpty
        ? Int16List(remainingFrames * 2) // channels=2, zero-filled = silence
        : frame;
    await FlutterPcmSound.feed(
      PcmArrayInt16.fromList(samplesToFeed as List<int>),
    );
  }

  static Future<void> dispose() async {
    FlutterPcmSound.release();
  }
}
