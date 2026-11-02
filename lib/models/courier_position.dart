/// Dernière position partagée par le livreur
class CourierPosition {
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const CourierPosition({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  /// « il y a 12 s », « il y a 3 min »…
  String get ago {
    final d = updatedAt;
    if (d == null) return 'à l\'instant';
    final s = DateTime.now().difference(d).inSeconds;
    if (s < 60) return 'il y a ${s < 0 ? 0 : s} s';
    if (s < 3600) return 'il y a ${s ~/ 60} min';
    return 'il y a ${s ~/ 3600} h';
  }
}