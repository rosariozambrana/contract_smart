/// Modelo para representar la ubicación geográfica de un inmueble
/// Capa de Negocio: Define la estructura de datos de ubicación
class UbicacionModel {
  final double latitude;
  final double longitude;
  final String? direccion;
  final String? ciudad;
  final String? pais;

  UbicacionModel({
    required this.latitude,
    required this.longitude,
    this.direccion,
    this.ciudad,
    this.pais,
  });

  /// Crear desde JSON
  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      pais: json['pais'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'direccion': direccion,
      'ciudad': ciudad,
      'pais': pais,
    };
  }

  /// Obtener dirección completa formateada
  String get direccionCompleta {
    List<String> partes = [];

    if (direccion != null && direccion!.isNotEmpty) {
      partes.add(direccion!);
    }
    if (ciudad != null && ciudad!.isNotEmpty) {
      partes.add(ciudad!);
    }
    if (pais != null && pais!.isNotEmpty) {
      partes.add(pais!);
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Ubicación no disponible';
  }

  /// Copia con nuevos valores
  UbicacionModel copyWith({
    double? latitude,
    double? longitude,
    String? direccion,
    String? ciudad,
    String? pais,
  }) {
    return UbicacionModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
    );
  }

  @override
  String toString() {
    return 'UbicacionModel(lat: $latitude, lng: $longitude, direccion: $direccionCompleta)';
  }
}
