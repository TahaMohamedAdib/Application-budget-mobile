typedef StorageSignedUrlCreator = Future<String> Function(
  String bucket,
  String objectPath,
  int expiresInSeconds,
);

typedef StorageUserIdProvider = String? Function();
typedef StorageBaseUrlProvider = String? Function();
typedef StorageClock = DateTime Function();

class StorageObjectReference {
  const StorageObjectReference({
    required this.bucket,
    required this.objectPath,
  });

  final String bucket;
  final String objectPath;

  String get cacheKey => '$bucket/$objectPath';
}

class StorageReferenceParser {
  static const Set<String> supportedBuckets = {'receipts', 'logos'};

  static StorageObjectReference? parse(
    String stored, {
    String? supabaseUrl,
  }) {
    final value = stored.trim();
    if (value.isEmpty) return null;

    final direct = _parseStoredPath(value);
    if (direct != null) return direct;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (!_matchesSupabaseOrigin(uri, supabaseUrl)) return null;
    if (_hasUnsafeEncodedPathSegment(value)) return null;

    final segments = uri.pathSegments;
    if (segments.length >= 6 &&
        segments[0] == 'storage' &&
        segments[1] == 'v1' &&
        segments[2] == 'object' &&
        const {'public', 'sign', 'authenticated'}.contains(segments[3])) {
      return _fromSegments(segments, bucketIndex: 4);
    }

    if (segments.length >= 7 &&
        segments[0] == 'storage' &&
        segments[1] == 'v1' &&
        segments[2] == 'render' &&
        segments[3] == 'image' &&
        const {'public', 'sign', 'authenticated'}.contains(segments[4])) {
      return _fromSegments(segments, bucketIndex: 5);
    }

    return null;
  }

