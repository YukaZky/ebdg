import 'dart:convert';

import 'package:fe_flutter/services/map_geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MapGeocodingService', () {
    test('normalizes common Indonesian address abbreviations', () {
      expect(
        MapGeocodingService.normalizeIndonesianAddress(
          '  JL. kisoreng no. 43   blora ',
        ),
        'Jalan kisoreng No 43 blora',
      );
      expect(
        MapGeocodingService.extractHouseNumber(
          'Jl Kisoreng Nomor 43 Blora',
        ),
        '43',
      );
      expect(
        MapGeocodingService.extractStreetName(
          'Jl Kisoreng No 43 Blora',
        ),
        'Kisoreng',
      );
    });

    test('ranks Jalan Kisoreng above an unrelated exact house number',
        () async {
      late Uri arcGisRequest;
      final client = MockClient((request) async {
        if (request.url.host == 'geocode.arcgis.com') {
          arcGisRequest = request.url;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'address': 'Jalan Kisoreng, Kota Blora, Jawa Tengah, 58219',
                  'score': 87.65,
                  'location': {
                    'x': 111.429262962819,
                    'y': -6.960835240187,
                  },
                  'attributes': {
                    'Match_addr':
                        'Jalan Kisoreng, Kota Blora, Jawa Tengah, 58219',
                    'Addr_type': 'StreetName',
                    'AddNum': '',
                    'Address': 'Jalan Kisoreng',
                    'StAddr': 'Jalan Kisoreng',
                    'City': 'Kota Blora',
                    'Subregion': 'Blora',
                    'Region': 'Jawa Tengah',
                    'Postal': '58219',
                    'Country': 'IDN',
                  },
                },
                {
                  'address':
                      'Jalan Pemuda 43, Tempelan, Kota Blora, Jawa Tengah',
                  'score': 99,
                  'location': {
                    'x': 111.4079,
                    'y': -6.9700,
                  },
                  'attributes': {
                    'Match_addr':
                        'Jalan Pemuda 43, Tempelan, Kota Blora, Jawa Tengah',
                    'Addr_type': 'PointAddress',
                    'AddNum': '43',
                    'Address': 'Jalan Pemuda',
                    'StAddr': 'Jalan Pemuda 43',
                    'City': 'Kota Blora',
                    'Subregion': 'Blora',
                    'Region': 'Jawa Tengah',
                    'Postal': '58211',
                    'Country': 'IDN',
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      final service = MapGeocodingService(client: client);
      addTearDown(service.close);

      final results = await service.search(
        'Jl Kisoreng No 43 Blora',
        context: 'Karangjati, Kota Blora, Jawa Tengah',
      );

      expect(
        arcGisRequest.queryParameters['SingleLine'],
        contains('Jalan Kisoreng No 43 Blora'),
      );
      expect(results, hasLength(1));
      expect(results.first.displayName, contains('Jalan Kisoreng'));
      expect(results.first.latitude, closeTo(-6.960835240187, 0.0000001));
      expect(results.first.longitude, closeTo(111.429262962819, 0.0000001));
      expect(results.first.precision, MapLocationPrecision.street);
      expect(results.first.accuracyMessage, contains('nomor 43'));
    });

    test('prefers an exact matching house when the provider has it', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'geocode.arcgis.com') {
          return http.Response(
            jsonEncode({
              'candidates': [
                _arcGisCandidate(
                  address: 'Jalan Kisoreng, Kota Blora, Jawa Tengah',
                  score: 98,
                  type: 'StreetName',
                  houseNumber: '',
                  latitude: -6.9608,
                  longitude: 111.4292,
                ),
                _arcGisCandidate(
                  address:
                      'Jalan Kisoreng 43, Karangjati, Kota Blora, Jawa Tengah',
                  score: 92,
                  type: 'PointAddress',
                  houseNumber: '43',
                  latitude: -6.9611,
                  longitude: 111.4295,
                ),
              ],
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      final service = MapGeocodingService(client: client);
      addTearDown(service.close);

      final results = await service.search('Jl Kisoreng No 43 Blora');

      expect(results.first.houseNumber, '43');
      expect(results.first.precision, MapLocationPrecision.exact);
      expect(results.first.accuracyMessage, contains('berhasil dicocokkan'));
    });

    test('uses the richer online address for reverse geocoding', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'geocode.arcgis.com');
        expect(request.url.path, endsWith('/reverseGeocode'));
        return http.Response(
          jsonEncode({
            'address': {
              'Match_addr': 'Jalan Kisoreng, Kota Blora, Jawa Tengah, 58219',
              'LongLabel':
                  'Jalan Kisoreng, Karangjati, Kota Blora, Jawa Tengah, 58219, IDN',
            },
          }),
          200,
        );
      });
      final service = MapGeocodingService(client: client);
      addTearDown(service.close);

      final address = await service.reverse(-6.960835, 111.429263);

      expect(address, startsWith('Jalan Kisoreng'));
      expect(address, contains('Karangjati'));
    });
  });
}

Map<String, dynamic> _arcGisCandidate({
  required String address,
  required double score,
  required String type,
  required String houseNumber,
  required double latitude,
  required double longitude,
}) {
  return {
    'address': address,
    'score': score,
    'location': {
      'x': longitude,
      'y': latitude,
    },
    'attributes': {
      'Match_addr': address,
      'Addr_type': type,
      'AddNum': houseNumber,
      'Address': 'Jalan Kisoreng',
      'StAddr': houseNumber.isEmpty
          ? 'Jalan Kisoreng'
          : 'Jalan Kisoreng $houseNumber',
      'City': 'Kota Blora',
      'Subregion': 'Blora',
      'Region': 'Jawa Tengah',
      'Postal': '58219',
      'Country': 'IDN',
    },
  };
}
