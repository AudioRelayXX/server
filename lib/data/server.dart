import 'dart:async';
import 'dart:typed_data';

import 'package:bootstrap/bootstrap.dart';
import 'package:flywheel/flywheel.dart';
import 'package:forge/forge.dart';
import 'package:trebuchet/trebuchet.dart';

class Jitter {
  static FlywheelBuffer? _buffer;

  static void init() {
    _buffer ??= FlywheelBuffer(
      targetLatencyMs: 30,
      maxPacketAgeMs: 30,
    );
  }

  static void addPacket(
      int sequence,
      Uint8List payload,
      ) {
    init();
    _buffer!.addPacket(
      sequence: sequence,
      payload: payload,
    );
  }

  static Uint8List? pullNextFrame() {
    return _buffer?.pullNextFrame();
  }

  static Stream<FlywheelEvent> get events {
    final buffer = _buffer;
    if (buffer == null) {
      throw StateError('Jitter has not been initialized');
    }

    return buffer.events;
  }

  static void dispose() {
    _buffer?.dispose();
    _buffer = null;
  }
}

class Decoder {
  static ForgeDecoder? _decoder;

  static void init({
    required int sampleRate,
    required int channels,
  }) {
    _decoder ??= ForgeDecoder(
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  static Uint8List decode(Uint8List opusPacket) {
    final decoder = _decoder;
    if (decoder == null) {
      throw StateError('Decoder has not been initialized');
    }

    return decoder.decode(opusPacket);
  }

  static void dispose() {
    _decoder?.dispose();
    _decoder = null;
  }
}

class Server {
  static TrebuchetReceiver? _receiver;
  static StreamSubscription<TrebuchetPacket>? _subscription;
  static StreamSubscription<TrebuchetEvent>? _receiverEventsSubscription;

  static Future<void> startServer({
    required int port,
    required int sampleRate,
    required int channels,
  }) async {
    await ForgeInit.ensure();

    Jitter.init();
    Decoder.init(
      sampleRate: sampleRate,
      channels: channels,
    );

    _receiver ??= TrebuchetReceiver(
      port: port,
    );

    _receiverEventsSubscription ??= _receiver!.events.listen((event) {
      logger.d('[Trebuchet] ${event.message}');
    });

    // Subscribe before starting the socket so a packet cannot arrive
    // between socket startup and attaching the packet listener.
    _subscription ??= _receiver!.packets.listen((packet) {
      logger.d(
        'Received packet with sequence ${packet.sequence} '
            'and payload size ${packet.payload.length}',
      );

      Jitter.addPacket(
        packet.sequence,
        packet.payload,
      );
    });

    if (!_receiver!.isStarted) {
      await _receiver!.start();
    }

    logger.i(
      'Audio server listening on UDP port $port '
          '($sampleRate Hz, $channels channel(s))',
    );
  }

  static Uint8List getPlaybackFrame() {
    final opusPacket = Jitter.pullNextFrame();

    if (opusPacket == null) {
      return Uint8List(0);
    }

    return Decoder.decode(opusPacket);
  }

  static Future<void> stopServer() async {
    await _subscription?.cancel();
    _subscription = null;

    await _receiverEventsSubscription?.cancel();
    _receiverEventsSubscription = null;

    await _receiver?.dispose();
    _receiver = null;

    Decoder.dispose();
    Jitter.dispose();
  }
}