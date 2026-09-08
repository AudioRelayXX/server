import 'dart:typed_data';

import 'package:audio_relay_x_server/data/server.dart';
import 'package:bootstrap/bootstrap.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:forge/forge.dart';

class UniversalPlayer {
  static const int _frameDurationMs = 20;
  static int get _samplesPerFrame =>
      (defaultSampleRate * _frameDurationMs ~/ 1000) * defaultChannels;
  static Future<void> init() async {
    await FlutterPcmSound.setup(
      sampleRate: defaultSampleRate,
      channelCount: defaultChannels,
    );
    await ForgeInit.ensure();
    FlutterPcmSound.setFeedCallback(_onFeed);
    FlutterPcmSound.start();
  }

  static Future<void> _onFeed(int remainingFrames) async {
    try {
      final frame = Server.getPlaybackFrame();
      final samples = frame.isEmpty
          ? Int16List(_samplesPerFrame)
          : Int16List.sublistView(frame);
      await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
    } catch (e, st) {
      logger.e('onFeed failed, feeding silence instead',
          error: e, stackTrace: st);
      await FlutterPcmSound.feed(
        PcmArrayInt16.fromList(Int16List(_samplesPerFrame)),
      );
    }
  }

  static Future<void> dispose() async {
    FlutterPcmSound.release();
  }
}
