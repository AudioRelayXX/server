import 'dart:io';

import 'package:audio_relay_x_server/data/audio.dart';
import 'package:audio_relay_x_server/data/server.dart';
import 'package:bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServerMainPage extends StatefulWidget {
  const ServerMainPage({
    super.key,
  });

  @override
  State<ServerMainPage> createState() => _ServerMainPageState();
}

enum _ServerState { idle, starting, running, stopping, error }

class _ServerMainPageState extends State<ServerMainPage> {
  _ServerState _state = _ServerState.idle;
  String? _localIp;
  bool _resolvingIp = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _resolveLocalIp();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resolveLocalIp() async {
    setState(() => _resolvingIp = true);

    String? ip;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.isLoopback) continue;
          ip = addr.address;
          break;
        }
        if (ip != null) break;
      }
    } catch (_) {
      ip = null;
    }

    if (!mounted) return;
    setState(() {
      _localIp = ip;
      _resolvingIp = false;
    });
  }

  bool get _isRunning => _state == _ServerState.running;

  bool get _isBusy =>
      _state == _ServerState.starting || _state == _ServerState.stopping;

  Future<void> startServer() async {
    try {
      await Server.startServer(
        port: defaultPort,
        sampleRate: defaultSampleRate,
        channels: defaultChannels,
      );
      UniversalPlayer.init();
    } on Exception {
      rethrow;
    }
  }

  Future<void> stopServer() async {
    await Server.stopServer();
    UniversalPlayer.dispose();
  }

  Future<void> _toggle() async {
    if (_isBusy) return;
    if (_isRunning) {
      setState(() => _state = _ServerState.stopping);
      try {
        await stopServer();
        if (!mounted) return;
        setState(() => _state = _ServerState.idle);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _state = _ServerState.error;
          _lastError = '$e';
        });
        _showError('Failed to stop: $e');
      }
      return;
    }

    setState(() {
      _state = _ServerState.starting;
      _lastError = null;
    });
    try {
      await startServer();
      if (!mounted) return;
      setState(() => _state = _ServerState.running);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ServerState.idle;
        _lastError = '$e';
      });
      _showError('Failed to start: $e');
      rethrow;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyAddress() async {
    final ip = _localIp;
    if (ip == null) return;
    await Clipboard.setData(ClipboardData(text: '$ip:$defaultPort'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard.')),
    );
  }

  String get _statusText {
    switch (_state) {
      case _ServerState.idle:
        return 'Idle';
      case _ServerState.starting:
        return 'Starting…';
      case _ServerState.running:
        return 'Relaying audio 🔴';
      case _ServerState.stopping:
        return 'Stopping…';
      case _ServerState.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text(
              'AudioRelayX Server',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _buildAddressCard(theme),
                const SizedBox(height: 24),
                _buildControlCard(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lan_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This device',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_resolvingIp)
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Finding IP address…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else if (_localIp == null)
                    Text(
                      'Could not determine a LAN IP address. '
                      'Make sure Wi-Fi is connected.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    )
                  else
                    Text(
                      '${_localIp!}:$defaultPort',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Copy address',
                  onPressed: _localIp == null ? null : _copyAddress,
                  icon: const Icon(Icons.copy_rounded),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: _isRunning
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRunning
                        ? Colors.redAccent
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                _lastError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _toggle,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _isRunning ? colorScheme.error : null,
                ),
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isRunning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded),
                label: Text(
                  _isRunning ? 'Stop' : 'Start',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
