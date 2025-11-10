import 'servicio_basico_model.dart';
import 'tipo_inmueble_model.dart';
import 'user_model.dart';
import 'galeria_inmueble_model.dart';

class InmuebleModel {
  final int id;
  final int userId; // id del propietario
  final String nombre;
  final String? detalle;
  final String numHabitacion;
  final String numPiso;
  final double precio;
  final bool isOcupado;
  final List<Map<String, dynamic>>? accesorios;
  final List<ServicioBasicoModel>? servicios_basicos;
  final int tipoInmuebleId;
  final double? latitude;
  final double? longitude;
  final String? direccion;
  final String? ciudad;
  final String? pais;

  late TipoInmuebleModel? tipoInmueble;
  late UserModel? propietario;
  late List<GaleriaInmuebleModel>? galeria;

  InmuebleModel({
    this.id = 0,
    this.userId = 0,
    this.nombre = '',
    this.detalle,
    this.numHabitacion = '',
    this.numPiso = '',
    this.precio = 0.0,
    this.isOcupado = false,
    this.accesorios,
    this.servicios_basicos,
    this.tipoInmuebleId = 0,
    this.latitude,
    this.longitude,
    this.direccion,
    this.ciudad,
    this.pais,
  });

  factory InmuebleModel.mapToModel(Map<String, dynamic> doc) {
    InmuebleModel model = InmuebleModel(
      id: doc['id'] ?? 0,
      userId: doc['user_id'] ?? 0,
      nombre: doc['nombre'] ?? '',
      detalle: doc['detalle'],
      numHabitacion: doc['num_habitacion'] ?? '',
      numPiso: doc['num_piso'] ?? '',
      precio: double.tryParse(doc['precio']?.toString() ?? '0') ?? 0.0,
      isOcupado: doc['isOcupado'] ?? false,
      accesorios: null,
      servicios_basicos: ServicioBasicoModel.fromJsonList(doc['servicios_basicos']),
      tipoInmuebleId: doc['tipo_inmueble_id'] ?? 0,
      latitude: doc['latitude'] != null ? double.tryParse(doc['latitude'].toString()) : null,
      longitude: doc['longitude'] != null ? double.tryParse(doc['longitude'].toString()) : null,
      direccion: doc['direccion'],
      ciudad: doc['ciudad'],
      pais: doc['pais'],
    );
    if (doc['tipo_inmueble'] != null) {
      model.tipoInmueble = TipoInmuebleModel.fromJson(doc['tipo_inmueble']);
    } else {
      model.tipoInmueble = null;
    }
    if (doc['propietario'] != null) {
      model.propietario = UserModel.mapToModel(doc['propietario']);
    } else {
      model.propietario = null;
    }
    if (doc['galeria'] != null) {
      model.galeria = GaleriaInmuebleModel.fromJsonList(doc['galeria']);
    } else {
      model.galeria = null;
    }

    return model;
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'detalle': detalle,
      'num_habitacion': numHabitacion,
      'num_piso': numPiso,
      'precio': precio,
      'isOcupado': isOcupado,
      'accesorios': accesorios ?? null,
      'tipo_inmueble_id': tipoInmuebleId,
      'servicios_basicos': servicios_basicos?.map((servicio) => servicio.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'direccion': direccion,
      'ciudad': ciudad,
      'pais': pais,
    };
  }
  static List<InmuebleModel> fromList(dynamic data) {
    if (data is List) {
      return data.map((item) => InmuebleModel.mapToModel(item)).toList();
    } else if (data is Map<String, dynamic>) {
      return [InmuebleModel.mapToModel(data)];
    } else {
      return [];
    }
  }
}