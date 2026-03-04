enum MediaType { image, audio, video, unknown }

class MediaItem {
  final String path;
  final MediaType type;
  final String? caption;
  final String? downloadUrl;
  final int? step;

  const MediaItem({
    required this.path,
    required this.type,
    this.caption,
    this.downloadUrl,
    this.step,
  });

  static MediaType _inferType(String typeName) {
    switch (typeName) {
      case 'image-file': case 'images/separated': return MediaType.image;
      case 'audio-file': return MediaType.audio;
      case 'video-file': return MediaType.video;
      default: return MediaType.unknown;
    }
  }

  factory MediaItem.fromHistoryValue(Map<String, dynamic> data, int? step) {
    return MediaItem(
      path: data['path'] as String? ?? '',
      type: _inferType(data['_type'] as String? ?? ''),
      caption: data['caption'] as String?,
      step: step,
    );
  }

  MediaItem withDownloadUrl(String url) {
    return MediaItem(
      path: path,
      type: type,
      caption: caption,
      downloadUrl: url,
      step: step,
    );
  }
}
