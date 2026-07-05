import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? searchAddress;
  final String? searchContext;

  const MapPickerScreen({
    Key? key,
    this.initialLat,
    this.initialLng,
    this.searchAddress,
    this.searchContext,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentPosition = const LatLng(-6.200000, 106.816666); // Default jika gagal semua
  bool _isLoading = true;
  bool _isSearching = false;
  bool _skipNextReverseGeocode = false;
  String _addressText = "Mencari lokasi...";
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchAddress?.trim() ?? '';
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _hasLocationPermission = true;
      }
    } catch (e) {
      debugPrint("Izin lokasi error: $e");
    }
  }

  Future<void> _initializeMap() async {
    await _checkPermission();

    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
      await _getAddressFromLatLng(_currentPosition);
    } else if (widget.searchAddress != null && widget.searchAddress!.isNotEmpty) {
      final results = await _searchSmartLocations(widget.searchAddress!);
      if (results.isNotEmpty) {
        final selected = results.first;
        final position = _positionFromResult(selected);
        if (position != null) {
          _currentPosition = position;
          _addressText = _displayNameFromResult(selected);
        }
      } else if (_hasLocationPermission) {
        await _fetchCurrentLocation();
      }
    } else if (_hasLocationPermission) {
      await _fetchCurrentLocation();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentPosition, 17.0);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentPosition = LatLng(position.latitude, position.longitude);
      await _getAddressFromLatLng(_currentPosition);
    } catch (e) {
      debugPrint("Error mengambil GPS: $e");
    }
  }

  String _normalizeSearchText(String value) {
    var text = value.trim();
    text = text.replaceAll(RegExp(r'\bjl\.?\b', caseSensitive: false), 'Jalan');
    text = text.replaceAll(RegExp(r'\bjln\.?\b', caseSensitive: false), 'Jalan');
    text = text.replaceAll(RegExp(r'\bno\.?\b', caseSensitive: false), 'Nomor');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  List<String> _importantTokens(String value) {
    final stopWords = <String>{
      'jalan', 'nomor', 'no', 'jl', 'jln', 'rt', 'rw', 'gang', 'gg',
      'kecamatan', 'kabupaten', 'kota', 'provinsi', 'indonesia', 'jawa',
      'tengah', 'barat', 'timur', 'utara', 'selatan', 'daerah', 'khusus'
    };

    return _normalizeSearchText(value)
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty && !stopWords.contains(token) && (token.length > 2 || RegExp(r'^\d+$').hasMatch(token)))
        .toList();
  }

  String _joinUniqueAddressParts(List<String?> parts) {
    final seen = <String>{};
    final cleanParts = <String>[];

    for (final part in parts) {
      final clean = _normalizeSearchText(part ?? '');
      if (clean.isEmpty) continue;

      final key = clean.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      cleanParts.add(clean);
    }

    return cleanParts.join(', ');
  }

  String _smartSearchQuery(String rawQuery) {
    final context = _normalizeSearchText(widget.searchContext ?? widget.searchAddress ?? '');
    return _joinUniqueAddressParts([
      rawQuery,
      context,
      'Indonesia',
    ]);
  }

  double _scoreSearchResult(Map<String, dynamic> result, String rawQuery) {
    final displayName = _displayNameFromResult(result).toLowerCase();
    final address = result['address'] is Map ? result['address'] as Map : const {};
    double score = double.tryParse(result['importance']?.toString() ?? '') ?? 0;

    for (final token in _importantTokens(rawQuery)) {
      if (displayName.contains(token)) score += RegExp(r'^\d+$').hasMatch(token) ? 2.0 : 1.0;
    }

    final houseNumber = address['house_number']?.toString().toLowerCase() ?? '';
    final road = address['road']?.toString().toLowerCase() ?? '';
    for (final token in _importantTokens(rawQuery)) {
      if (houseNumber == token) score += 4.0;
      if (road.contains(token)) score += 3.0;
    }

    return score;
  }

  Future<List<Map<String, dynamic>>> _searchSmartLocations(String rawQuery) async {
    final smartQuery = _smartSearchQuery(rawQuery);
    var results = await _searchWithNominatim(smartQuery, rawQuery);

    if (results.isEmpty) {
      final backupQuery = _joinUniqueAddressParts([rawQuery, 'Indonesia']);
      if (backupQuery.toLowerCase() != smartQuery.toLowerCase()) {
        results = await _searchWithNominatim(backupQuery, rawQuery);
      }
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _searchWithNominatim(String query, String rawQuery) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '8',
        'addressdetails': '1',
        'countrycodes': 'id',
        'dedupe': '1',
      });

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'fe_flutter/1.0 map picker',
        },
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];

      final results = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => _positionFromResult(item) != null)
          .toList();

      results.sort((a, b) => _scoreSearchResult(b, rawQuery).compareTo(_scoreSearchResult(a, rawQuery)));
      return results;
    } catch (e) {
      debugPrint('Pencarian Nominatim gagal: $e');
      return [];
    }
  }

  LatLng? _positionFromResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  String _displayNameFromResult(Map<String, dynamic> result) {
    return result['display_name']?.toString() ?? 'Lokasi ditemukan';
  }

  Future<Map<String, dynamic>?> _showSearchResultPicker(List<Map<String, dynamic>> results) async {
    if (results.length == 1) return results.first;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih hasil lokasi paling sesuai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jika nomor rumah belum tepat, pilih area terdekat lalu geser pin manual sampai benar.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.48),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final position = _positionFromResult(result);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined, color: Color(0xFF0C2442)),
                        title: Text(
                          _displayNameFromResult(result),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: position == null
                            ? null
                            : Text(
                                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                        onTap: () => Navigator.pop(context, result),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama lokasi atau alamat terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _addressText = 'Mencari lokasi...';
    });

    try {
      final results = await _searchSmartLocations(query);
      Map<String, dynamic>? selectedResult;

      if (results.isNotEmpty && mounted) {
        selectedResult = await _showSearchResultPicker(results);
      }

      if (selectedResult != null) {
        final targetPosition = _positionFromResult(selectedResult);
        if (targetPosition == null) return;

        if (!mounted) return;
        setState(() {
          _currentPosition = targetPosition;
          _addressText = _displayNameFromResult(selectedResult!);
          _skipNextReverseGeocode = true;
        });
        _mapController.move(targetPosition, 18.0);
        return;
      }

      // Fallback terakhir untuk device geocoder jika Nominatim tidak memberi hasil.
      final fallbackQuery = _smartSearchQuery(query);
      final locations = await locationFromAddress(fallbackQuery);
      if (locations.isEmpty) {
        if (mounted) {
          setState(() => _addressText = 'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final targetPosition = LatLng(locations.first.latitude, locations.first.longitude);
      if (!mounted) return;

      setState(() => _currentPosition = targetPosition);
      _mapController.move(targetPosition, 17.0);
      await _getAddressFromLatLng(targetPosition);
    } catch (e) {
      debugPrint('Pencarian lokasi gagal: $e');
      if (mounted) {
        setState(() => _addressText = 'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _goToDeviceLocation() async {
    setState(() => _addressText = "Mencari lokasi anda...");
    await _checkPermission();
    if (_hasLocationPermission) {
      await _fetchCurrentLocation();
      _mapController.move(_currentPosition, 17.0);
      setState(() {});
    } else {
      setState(() => _addressText = "Akses GPS/Lokasi HP belum diizinkan.");
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            String rawAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
            _addressText = rawAddress.replaceAll(RegExp(r',\s*,|,\s*$'), '').trim();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addressText = "Koordinat: ${position.latitude}, ${position.longitude}");
      }
    }
  }

  Widget _buildSearchBox() {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _isSearching ? null : _searchLocation(),
                decoration: InputDecoration(
                  hintText: 'Contoh: Jl Kisoreng No 43 Blora',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0C2442)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0C2442), width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C2442),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSearching ? null : _searchLocation,
                child: _isSearching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Cari', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi', style: TextStyle(color: Colors.black87, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C2442)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 17.0,
                    onPositionChanged: (camera, hasGesture) {
                      _currentPosition = camera.center ?? _currentPosition;
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        if (_skipNextReverseGeocode) {
                          _skipNextReverseGeocode = false;
                          return;
                        }
                        _getAddressFromLatLng(_currentPosition);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fe_flutter',
                    ),
                  ],
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildSearchBox(),
                ),

                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35.0),
                    child: Icon(Icons.location_on, size: 50, color: Colors.red),
                  ),
                ),

                Positioned(
                  right: 20,
                  bottom: 220,
                  child: FloatingActionButton(
                    heroTag: "myLocationBtn",
                    backgroundColor: Colors.white,
                    onPressed: _goToDeviceLocation,
                    child: const Icon(Icons.my_location, color: Color(0xFF0C2442)),
                  ),
                ),

                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Lokasi Terpilih:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(_addressText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C2442),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pop(context, {
                                'latitude': _currentPosition.latitude,
                                'longitude': _currentPosition.longitude,
                                'addressText': _addressText,
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child: Text(
                                "TETAPKAN SEBAGAI MAP ANDA",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
