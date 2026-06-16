import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? searchAddress; // Parameter pencarian alamat pintar

  const MapPickerScreen({Key? key, this.initialLat, this.initialLng, this.searchAddress}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666); // Default: Jakarta
  bool _isLoading = true;
  String _addressText = "Mencari lokasi...";

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // 1. Jika Mode Edit (sudah ada koordinat lama)
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
      await _getAddressFromLatLng(_currentPosition);
    } 
    // 2. SISTEM PINTAR: Cari koordinat berdasarkan ketikan/pilihan alamat user
    else if (widget.searchAddress != null && widget.searchAddress!.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(widget.searchAddress!);
        if (locations.isNotEmpty) {
          _currentPosition = LatLng(locations.first.latitude, locations.first.longitude);
          await _getAddressFromLatLng(_currentPosition);
        } else {
          await _getCurrentGPSLocation();
        }
      } catch (e) {
        debugPrint("Gagal konversi alamat ke peta: $e");
        await _getCurrentGPSLocation();
      }
    } 
    // 3. Jika tidak ada patokan, gunakan GPS HP
    else {
      await _getCurrentGPSLocation();
    }

    setState(() => _isLoading = false);
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 16));
    }
  }

  Future<void> _getCurrentGPSLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentPosition = LatLng(position.latitude, position.longitude);
    await _getAddressFromLatLng(_currentPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressText = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
        });
      }
    } catch (e) {
      setState(() => _addressText = "Koordinat: ${position.latitude}, ${position.longitude}");
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
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 16),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                     _mapController = controller;
                     _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 16));
                  },
                  onCameraMove: (position) => _currentPosition = position.target,
                  onCameraIdle: () => _getAddressFromLatLng(_currentPosition),
                ),
                // Pin Peta
                const Center(child: Padding(
                  padding: EdgeInsets.only(bottom: 35.0),
                  child: Icon(Icons.location_on, size: 50, color: Colors.red),
                )),
                
                // Panel Konfirmasi
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C2442), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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