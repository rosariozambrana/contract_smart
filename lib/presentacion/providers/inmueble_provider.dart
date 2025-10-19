import 'package:flutter/material.dart';
import '../../negocio/models/inmueble_model.dart';
import '../../negocio/models/response_model.dart';
import '../../negocio/models/galeria_inmueble_model.dart';
import '../../negocio/models/user_model.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../../negocio/models/tipo_inmueble_model.dart';
import '../../negocio/models/servicio_basico_model.dart';
import '../../negocio/AuthenticatedNegocio.dart';
import '../screens/components/message_widget.dart';
import 'user_global_provider.dart';

class InmuebleProvider extends ChangeNotifier {
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();
  late ResponseModel _responseModel;
  List<InmuebleModel> _inmuebles = [];
  List<InmuebleModel> _myInmuebles = [];
  List<GaleriaInmuebleModel> _galeriaInmueble = [];
  List<TipoInmuebleModel> _tipoInmuebles = [];
  List<ServicioBasicoModel> _serviciosBasicos = [];
  InmuebleModel? _selectedInmueble;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;

  MessageType _messageType = MessageType.info;
  bool _isInitialized = false;

  InmuebleProvider();

  bool get isInitialized => _isInitialized;

  /// Inicializa el provider cargando todos los datos necesarios
  /// Este método debe llamarse explícitamente después de crear el provider
  Future<void> initialize() async {
    try {
      isLoading = true;

      print('🔄 INITIALIZE llamado - _isInitialized: $_isInitialized');

      // CRÍTICO: Siempre recargar el usuario actual para evitar cache de usuario anterior
      // Esto es necesario cuando diferentes usuarios inician sesión en la misma sesión de la app
      await _loadCurrentUser();
      print('   - Usuario actual después de _loadCurrentUser: ${currentUser?.email} (ID: ${currentUser?.id})');

      // Solo cargar el resto de datos si no está inicializado
      if (!_isInitialized) {
        print('   - Primera inicialización, cargando inmuebles y servicios...');
        await Future.wait([
          _loadInmueblesInternal(),
          _loadServiciosBasicosInternal(),
        ]);
        _isInitialized = true;
      } else {
        print('   - Ya inicializado, solo se recargó el usuario');
      }

    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al inicializar: $e';
      print('❌ Error en initialize(): $e');
    } finally {
      isLoading = false;
    }
  }

