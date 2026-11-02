import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'shipping.dart';

/// Erreur de localisation, affichable telle quelle
class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}

/// Adresse retrouvée à partir de coordonnées GPS
class PlaceInfo {
  final String? governorate;
  final String? city;
  final String? street;
  final String? postalCode;
  const PlaceInfo({this.governorate, this.city, this.street, this.postalCode});
}

/// Position actuelle, après vérification du GPS et de la permission
Future<Position> getCurrentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw LocationException('Activez la localisation (GPS) de votre appareil.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw LocationException('Permission de localisation refusée.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw LocationException(
        'La localisation est bloquée. Autorisez-la dans les réglages de l\'application.');
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
}

/// Minuscules, sans accents, sans « gouvernorat de » ni article
String _norm(String s) {
  var t = s.toLowerCase().trim();
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuyy';
  for (var i = 0; i < from.length; i++) {
    t = t.replaceAll(from[i], to[i]);
  }
  t = t
      .replaceAll(RegExp(r"gouvernorat (de |d')?"), '')
      .replaceAll('governorate', '')
      .replaceAll(RegExp(r'^(le|la|el) '), '')
      .trim();
  return t;
}

/// Retrouve le gouvernorat de la liste à partir d'un texte (ex. « Gouvernorat de Nabeul »)
String? matchGovernorate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final n = _norm(raw);
  if (n.length < 3) return null;
  for (final g in kGovernorates) {
    final gn = _norm(g);
    if (n == gn || n.contains(gn) || gn.contains(n)) return g;
  }
  return null;
}

/// Adresse à partir de coordonnées (service Nominatim d'OpenStreetMap, gratuit).
/// Renvoie null si rien n'est trouvé.
Future<PlaceInfo?> reverseGeocode(double lat, double lng) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': '$lat',
    'lon': '$lng',
    'zoom': '18',
    'addressdetails': '1',
    'accept-language': 'fr',
  });
  final res = await http
      .get(uri, headers: {'User-Agent': 'SouknaApp/1.0 (projet etudiant)'})
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) return null;

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final a = (data['address'] ?? <String, dynamic>{}) as Map<String, dynamic>;

  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = a[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? governorate;
  for (final k in ['state', 'region', 'state_district', 'county']) {
    governorate = matchGovernorate(a[k] is String ? a[k] as String : null);
    if (governorate != null) break;
  }

  final road = [pick(['house_number']), pick(['road', 'pedestrian', 'residential', 'footway'])]
      .whereType<String>()
      .join(' ');
  final area = pick(['neighbourhood', 'suburb', 'hamlet', 'quarter', 'isolated_dwelling']);
  final street = road.isEmpty ? area : (area == null ? road : '$road, $area');

  return PlaceInfo(
    governorate: governorate,
    city: pick(['city', 'town', 'village', 'municipality', 'county']),
    street: street,
    postalCode: pick(['postcode']),
  );
}

/// Ouvre un point dans l'application de cartes (sans clé API)
Future<bool> openInMaps(double lat, double lng) async {
  final uri =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}