  static bool isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static StorageObjectReference? _parseStoredPath(String value) {
    if (value.contains(r'\')) return null;

    final segments = value.split('/');
    if (segments.length < 2 || !supportedBuckets.contains(segments.first)) {
      return null;
    }

    return _fromSegments(segments, bucketIndex: 0);
  }

  static StorageObjectReference? _fromSegments(
    List<String> segments, {
    required int bucketIndex,
  }) {
    if (segments.length <= bucketIndex + 1) return null;

    final bucket = segments[bucketIndex];
    if (!supportedBuckets.contains(bucket)) return null;

    final objectSegments = segments.sublist(bucketIndex + 1);
    if (objectSegments.any(_isUnsafeObjectSegment)) {
      return null;
    }

    return StorageObjectReference(
      bucket: bucket,
      objectPath: objectSegments.join('/'),
    );
  }

  static bool _isUnsafeObjectSegment(String segment) {
    if (segment.isEmpty || segment == '.' || segment == '..') return true;

    try {
      final decoded = Uri.decodeComponent(segment);
      return decoded == '.' ||
          decoded == '..' ||
          decoded.contains('/') ||
          decoded.contains(r'\');
    } on FormatException {
      return true;
    }
  }

  static bool _hasUnsafeEncodedPathSegment(String rawUrl) {
    final authorityStart = rawUrl.indexOf('://');
    if (authorityStart < 0) return false;

    final pathStart = rawUrl.indexOf('/', authorityStart + 3);
    if (pathStart < 0) return false;

    final queryStart = rawUrl.indexOf('?', pathStart);
    final fragmentStart = rawUrl.indexOf('#', pathStart);
    final endCandidates = <int>[
      if (queryStart >= 0) queryStart,
      if (fragmentStart >= 0) fragmentStart,
    ];
    final pathEnd = endCandidates.isEmpty
        ? rawUrl.length
        : endCandidates.reduce((left, right) => left < right ? left : right);

    for (final segment in rawUrl.substring(pathStart, pathEnd).split('/')) {
      if (segment.isEmpty) continue;
      try {
        final decoded = Uri.decodeComponent(segment);
        if (decoded == '.' ||
            decoded == '..' ||
            decoded.contains('/') ||
            decoded.contains(r'\')) {
          return true;
        }
      } on FormatException {
        return true;
      }
    }
    return false;
  }

  static bool _matchesSupabaseOrigin(Uri uri, String? supabaseUrl) {
    final configured = Uri.tryParse(supabaseUrl?.trim() ?? '');
    if (configured != null && configured.hasAuthority) {
      return uri.scheme == configured.scheme &&
          uri.host.toLowerCase() == configured.host.toLowerCase() &&
          uri.port == configured.port;
    }

    return uri.host.toLowerCase().endsWith('.supabase.co');
  }
}

class StorageUrlResolver {
  StorageUrlResolver({
    required StorageSignedUrlCreator createSignedUrl,
    required StorageUserIdProvider currentUserId,
    StorageBaseUrlProvider? supabaseUrl,
    StorageClock? now,
    this.refreshMargin = const Duration(minutes: 1),
  })  : _createSignedUrl = createSignedUrl,
        _currentUserId = currentUserId,
        _supabaseUrl = supabaseUrl ?? (() => null),
        _now = now ?? DateTime.now;

  final StorageSignedUrlCreator _createSignedUrl;
  final StorageUserIdProvider _currentUserId;
  final StorageBaseUrlProvider _supabaseUrl;
  final StorageClock _now;
  final Duration refreshMargin;

  final Map<String, _SignedUrlCacheEntry> _cache = {};
  final Map<String, Future<String>> _inFlight = {};
  String? _cacheUserId;
  bool _hasObservedUser = false;
  int _cacheGeneration = 0;

  Future<String> resolve(
    String stored, {
    int expiresInSeconds = 3600,
  }) {
    if (expiresInSeconds <= 0) {
      throw ArgumentError.value(
        expiresInSeconds,
        'expiresInSeconds',
        'must be greater than zero',
      );
    }

    _purgeForUserChange();

    final reference = StorageReferenceParser.parse(
      stored,
      supabaseUrl: _supabaseUrl(),
    );
    if (reference == null) return Future<String>.value(stored);

    final generation = _cacheGeneration;
    final userCacheKey = _cacheUserId ?? '<anonymous>';
    final key = '$userCacheKey|${reference.cacheKey}|$expiresInSeconds';
    final now = _now();
    final cached = _cache[key];
    if (cached != null && now.isBefore(cached.refreshAt)) {
      return Future<String>.value(cached.url);
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _signAndCache(
      reference,
      key,
      expiresInSeconds,
      now,
      generation,
    );
    _inFlight[key] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    });
  }

  void clear() {
    _cacheGeneration++;
    _cache.clear();
    _inFlight.clear();
  }

  Future<String> _signAndCache(
    StorageObjectReference reference,
    String key,
    int expiresInSeconds,
    DateTime signedAt,
    int generation,
  ) async {
    final signedUrl = await _createSignedUrl(
      reference.bucket,
      reference.objectPath,
      expiresInSeconds,
    );
    if (signedUrl.isEmpty) {
      throw StateError('Supabase returned an empty signed Storage URL.');
    }

    final requestedLifetime = Duration(seconds: expiresInSeconds);
    final proportionalMargin = Duration(
      seconds: (expiresInSeconds ~/ 10).clamp(1, expiresInSeconds).toInt(),
    );
    final effectiveMargin =
        refreshMargin < proportionalMargin ? refreshMargin : proportionalMargin;
    final refreshAt = signedAt.add(requestedLifetime - effectiveMargin);

    if (generation == _cacheGeneration) {
      _cache[key] = _SignedUrlCacheEntry(
        url: signedUrl,
        refreshAt: refreshAt,
      );
    }
    return signedUrl;
  }

  void _purgeForUserChange() {
    final userId = _currentUserId();
    if (_hasObservedUser && userId != _cacheUserId) {
      clear();
    }
    _cacheUserId = userId;
    _hasObservedUser = true;
  }
}

class _SignedUrlCacheEntry {
  const _SignedUrlCacheEntry({
    required this.url,
    required this.refreshAt,
  });

  final String url;
  final DateTime refreshAt;
}
