import 'dart:convert';

import 'package:http/http.dart' as http;

enum MapLocationPrecision {
  exact,
  street,
  area,
}

class MapSearchResult {
  const MapSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.provider,
    required this.precision,
    required this.providerConfidence,
    this.street = '',
    this.houseNumber = '',
    this.locality = '',
    this.region = '',
    this.requestedHouseNumber,
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final String provider;
  final MapLocationPrecision precision;
  final double providerConfidence;
  final String street;
  final String houseNumber;
  final String locality;
  final String region;
  final String? requestedHouseNumber;

  String get precisionLabel {
    switch (precision) {
      case MapLocationPrecision.exact:
        return 'Alamat tepat';
      case MapLocationPrecision.street:
        return 'Perkiraan di jalan';
      case MapLocationPrecision.area:
        return 'Perkiraan area';
    }
  }

  String get accuracyMessage {
    switch (precision) {
      case MapLocationPrecision.exact:
        return 'Alamat dan nomor bangunan berhasil dicocokkan.';
      case MapLocationPrecision.street:
        final number = requestedHouseNumber;
        if (number != null && number.isNotEmpty) {
          return 'Jalan ditemukan, tetapi nomor $number belum tersedia di data peta. Geser pin ke bangunan yang benar.';
        }
        return 'Jalan ditemukan. Periksa posisi pin lalu geser bila perlu.';
      case MapLocationPrecision.area:
        return 'Baru area terdekat yang ditemukan. Geser pin ke lokasi yang benar sebelum menyimpan.';
    }
  }
}

class MapGeocodingService {
  MapGeocodingService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const _arcGisHost = 'geocode.arcgis.com';
  static const _arcGisPath = '/arcgis/rest/services/World/GeocodeServer';
  static const _nominatimHost = 'nominatim.openstreetmap.org';

  final http.Client _client;
  final bool _ownsClient;
  final Map<String, Future<List<MapSearchResult>>> _searchCache = {};
  final Map<String, Future<String?>> _reverseCache = {};

