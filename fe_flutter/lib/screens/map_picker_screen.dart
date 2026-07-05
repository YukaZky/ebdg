import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/map_geocoding_service.dart';

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
  final MapGeocodingService _geocodingService = MapGeocodingService();

  LatLng _currentPosition =
      const LatLng(-6.200000, 106.816666); // Default jika gagal semua
  bool _isLoading = true;
  bool _isSearching = false;
  bool _mapMovedByUser = false;
  String _addressText = "Mencari lokasi...";
  String? _accuracyMessage;
  MapLocationPrecision? _currentPrecision;
  bool _hasLocationPermission = false;
  int _reverseGeocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchAddress?.trim() ?? '';
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _geocodingService.close();
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

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
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
    } else if (widget.searchAddress != null &&
        widget.searchAddress!.isNotEmpty) {
      final results = await _geocodingService.search(
        widget.searchAddress!,
        context: widget.searchContext,
      );
      if (results.isNotEmpty) {
        final selected = results.first;
        _currentPosition = LatLng(selected.latitude, selected.longitude);
        _addressText = selected.displayName;
        _accuracyMessage = selected.accuracyMessage;
        _currentPrecision = selected.precision;
      } else if (_hasLocationPermission) {
        await _fetchCurrentLocation();
      }
    } else if (_hasLocationPermission) {
      await _fetchCurrentLocation();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_currentPosition, 17.0);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = LatLng(position.latitude, position.longitude);
      await _getAddressFromLatLng(_currentPosition);
    } catch (e) {
      debugPrint("Error mengambil GPS: $e");
    }
  }

  Color get _accuracyColor {
    switch (_currentPrecision) {
      case MapLocationPrecision.exact:
        return Colors.green.shade700;
      case MapLocationPrecision.street:
        return Colors.orange.shade800;
      case MapLocationPrecision.area:
      case null:
        return Colors.blueGrey.shade700;
    }
  }

  IconData get _accuracyIcon {
    switch (_currentPrecision) {
      case MapLocationPrecision.exact:
        return Icons.verified_rounded;
      case MapLocationPrecision.street:
        return Icons.alt_route_rounded;
      case MapLocationPrecision.area:
      case null:
        return Icons.info_outline_rounded;
    }
  }

  Future<MapSearchResult?> _showSearchResultPicker(
    List<MapSearchResult> results,
  ) async {
    if (results.length == 1 &&
        results.first.precision == MapLocationPrecision.exact) {
      return results.first;
    }

    return showModalBottomSheet<MapSearchResult>(
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
                  'Hasil dengan label "perkiraan" perlu diperiksa dan digeser ke bangunan yang benar.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.48),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined,
                            color: Color(0xFF0C2442)),
                        title: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.precisionLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: result.precision ==
                                          MapLocationPrecision.exact
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                              ),
                              Text(
                                '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
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
      _accuracyMessage = null;
      _currentPrecision = null;
    });

    try {
      final results = await _geocodingService.search(
        query,
        context: widget.searchContext,
      );
      if (results.isNotEmpty) {
        if (!mounted) return;
        final selectedResult = await _showSearchResultPicker(results);
        if (selectedResult == null || !mounted) return;

        final targetPosition = LatLng(
          selectedResult.latitude,
          selectedResult.longitude,
        );
        setState(() {
          _currentPosition = targetPosition;
          _addressText = selectedResult.displayName;
          _accuracyMessage = selectedResult.accuracyMessage;
          _currentPrecision = selectedResult.precision;
          _mapMovedByUser = false;
        });
        _mapController.move(
          targetPosition,
          selectedResult.precision == MapLocationPrecision.exact ? 19.0 : 17.5,
        );
        return;
      }

      // Fallback terakhir bila kedua sumber online tidak memberi hasil.
      final fallbackQuery = [
        MapGeocodingService.normalizeIndonesianAddress(query),
        MapGeocodingService.normalizeIndonesianAddress(
          widget.searchContext ?? '',
        ),
        'Indonesia',
      ].where((part) => part.isNotEmpty).join(', ');
      final locations = await locationFromAddress(fallbackQuery);
      if (locations.isEmpty) {
        if (mounted) {
          setState(() => _addressText =
              'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final targetPosition =
          LatLng(locations.first.latitude, locations.first.longitude);
      if (!mounted) return;

      setState(() {
        _currentPosition = targetPosition;
        _accuracyMessage =
            'Hasil ini masih berupa perkiraan dari perangkat. Geser pin ke bangunan yang benar.';
        _currentPrecision = MapLocationPrecision.area;
        _mapMovedByUser = false;
      });
      _mapController.move(targetPosition, 17.0);
      await _getAddressFromLatLng(targetPosition);
    } catch (e) {
      debugPrint('Pencarian lokasi gagal: $e');
      if (mounted) {
        setState(() => _addressText =
            'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Lokasi tidak ditemukan. Coba masukkan alamat lebih lengkap.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _goToDeviceLocation() async {
    setState(() {
      _addressText = "Mencari lokasi anda...";
      _accuracyMessage = null;
      _currentPrecision = null;
    });
    await _checkPermission();
    if (!mounted) return;
    if (_hasLocationPermission) {
      await _fetchCurrentLocation();
      if (!mounted) return;
      setState(() {
        _accuracyMessage =
            'Titik diambil dari GPS perangkat. Pastikan ujung pin tepat di bangunan tujuan.';
        _currentPrecision = null;
        _mapMovedByUser = false;
      });
      _mapController.move(_currentPosition, 17.0);
    } else {
      setState(() => _addressText = "Akses GPS/Lokasi HP belum diizinkan.");
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final requestId = ++_reverseGeocodeRequestId;
    try {
      final onlineAddress = await _geocodingService.reverse(
        position.latitude,
        position.longitude,
      );
      if (onlineAddress != null && onlineAddress.isNotEmpty) {
        if (mounted && requestId == _reverseGeocodeRequestId) {
          setState(() => _addressText = onlineAddress);
        }
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        if (mounted && requestId == _reverseGeocodeRequestId) {
          setState(() {
            String rawAddress =
                "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
            _addressText =
                rawAddress.replaceAll(RegExp(r',\s*,|,\s*$'), '').trim();
          });
        }
      }
    } catch (e) {
      if (mounted && requestId == _reverseGeocodeRequestId) {
        setState(() => _addressText =
            "Koordinat: ${position.latitude}, ${position.longitude}");
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
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF0C2442)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    borderSide:
                        const BorderSide(color: Color(0xFF0C2442), width: 1.4),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSearching ? null : _searchLocation,
                child: _isSearching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Cari',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('Pilih Lokasi',
            style: TextStyle(color: Colors.black87, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C2442)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 17.0,
                    onPositionChanged: (camera, hasGesture) {
                      _currentPosition = camera.center ?? _currentPosition;
                      if (hasGesture) _mapMovedByUser = true;
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        if (!_mapMovedByUser) return;
                        _mapMovedByUser = false;
                        setState(() {
                          _accuracyMessage =
                              'Pin telah digeser manual. Pastikan ujung pin tepat di bangunan tujuan.';
                          _currentPrecision = null;
                        });
                        _getAddressFromLatLng(_currentPosition);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                Center(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: const Offset(0, -25),
                      child: const Icon(
                        Icons.location_on,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: const Text(
                          'Geser peta agar ujung pin tepat di bangunan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C2442),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 285,
                  child: FloatingActionButton(
                    heroTag: "myLocationBtn",
                    backgroundColor: Colors.white,
                    onPressed: _goToDeviceLocation,
                    child:
                        const Icon(Icons.my_location, color: Color(0xFF0C2442)),
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Lokasi Terpilih:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(_addressText,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        if (_accuracyMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _accuracyColor.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _accuracyColor.withOpacity(0.24),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _accuracyIcon,
                                  size: 17,
                                  color: _accuracyColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _accuracyMessage!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: _accuracyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C2442),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
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
                                "PIN SUDAH TEPAT — SIMPAN",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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
