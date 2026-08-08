import 'package:bootstrap/bootstrap.dart' as bootstrap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  bootstrap.bootstrap(
    app: const AudioRelayXServer(),
    initializeServices: () async {},
  );
}

class AudioRelayXServer extends ConsumerWidget {
  const AudioRelayXServer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AudioRelayX Server',
      debugShowCheckedModeBanner: kDebugMode,
      theme: bootstrap.AppTheme.light,
    );
  }
}