  static String normalizeIndonesianAddress(String value) {
    var text = value.trim();
    text = text.replaceAll(
      RegExp(r'\bjl\.?(?=\s|$)', caseSensitive: false),
      'Jalan',
    );
    text = text.replaceAll(
      RegExp(r'\bjln\.?(?=\s|$)', caseSensitive: false),
      'Jalan',
    );
    text = text.replaceAll(
      RegExp(r'\bnomor\b|\bno\.?(?=\s*\d)', caseSensitive: false),
      'No',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  static String? extractHouseNumber(String value) {
    final normalized = normalizeIndonesianAddress(value);
    final explicit = RegExp(
      r'\bNo\s*(\d+[a-z]?(?:[-/]\d+[a-z]?)?)\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    return explicit?.group(1)?.toLowerCase();
  }

  static String? extractStreetName(String value) {
    final normalized = normalizeIndonesianAddress(value);
    final match = RegExp(
      r'\bJalan\s+(.+?)(?=\s+No\s*\d|,\s*|$)',
      caseSensitive: false,
    ).firstMatch(normalized);
    return match?.group(1)?.trim();
  }

  Future<List<MapSearchResult>> search(
    String rawQuery, {
    String? context,
  }) {
    final query = _joinAddressParts([
      normalizeIndonesianAddress(rawQuery),
      normalizeIndonesianAddress(context ?? ''),
      'Indonesia',
    ]);
    final cacheKey = query.toLowerCase();

    return _searchCache.putIfAbsent(
      cacheKey,
      () => _searchUncached(query, rawQuery),
    );
  }

  Future<List<MapSearchResult>> _searchUncached(
    String query,
    String rawQuery,
  ) async {
    final providerResults = await Future.wait([
      _searchArcGis(query, rawQuery),
      _searchNominatim(query, rawQuery),
    ]);

    final deduplicated = <MapSearchResult>[];
    for (final result in providerResults.expand((items) => items)) {
      if (!_isRelevant(result, rawQuery)) continue;
      final duplicateIndex = deduplicated.indexWhere(
        (existing) => _isSameLocation(existing, result),
      );
      if (duplicateIndex < 0) {
        deduplicated.add(result);
      } else if (_score(result, rawQuery) >
          _score(deduplicated[duplicateIndex], rawQuery)) {
        deduplicated[duplicateIndex] = result;
      }
    }

    deduplicated.sort(
      (a, b) => _score(b, rawQuery).compareTo(_score(a, rawQuery)),
    );
    return List.unmodifiable(deduplicated.take(10));
  }

  Future<List<MapSearchResult>> _searchArcGis(
    String query,
    String rawQuery,
  ) async {
    try {
      final uri = Uri.https(
        _arcGisHost,
        '$_arcGisPath/findAddressCandidates',
        {
          'SingleLine': query,
          'f': 'json',
          'countryCode': 'IDN',
          'maxLocations': '8',
          'outFields':
              'Match_addr,Addr_type,AddNum,Address,StAddr,City,Subregion,Region,Postal,Country',
        },
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['candidates'] is! List) {
        return const [];
      }

      final requestedHouseNumber = extractHouseNumber(rawQuery);
      final results = <MapSearchResult>[];
      for (final candidate in decoded['candidates'] as List) {
        if (candidate is! Map || candidate['location'] is! Map) continue;

        final location = candidate['location'] as Map;
        final attributes = candidate['attributes'] is Map
            ? candidate['attributes'] as Map
            : {};
        final latitude = _toDouble(location['y']);
        final longitude = _toDouble(location['x']);
        if (latitude == null || longitude == null) continue;

        final houseNumber = _firstNonEmpty([
          attributes['AddNum'],
        ]);
        final street = _firstNonEmpty([
          attributes['StAddr'],
          attributes['Address'],
        ]);
        final addressType = attributes['Addr_type']?.toString() ?? '';

        results.add(
          MapSearchResult(
            latitude: latitude,
            longitude: longitude,
            displayName: _firstNonEmpty([
              candidate['address'],
              attributes['Match_addr'],
            ], fallback: 'Lokasi ditemukan'),
            provider: 'ArcGIS',
            precision: _arcGisPrecision(
              addressType,
              requestedHouseNumber,
              houseNumber,
              street,
            ),
            providerConfidence:
                (_toDouble(candidate['score']) ?? 0).clamp(0, 100) / 100,
            street: street,
            houseNumber: houseNumber,
            locality: _firstNonEmpty([
              attributes['City'],
              attributes['Subregion'],
            ]),
            region: attributes['Region']?.toString() ?? '',
            requestedHouseNumber: requestedHouseNumber,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<List<MapSearchResult>> _searchNominatim(
    String query,
    String rawQuery,
  ) async {
    try {
      final uri = Uri.https(_nominatimHost, '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '8',
        'addressdetails': '1',
        'countrycodes': 'id',
        'dedupe': '1',
        'accept-language': 'id',
      });
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'GeoDesaConnect/1.0 map-picker',
        },
      );
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) return const [];

      final requestedHouseNumber = extractHouseNumber(rawQuery);
      final results = <MapSearchResult>[];
      for (final item in decoded) {
        if (item is! Map) continue;

        final latitude = _toDouble(item['lat']);
        final longitude = _toDouble(item['lon']);
        if (latitude == null || longitude == null) continue;

        final address = item['address'] is Map ? item['address'] as Map : {};
        final houseNumber = address['house_number']?.toString() ?? '';
        final street = _firstNonEmpty([
          address['road'],
          address['pedestrian'],
          address['residential'],
        ]);
        final type = item['type']?.toString() ?? '';
        final category = item['category']?.toString() ?? '';

        results.add(
          MapSearchResult(
            latitude: latitude,
            longitude: longitude,
            displayName: item['display_name']?.toString() ?? 'Lokasi ditemukan',
            provider: 'OpenStreetMap',
            precision: _nominatimPrecision(
              type,
              category,
              requestedHouseNumber,
              houseNumber,
              street,
            ),
            providerConfidence:
                (_toDouble(item['importance']) ?? 0).clamp(0, 1),
            street: street,
            houseNumber: houseNumber,
            locality: _firstNonEmpty([
              address['city'],
              address['town'],
              address['village'],
              address['municipality'],
            ]),
            region: address['state']?.toString() ?? '',
            requestedHouseNumber: requestedHouseNumber,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<String?> reverse(double latitude, double longitude) {
    final cacheKey =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    return _reverseCache.putIfAbsent(
      cacheKey,
      () => _reverseUncached(latitude, longitude),
    );
  }

  Future<String?> _reverseUncached(
    double latitude,
    double longitude,
  ) async {
    final arcGisResult = await _reverseArcGis(latitude, longitude);
    if (arcGisResult != null && arcGisResult.isNotEmpty) {
      return arcGisResult;
    }
    return _reverseNominatim(latitude, longitude);
  }

  Future<String?> _reverseArcGis(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https(
        _arcGisHost,
        '$_arcGisPath/reverseGeocode',
        {
          'location': '$longitude,$latitude',
          'f': 'json',
          'langCode': 'id',
          'distance': '100',
          'outSR': '4326',
        },
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['address'] is! Map) return null;

      final address = decoded['address'] as Map;
      return _firstNonEmpty([
        address['LongLabel'],
        address['Match_addr'],
      ], fallback: '');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseNominatim(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https(_nominatimHost, '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'id',
      });
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'GeoDesaConnect/1.0 map-picker',
        },
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;
      return decoded['display_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  static MapLocationPrecision _arcGisPrecision(
    String addressType,
    String? requestedHouseNumber,
    String houseNumber,
    String street,
  ) {
    final exactTypes = {
      'PointAddress',
      'Subaddress',
      'StreetAddress',
      'DistanceMarker',
    };
    final normalizedRequested = requestedHouseNumber?.toLowerCase();
    final normalizedFound = houseNumber.toLowerCase();

    if (requestedHouseNumber != null) {
      if (normalizedFound == normalizedRequested &&
          exactTypes.contains(addressType)) {
        return MapLocationPrecision.exact;
      }
      return street.isNotEmpty
          ? MapLocationPrecision.street
          : MapLocationPrecision.area;
    }

    if (exactTypes.contains(addressType) || addressType == 'POI') {
      return MapLocationPrecision.exact;
    }
    if (street.isNotEmpty ||
        addressType == 'StreetName' ||
        addressType == 'StreetMidBlock') {
      return MapLocationPrecision.street;
    }
    return MapLocationPrecision.area;
  }

  static MapLocationPrecision _nominatimPrecision(
    String type,
    String category,
    String? requestedHouseNumber,
    String houseNumber,
    String street,
  ) {
    if (requestedHouseNumber != null) {
      if (houseNumber.toLowerCase() == requestedHouseNumber.toLowerCase()) {
        return MapLocationPrecision.exact;
      }
      return street.isNotEmpty
          ? MapLocationPrecision.street
          : MapLocationPrecision.area;
    }

    const exactTypes = {
      'house',
      'building',
      'commercial',
      'retail',
      'office',
      'shop',
      'amenity',
      'tourism',
    };
    if (houseNumber.isNotEmpty ||
        exactTypes.contains(type) ||
        exactTypes.contains(category)) {
      return MapLocationPrecision.exact;
    }
    return street.isNotEmpty
        ? MapLocationPrecision.street
        : MapLocationPrecision.area;
  }

  static double _score(MapSearchResult result, String rawQuery) {
    var score = result.providerConfidence * 4;
    switch (result.precision) {
      case MapLocationPrecision.exact:
        score += 4;
      case MapLocationPrecision.street:
        score += 2;
      case MapLocationPrecision.area:
        break;
    }

    final searchable = _fold(
      '${result.displayName} ${result.street} ${result.locality} ${result.region}',
    );
    final tokens = _importantTokens(rawQuery)
        .where((token) => !RegExp(r'^\d').hasMatch(token))
        .toList();
    final matchedTokens =
        tokens.where((token) => searchable.contains(token)).length;
    score += matchedTokens * 1.5;
    if (tokens.isNotEmpty && matchedTokens == 0) score -= 6;

    final streetName = extractStreetName(rawQuery);
    final streetTokens = _importantTokens(streetName ?? '');
    if (streetTokens.isNotEmpty) {
      final foldedStreet = _fold('${result.street} ${result.displayName}');
      final roadMatches =
          streetTokens.where((token) => foldedStreet.contains(token)).length;
      if (roadMatches == streetTokens.length) {
        score += 4;
      } else if (roadMatches == 0) {
        score -= 8;
      }
    }

    final requestedHouseNumber = extractHouseNumber(rawQuery);
    if (requestedHouseNumber != null) {
      if (result.houseNumber.toLowerCase() ==
          requestedHouseNumber.toLowerCase()) {
        score += 6;
      } else if (result.houseNumber.isNotEmpty) {
        score -= 5;
      } else {
        score -= 1;
      }
    }

    return score;
  }

  static bool _isRelevant(MapSearchResult result, String rawQuery) {
    final searchable = _fold(
      '${result.displayName} ${result.street} ${result.locality} ${result.region}',
    );
    final streetTokens = _importantTokens(extractStreetName(rawQuery) ?? '');
    if (streetTokens.isNotEmpty) {
      return streetTokens.any(searchable.contains);
    }

    final tokens = _importantTokens(rawQuery)
        .where((token) => !RegExp(r'^\d').hasMatch(token))
        .toList();
    return tokens.isEmpty || tokens.any(searchable.contains);
  }

  static List<String> _importantTokens(String value) {
    const stopWords = {
      'jalan',
      'nomor',
      'no',
      'jl',
      'jln',
      'rt',
      'rw',
      'gang',
      'gg',
      'kecamatan',
      'kabupaten',
      'kota',
      'provinsi',
      'indonesia',
      'jawa',
      'tengah',
      'barat',
      'timur',
      'utara',
      'selatan',
      'daerah',
      'khusus',
    };
    return _fold(normalizeIndonesianAddress(value))
        .split(RegExp(r'[^a-z0-9]+'))
        .where(
          (token) =>
              token.isNotEmpty &&
              !stopWords.contains(token) &&
              (token.length > 2 || RegExp(r'^\d+$').hasMatch(token)),
        )
        .toList();
  }

  static String _joinAddressParts(List<String> parts) {
    final result = <String>[];
    for (final part in parts) {
      final clean = normalizeIndonesianAddress(part);
      if (clean.isEmpty) continue;
      final folded = _fold(clean);
      if (result.any((existing) {
        final foldedExisting = _fold(existing);
        return foldedExisting == folded || foldedExisting.contains(folded);
      })) {
        continue;
      }
      result.add(clean);
    }
    return result.join(', ');
  }

  static bool _isSameLocation(
    MapSearchResult first,
    MapSearchResult second,
  ) {
    if (_fold(first.displayName) == _fold(second.displayName)) return true;
    return (first.latitude - second.latitude).abs() < 0.00025 &&
        (first.longitude - second.longitude).abs() < 0.00025;
  }

  static String _fold(String value) => value.toLowerCase();

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _firstNonEmpty(
    List<dynamic> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
