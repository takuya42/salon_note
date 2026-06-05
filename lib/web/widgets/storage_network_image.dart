import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageNetworkImage extends StatelessWidget {
  const StorageNetworkImage({
    super.key,
    required this.imageUrl,
    required this.imagePath,
    required this.fit,
    required this.placeholder,
    required this.logPrefix,
  });

  final String imageUrl;
  final String imagePath;
  final BoxFit fit;
  final Widget placeholder;
  final String logPrefix;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    final pathFromField = _normalizeStoragePath(imagePath);
    final normalizedPath = pathFromField.isNotEmpty
        ? pathFromField
        : _normalizeStoragePath(normalizedUrl);

    debugPrint('$logPrefix STORAGE PATH => $normalizedPath');
    debugPrint('$logPrefix IMAGE URL => $normalizedUrl');

    if (normalizedPath.isEmpty) {
      return _NetworkImageWithFallback(
        imageUrl: normalizedUrl,
        fit: fit,
        placeholder: placeholder,
        logPrefix: logPrefix,
      );
    }

    return FutureBuilder<String>(
      future: _downloadUrl(normalizedPath, logPrefix),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder;
        }

        if (snapshot.hasError) {
          debugPrint('$logPrefix GET DOWNLOAD URL ERROR => ${snapshot.error}');
          return _NetworkImageWithFallback(
            imageUrl: normalizedUrl,
            fit: fit,
            placeholder: placeholder,
            logPrefix: logPrefix,
          );
        }

        return _NetworkImageWithFallback(
          imageUrl: snapshot.data ?? normalizedUrl,
          fit: fit,
          placeholder: placeholder,
          logPrefix: logPrefix,
        );
      },
    );
  }

  static Future<String> _downloadUrl(String imagePath, String logPrefix) async {
    final storage = FirebaseStorage.instance;
    final bucket = storage.ref().bucket;
    debugPrint('$logPrefix STORAGE BUCKET => $bucket');

    final ref = storage.ref(imagePath);
    debugPrint('$logPrefix STORAGE REF FULL PATH => ${ref.fullPath}');

    final downloadUrl = await ref.getDownloadURL();
    debugPrint('$logPrefix RESOLVED DOWNLOAD URL => $downloadUrl');

    return downloadUrl;
  }

  static String _normalizeStoragePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('http')) {
      return _pathFromDownloadUrl(trimmed);
    }

    if (!trimmed.startsWith('gs://')) {
      return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    }

    final withoutScheme = trimmed.substring(5);
    final firstSlash = withoutScheme.indexOf('/');
    if (firstSlash == -1 || firstSlash == withoutScheme.length - 1) {
      return '';
    }

    return withoutScheme.substring(firstSlash + 1);
  }

  static String _pathFromDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.host.contains('firebasestorage.googleapis.com')) {
      return '';
    }

    final segments = uri.pathSegments;
    final objectIndex = segments.indexOf('o');
    if (objectIndex == -1 || objectIndex == segments.length - 1) {
      return '';
    }

    return Uri.decodeComponent(segments[objectIndex + 1]);
  }
}

class _NetworkImageWithFallback extends StatelessWidget {
  const _NetworkImageWithFallback({
    required this.imageUrl,
    required this.fit,
    required this.placeholder,
    required this.logPrefix,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget placeholder;
  final String logPrefix;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      debugPrint('$logPrefix IMAGE EMPTY');
      return placeholder;
    }

    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, error, __) {
        debugPrint('$logPrefix IMAGE ERROR => $error');
        return placeholder;
      },
    );
  }
}
