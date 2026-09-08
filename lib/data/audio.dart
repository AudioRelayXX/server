import 'dart:typed_data';

import 'package:audio_relay_x_server/data/server.dart';
import 'package:bootstrap/bootstrap.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:forge/forge.dart';

class UniversalPlayer {
  static ForgeDecoder? _decoder;
  static Future<void> init() async {
    _decoder ??= ForgeDecoder(
      sampleRate: defaultSampleRate,
      channels: defaultChannels,
    );
    await FlutterPcmSound.setup(
      sampleRate: defaultSampleRate,
      channelCount: defaultChannels,
    );
    await ForgeInit.ensure();
    FlutterPcmSound.setFeedCallback(_onFeed);

    FlutterPcmSound.start();
  }

  static Future<void> _onFeed(int remainingFrames) async {
    final frame = Server.getPlaybackFrame();
    final samples = frame.isEmpty
        ? Int16List(remainingFrames * 2)
        : Int16List.sublistView(frame);
    await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
  }

  static Future<void> dispose() async {
    FlutterPcmSound.release();
  }
}