  /// Versión interna de loadServiciosBasicos que no maneja isLoading
  Future<void> _loadServiciosBasicosInternal() async {
    try {
      // Load default basic services
      _serviciosBasicos = ServicioBasicoModel.getDefaultServicios();

      // If editing an existing property, mark the services that are already selected
      if (_selectedInmueble != null && _selectedInmueble!.servicios_basicos != null) {
        for (var servicio in _serviciosBasicos) {
          servicio.isSelected = _selectedInmueble!.servicios_basicos!.any(
            (s) => s.id == servicio.id
          );
        }
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar los servicios básicos: $e';
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      print('📥 _loadCurrentUser() - Iniciando carga de usuario...');
      final previousUserId = currentUser?.id;
      final previousUserEmail = currentUser?.email;

      // PRIORIDAD 1: Intentar obtener del UserGlobalProvider (más rápido y confiable)
      currentUser = _userGlobalProvider.currentUser;

      if (currentUser != null) {
        print('✅ Usuario obtenido de UserGlobalProvider:');
        print('   - Email: ${currentUser!.email}');
        print('   - ID: ${currentUser!.id}');
        print('   - Tipo: ${currentUser!.tipoUsuario}');
      } else {
        // PRIORIDAD 2: Si no está en UserGlobalProvider, intentar obtener de la sesión
        print('⚠️ Usuario no encontrado en UserGlobalProvider, consultando sesión...');
        currentUser = await _authenticatedNegocio.getUserSession();

        if (currentUser != null) {
          print('✅ Usuario obtenido de sesión:');
          print('   - Email: ${currentUser!.email}');
          print('   - ID: ${currentUser!.id}');
          print('   - Tipo: ${currentUser!.tipoUsuario}');

          // Actualizar el UserGlobalProvider con el usuario de la sesión
          _userGlobalProvider.updateUser(currentUser);
        } else {
          print('⚠️ Usuario no encontrado en sesión');
          messageType = MessageType.info;
          message = 'Usuario no encontrado';
        }
      }

      if (currentUser != null) {
        if (previousUserId != null && previousUserId != currentUser!.id) {
          print('🔄 CAMBIO DE USUARIO DETECTADO:');
          print('   - Usuario anterior: $previousUserEmail (ID: $previousUserId)');
          print('   - Nuevo usuario: ${currentUser!.email} (ID: ${currentUser!.id})');
        }

        messageType = MessageType.success;
        message = 'Usuario actual cargado exitosamente';
      }
    } catch (e) {
      print('❌ Error al cargar el usuario actual: $e');
      messageType = MessageType.error;
      message = 'Error al cargar el usuario actual: $e';
      rethrow; // Re-lanzar para que initialize() pueda capturarlo
    }
  }

  /// Versión interna de loadInmuebles que no maneja isLoading
  Future<void> _loadInmueblesInternal() async {
    try {
      _responseModel = await _inmuebleNegocio.getInmuebles("");
      print('Respuesta del negocio: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        inmuebles = InmuebleModel.fromList(_responseModel.data);

        // Verificar si hay inmuebles antes de usar .first
        if (inmuebles.isNotEmpty) {
          print('Inmuebles cargados: ${inmuebles.first.servicios_basicos.toString()}');
        } else {
          print('Inmuebles cargados: Lista vacía');
        }

        messageType = MessageType.success;
        message = _responseModel.message;
      } else {
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'No se encontraron inmuebles';
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar los inmuebles: $e';
      rethrow; // Re-lanzar para que initialize() pueda capturarlo
    }
  }

  Future<void> loadInmuebles() async {
  try {
    isLoading = true;
    // Simula una llamada a la base de datos para obtener inmuebles
    _responseModel = await _inmuebleNegocio.getInmuebles("");
    print('Respuesta del negocio: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
    if (_responseModel.isSuccess && _responseModel.data != null) {
      inmuebles = InmuebleModel.fromList(_responseModel.data);
      
      // Verificar si hay inmuebles antes de usar .first
      if (inmuebles.isNotEmpty) {
        print('Inmuebles cargados: ${inmuebles.first.servicios_basicos.toString()}');
      } else {
        print('Inmuebles cargados: Lista vacía');
      }
      
      messageType = MessageType.success;
      message = _responseModel.message;
    } else {
      messageType = MessageType.info;
      message = _responseModel.messageError ?? 'No se encontraron inmuebles';
    }
  } catch (e) {
    messageType = MessageType.error;
    message = 'Error al cargar los inmuebles: $e';
  } finally {
    isLoading = false;
  }
}

  Future<void> loadInmueblesByPropietarioId() async {
    print('🏠 loadInmueblesByPropietarioId() - Iniciando carga...');

    if (currentUser == null) {
      print('❌ ERROR: currentUser es NULL');
      message = 'No se pudo cargar el usuario actual';
      isLoading = false;
      messageType = MessageType.error;
      return;
    }

    print('✅ Usuario actual verificado:');
    print('   - Email: ${currentUser!.email}');
    print('   - ID: ${currentUser!.id}');
    print('   - Solicitando inmuebles para propietario ID: ${currentUser!.id}');

    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.getInmueblesByPropietarioId(currentUser!.id);
      print('📦 Respuesta del backend:');
      print('   - Success: ${_responseModel.isSuccess}');
      print('   - Data: ${_responseModel.data != null ? "✅ Datos recibidos" : "❌ Sin datos"}');

      if (_responseModel.isSuccess && _responseModel.data != null) {
        myInmuebles = InmuebleModel.fromList(_responseModel.data);
        print('✅ Inmuebles cargados: ${myInmuebles.length} inmuebles para el propietario ${currentUser!.email}');
        if (myInmuebles.isNotEmpty) {
          print('   - Primer inmueble: ${myInmuebles.first.nombre} (user_id: ${myInmuebles.first.userId})');
        }
        message = _responseModel.message ?? 'Inmuebles cargados exitosamente';
        messageType = MessageType.success;
      } else {
        print('⚠️ No se encontraron inmuebles para este propietario');
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'No se encontraron inmuebles para este propietario';
      }
    } catch (e) {
      print('❌ Error al cargar los inmuebles del propietario: $e');
      messageType = MessageType.error;
      message = 'Error al cargar los inmuebles del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<List<GaleriaInmuebleModel>> loadInmuebleGaleria(int inmuebleId) async {
    try {
      List<GaleriaInmuebleModel> result = [];
      _responseModel = await _inmuebleNegocio.getInmuebleGaleria(inmuebleId);
      if (_responseModel.isSuccess && _responseModel.data != null) {
        result = GaleriaInmuebleModel.fromJsonList(_responseModel.data);
      }
      return result;
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar las imágenes del inmueble: $e';
      print('Error al cargar las imágenes del inmueble: $e');
      return [];
    }
  }

  Future<void> loadTipoInmueble() async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.getTipoInmueble();
      if (_responseModel.isSuccess && _responseModel.data != null) {
        tipoInmuebles = TipoInmuebleModel.fromList(_responseModel.data);
        print('Tipos de inmueble cargados: ${tipoInmuebles.length}');
        message = _responseModel.message ?? 'Tipos de inmueble cargados exitosamente';
        messageType = MessageType.success;
      } else {
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'No se encontraron tipos de inmueble';
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar los tipos de inmueble: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<String> getFirstImageUrl(int inmuebleId) async {
    try {
      _responseModel = await _inmuebleNegocio.getInmuebleGaleria(inmuebleId);
      print('Respuesta del negocio al obtener la galería: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        List<GaleriaInmuebleModel> galerias = GaleriaInmuebleModel.fromJsonList(_responseModel.data);
        if (galerias.isNotEmpty) {
          // Return the URL of the first image
          return galerias.first.photoPath ?? '';
        }
      }
      return ''; // Return empty string if no images found
    } catch (e) {
      print('Error al obtener la primera imagen: $e');
      return '';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createInmueble(InmuebleModel inmueble) async {
    try {
      isLoading = true;

      // 🔍 DEBUG: Validación de usuario antes de crear inmueble
      print('🔍 VALIDANDO USUARIO EN createInmueble():');
      print('   - currentUser: ${currentUser != null ? "✅ EXISTE (ID: ${currentUser!.id}, Email: ${currentUser!.email})" : "❌ NULL"}');
      print('   - inmueble.userId: ${inmueble.userId} ${inmueble.userId == 0 ? "⚠️ CERO!" : "✅"}');
      print('   - _isInitialized: $_isInitialized');

      if (currentUser == null || inmueble.userId == 0) {
        messageType = MessageType.error;
        message = 'No se pudo cargar el usuario actual';
        isLoading = false;
        print('❌ ERROR CRÍTICO: No se pudo cargar el usuario actual');
        print('   - currentUser es null: ${currentUser == null}');
        print('   - userId es 0: ${inmueble.userId == 0}');
        return false;
      }

      print('✅ Usuario validado correctamente, procediendo a crear inmueble...');
      _responseModel = await _inmuebleNegocio.createInmueble(inmueble);
      print('Respuesta del negocio al crear inmueble: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        _selectedInmueble = InmuebleModel.mapToModel(_responseModel.data);
        message = 'Inmueble creado exitosamente';
        await loadInmueblesByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = _responseModel.messageError ?? 'Error al crear el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el inmueble: $e';
      isLoading = false;
      print('Error al crear el inmueble: $e');
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateInmueble(InmuebleModel inmueble) async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.updateInmueble(inmueble);
      if (_responseModel.isSuccess && _responseModel.data != null) {
       List<InmuebleModel> updatedList = InmuebleModel.fromList(_responseModel.data);
      if (updatedList.isNotEmpty) {
        _selectedInmueble = updatedList.first;
      }
      message = _responseModel.message ?? 'Inmueble actualizado exitosamente';
      messageType = MessageType.success;
      await loadInmueblesByPropietarioId(); // Refresh the list
      isLoading = false;
      return true;
      } else {
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'Error al actualizar el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al actualizar el inmueble: $e';
      isLoading = false;
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteInmueble(int id) async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.deleteInmueble(id);
      if (_responseModel.isSuccess) {
        message = _responseModel.message ?? 'Inmueble eliminado exitosamente';
        messageType = MessageType.success;
        await loadInmueblesByPropietarioId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        messageType = MessageType.error;
        message = _responseModel.messageError ?? 'Error al eliminar el inmueble';
        isLoading = false;
        return false;
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al eliminar el inmueble: $e';
      isLoading = false;
      return false;
    }
  }

  Future<bool> uploadInmuebleImage(int inmuebleId, String filePath) async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.uploadInmuebleImage(inmuebleId, filePath);
      print('Respuesta del negocio al subir imagen: ${_responseModel.isSuccess}, Data: ${_responseModel.data}');
      if (_responseModel.isSuccess && _responseModel.data != null) {
        message = _responseModel.message ?? 'Imagen subida exitosamente';
        messageType = MessageType.success;
        await loadInmuebleGaleria(inmuebleId); // Refresh the gallery
        isLoading = false;
        return true;
      } else {
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'Error al subir la imagen';
        isLoading = false;
        return false;
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al subir la imagen: $e';
      isLoading = false;
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteInmuebleImage(int galeriaId, int inmuebleId) async {
    try {
      isLoading = true;
      _responseModel = await _inmuebleNegocio.deleteInmuebleImage(galeriaId);
      if (_responseModel.isSuccess) {
        messageType = MessageType.success;
        message = 'Imagen eliminada exitosamente';
        await loadInmuebleGaleria(inmuebleId); // Refresh the gallery
        isLoading = false;
        return true;
      } else {
        messageType = MessageType.info;
        message = _responseModel.messageError ?? 'Error al eliminar la imagen';
        isLoading = false;
        return false;
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al eliminar la imagen: $e';
      isLoading = false;
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadServiciosBasicos() async {
    try {
      isLoading = true;
      // Load default basic services
      _serviciosBasicos = ServicioBasicoModel.getDefaultServicios();

      // If editing an existing property, mark the services that are already selected
      if (_selectedInmueble != null && _selectedInmueble!.servicios_basicos != null) {
        for (var servicio in _serviciosBasicos) {
          servicio.isSelected = _selectedInmueble!.servicios_basicos!.any(
            (s) => s.id == servicio.id
          );
        }
      }

      message = null; // Reset message on successful load
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar los servicios básicos: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> clear({bool keepUser = false}) async {
    _inmuebles.clear();
    _myInmuebles.clear();
    _galeriaInmueble.clear();
    _tipoInmuebles.clear();
    _serviciosBasicos.clear();
    _selectedInmueble = null;
    _message = null;
    _isLoading = false;

    // Opcionalmente mantener el usuario y estado de inicialización
    // para evitar recargas innecesarias entre navegaciones
    if (!keepUser) {
      _currentUser = null;
      _isInitialized = false;
    }

    notifyListeners();
  }

  void selectInmueble(InmuebleModel inmueble) {
    _selectedInmueble = inmueble;
    notifyListeners();
  }

  String? get message => _message;

  set message(String? value) {
    _message = value;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<InmuebleModel> get inmuebles => _inmuebles;

  set inmuebles(List<InmuebleModel> value) {
    _inmuebles = value;
    notifyListeners();
  }

  List<GaleriaInmuebleModel> get galeriaInmueble => _galeriaInmueble;

  List<TipoInmuebleModel> get tipoInmuebles => _tipoInmuebles;

  InmuebleModel? get selectedInmueble => _selectedInmueble;

  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? value) {
    _currentUser = value;
    notifyListeners();
  }
  set galeriaInmueble(List<GaleriaInmuebleModel> value) {
    _galeriaInmueble = value;
    notifyListeners();
  }

  set tipoInmuebles(List<TipoInmuebleModel> value) {
    _tipoInmuebles = value;
    notifyListeners();
  }

  List<ServicioBasicoModel> get serviciosBasicos => _serviciosBasicos;

  set serviciosBasicos(List<ServicioBasicoModel> value) {
    _serviciosBasicos = value;
    notifyListeners();
  }
  set selectedInmueble(InmuebleModel? value) {
    _selectedInmueble = value;
    notifyListeners();
  }

  List<InmuebleModel> get myInmuebles => _myInmuebles;

  set myInmuebles(List<InmuebleModel> value) {
    _myInmuebles = value;
    notifyListeners();
  }

  MessageType get messageType => _messageType;

  set messageType(MessageType value) {
    _messageType = value;
    notifyListeners();
  }


}
