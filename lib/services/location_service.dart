import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class Coordenada {
  final double latitude;
  final double longitude;
  const Coordenada(this.latitude, this.longitude);
}

class LocationService {
  Future<Coordenada?> obterLocalizacao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      return Coordenada(posicao.latitude, posicao.longitude);
    } catch (_) {
      return null;
    }
  }

  // Fórmula de Haversine. Funciona sem rede e facilita o teste unitário.
  static double distanciaKm(Coordenada origem, Coordenada destino) {
    const raioTerraKm = 6371.0;
    const grausEmRadianos = math.pi / 180;
    final deltaLat = (destino.latitude - origem.latitude) * grausEmRadianos;
    final deltaLon = (destino.longitude - origem.longitude) * grausEmRadianos;
    final lat1 = origem.latitude * grausEmRadianos;
    final lat2 = destino.latitude * grausEmRadianos;
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);
    final limitado = a.clamp(0.0, 1.0).toDouble();
    return 2 * raioTerraKm *
        math.atan2(math.sqrt(limitado), math.sqrt(1 - limitado));
  }
}
