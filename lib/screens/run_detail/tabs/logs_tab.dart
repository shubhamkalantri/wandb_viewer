import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../providers/run_detail_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../repositories/run_repository.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/error_view.dart';

class LogsTab extends ConsumerStatefulWidget {
  final RunDetailParams params;
  final bool isActive;

  const LogsTab({super.key, required this.params, required this.isActive});

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String? _logContent;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  static const int _maxDisplayLines = 1000;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    if (widget.isActive) _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    final interval = ref.read(settingsProvider).pollInterval;
    _pollTimer = Timer.periodic(interval, (_) => _fetchLogs());
  }

  Future<void> _fetchLogs() async {
    try {
      final filesAsync = ref.read(runFilesProvider(widget.params));
      final files = filesAsync.valueOrNull;
      if (files == null) {
        // Provider hasn't loaded yet, wait for it
        final loadedFiles = await ref.read(runFilesProvider(widget.params).future);
        if (!mounted) return;
        await _downloadLog(loadedFiles);
      } else {
        await _downloadLog(files);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs. Check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _downloadLog(List<RunFile> files) async {
    final logFile = files.where((f) => f.name == 'output.log').firstOrNull;
    if (logFile == null) {
      if (mounted) {
        setState(() {
          _logContent = 'No output.log file found';
          _loading = false;
        });
      }
      return;
    }

    final logUri = Uri.parse(logFile.url);
    if (logUri.scheme != 'https') {
      if (mounted) {
        setState(() {
          _error = 'Unable to load logs securely.';
          _loading = false;
        });
      }
      return;
    }
    final response = await http.get(logUri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      if (mounted) {
        final lines = response.body.split('\n');
        final displayLines = lines.length > _maxDisplayLines
            ? lines.sublist(lines.length - _maxDisplayLines)
            : lines;
        setState(() {
          _logContent = displayLines.join('\n');
          _loading = false;
          _error = null;
        });
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _error = 'Failed to download log (HTTP ${response.statusCode})';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingIndicator(message: 'Loading logs...');
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });
          _fetchLogs();
        },
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            _logContent ?? '',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              setState(() => _autoScroll = !_autoScroll);
              if (_autoScroll && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            child: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
            ),
          ),
        ),
      ],
    );
  }
}
