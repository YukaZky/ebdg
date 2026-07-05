import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? searchAddress; 

  const MapPickerScreen({Key? key, this.initialLat, this.initialLng, this.searchAddress}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666); // Default jika gagal semua
  bool _isLoading = true;
  String _addressText = "Mencari lokasi...";
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
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

    // 1. Jika Mode Edit (sudah ada koordinat tersimpan dari database sebelumnya)
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
      await _getAddressFromLatLng(_currentPosition);
    } 
    // 2. PRIORITAS UTAMA (Standar E-Commerce): Lempar peta ke area yang dipilih dari Dropdown RajaOngkir
    else if (widget.searchAddress != null && widget.searchAddress!.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(widget.searchAddress!);
        if (locations.isNotEmpty) {
          _currentPosition = LatLng(locations.first.latitude, locations.first.longitude);
          await _getAddressFromLatLng(_currentPosition);
        } else {
          // Jika satelit gagal mengidentifikasi nama daerah, baru pakai GPS HP
          if (_hasLocationPermission) await _fetchCurrentLocation();
        }
      } catch (e) {
        debugPrint("Pencarian lokasi satelit dari dropdown gagal: $e");
        if (_hasLocationPermission) await _fetchCurrentLocation();
      }
    } 
    // 3. FALLBACK: Jika dropdown kosong sama sekali, baru gunakan murni GPS Device
    else if (_hasLocationPermission) {
      await _fetchCurrentLocation();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentPosition, 16.0);
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

  // Fungsi untuk tombol My Location
  void _goToDeviceLocation() async {
    setState(() => _addressText = "Mencari lokasi anda...");
    await _checkPermission();
    if (_hasLocationPermission) {
      await _fetchCurrentLocation();
      _mapController.move(_currentPosition, 16.0);
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
            // Mencegah munculnya koma berlebih jika ada data alamat yang kosong dari satelit
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
                    initialZoom: 16.0,
                    onPositionChanged: (camera, hasGesture) {
                      _currentPosition = camera.center ?? _currentPosition; 
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
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
                
                // Pin Peta Berada di Tengah Layar
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 35.0),
                    child: Icon(Icons.location_on, size: 50, color: Colors.red),
                  )
                ),

                // Tombol "My Location" untuk memusatkan kembali peta ke lokasi HP
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
                
                // Panel Konfirmasi Bawah
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12), 
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
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
                              child: Text("KONFIRMASI LOKASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}