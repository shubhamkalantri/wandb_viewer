import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../models/media_item.dart';
import '../../../providers/run_detail_provider.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/error_view.dart';

/// Provider that parses media items from run files
final runMediaProvider = FutureProvider.family<List<MediaItem>, RunDetailParams>(
    (ref, params) async {
  final files = await ref.watch(runFilesProvider(params).future);
  final mediaFiles = <MediaItem>[];

  for (final file in files) {
    MediaType? type;
    if (_isImage(file.name)) {
      type = MediaType.image;
    } else if (_isAudio(file.name)) {
      type = MediaType.audio;
    } else if (_isVideo(file.name)) {
      type = MediaType.video;
    }
    if (type != null) {
      mediaFiles.add(MediaItem(
        path: file.name,
        type: type,
        downloadUrl: file.url,
      ));
    }
  }
  return mediaFiles;
});

bool _isSecureUrl(String? url) {
  if (url == null) return false;
  final uri = Uri.tryParse(url);
  return uri != null && uri.scheme == 'https';
}

bool _isImage(String name) =>
    name.endsWith('.png') ||
    name.endsWith('.jpg') ||
    name.endsWith('.jpeg') ||
    name.endsWith('.gif') ||
    name.endsWith('.bmp') ||
    name.endsWith('.webp');

bool _isAudio(String name) =>
    name.endsWith('.wav') ||
    name.endsWith('.mp3') ||
    name.endsWith('.flac') ||
    name.endsWith('.ogg');

bool _isVideo(String name) =>
    name.endsWith('.mp4') ||
    name.endsWith('.webm') ||
    name.endsWith('.avi') ||
    name.endsWith('.mov');

class MediaTab extends ConsumerWidget {
  final RunDetailParams params;
  const MediaTab({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(runMediaProvider(params));

    return mediaAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading media...'),
      error: (e, _) => ErrorView(
        message: 'Failed to load media. Check your connection and try again.',
        onRetry: () => ref.invalidate(runMediaProvider(params)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No media files found'));
        }

        final images = items.where((i) => i.type == MediaType.image).toList();
        final audio = items.where((i) => i.type == MediaType.audio).toList();
        final videos = items.where((i) => i.type == MediaType.video).toList();

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (images.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Images (${images.length})',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) => _ImageTile(
                  item: images[index],
                ),
              ),
            ],
            if (audio.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Audio (${audio.length})',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              ...audio.map((item) => _AudioTile(item: item)),
            ],
            if (videos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Videos (${videos.length})',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              ...videos.map((item) => _VideoTile(item: item)),
            ],
          ],
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final MediaItem item;
  const _ImageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!_isSecureUrl(item.downloadUrl)) {
      return const Card(child: Center(child: Icon(Icons.broken_image)));
    }

    return GestureDetector(
      onTap: () => _showFullscreen(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: item.downloadUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(item.path.split('/').last)),
        body: InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: item.downloadUrl!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ));
  }
}

class _AudioTile extends StatefulWidget {
  final MediaItem item;
  const _AudioTile({required this.item});

  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  late AudioPlayer _player;
  late StreamSubscription<PlayerState> _playerSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _playerSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_isSecureUrl(widget.item.downloadUrl)) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.idle ||
          _player.processingState == ProcessingState.completed) {
        await _player.setUrl(widget.item.downloadUrl!);
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 36),
        title: Text(widget.item.path.split('/').last),
        onTap: _isSecureUrl(widget.item.downloadUrl) ? _togglePlay : null,
      ),
    );
  }
}

class _VideoTile extends StatefulWidget {
  final MediaItem item;
  const _VideoTile({required this.item});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  Future<void> _initPlayer() async {
    if (!_isSecureUrl(widget.item.downloadUrl)) return;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.downloadUrl!),
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.videocam, size: 36),
            title: Text(widget.item.path.split('/').last),
            trailing: IconButton(
              icon: Icon(_initialized && _controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: () async {
                if (!_initialized) {
                  await _initPlayer();
                  if (!mounted || !_initialized || _controller == null) return;
                  _controller!.play();
                } else if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
                if (mounted) setState(() {});
              },
            ),
          ),
          if (_initialized && _controller != null)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
        ],
      ),
    );
  }
}
