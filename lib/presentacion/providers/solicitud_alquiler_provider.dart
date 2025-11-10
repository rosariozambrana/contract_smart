import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../negocio/models/solicitud_alquiler_model.dart';
import '../../negocio/models/response_model.dart';
import '../../negocio/models/user_model.dart';
import '../../negocio/AuthenticatedNegocio.dart';
import '../../negocio/SolicitudAlquilerNegocio.dart';
import '../../negocio/InmuebleNegocio.dart';
import '../../datos/notification_service.dart';
import '../../datos/reverb_service.dart';
import '../../datos/ApiService.dart';
import '../screens/components/message_widget.dart';
import 'user_global_provider.dart';

class SolicitudAlquilerProvider extends ChangeNotifier {
  final SolicitudAlquilerNegocio _solicitudNegocio = SolicitudAlquilerNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();
  final ApiService _apiService = ApiService.getInstance();
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();

  // Services for notifications
  late ReverbService _reverbService;
  late NotificationService _notificationService;
  final BuildContext? _context;

  List<SolicitudAlquilerModel> _solicitudes = [];
  SolicitudAlquilerModel? _selectedSolicitud;
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  SolicitudAlquilerProvider({BuildContext? context}) : _context = context {
    // Load current user
    loadCurrentUser();

    // Listen for changes to the global user state
    _userGlobalProvider.addListener(_onUserChanged);

    // Initialize services if context is provided
    if (_context != null) {
      _reverbService = Provider.of<ReverbService>(_context!, listen: false);
      _notificationService = Provider.of<NotificationService>(_context!, listen: false);
    }
  }

  // Method to initialize services if not done in constructor
  void initializeServices(BuildContext context) {
    _reverbService = Provider.of<ReverbService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
  }

  // Cleanup listener when provider is disposed
  @override
  void dispose() {
    _userGlobalProvider.removeListener(_onUserChanged);
    super.dispose();
  }

  // Called when the global user state changes
  void _onUserChanged() {
    currentUser = _userGlobalProvider.currentUser;
  }

  // Helper method to check if services are initialized
  bool _isServicesInitialized() {
  try {
    // ✅ Verificar si las variables late están inicializadas
    // Para variables late, intentar accederlas lanza error si no están inicializadas
    final reverbCheck = _reverbService;
    final notificationCheck = _notificationService;

    // Si llegamos hasta aquí, ambos están inicializados
    return reverbCheck != null && notificationCheck != null;
  } catch (e) {
    // Si hay error, significa que las variables late no están inicializadas
    print('❌ Services not initialized: $e');
    return false;
  }
}
  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;

      // First try to get the user from the global provider
      currentUser = _userGlobalProvider.currentUser;

      // If not available in global provider, try to load from session
      if (currentUser == null) {
        currentUser = await _authenticatedNegocio.getUserSession();

        // If we found a user in the session, update the global provider
        if (currentUser != null) {
          _userGlobalProvider.updateUser(currentUser);
        }
      }

      if (currentUser == null) {
        messageType = MessageType.info;
        message = 'No se pudo cargar el usuario actual';
      } else {
        print('✅ Usuario actual cargado: ${currentUser!.name} (ID: ${currentUser!.id}, Tipo: ${currentUser!.tipoUsuario})');
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar el usuario actual: $e';
      print('❌ Error loading current user: $e');
    } finally {
      isLoading = false;
    }
  }
  // el que realiza la solicitud de alquiler es el cliente, por lo que se asigna el userId del cliente a la solicitud
  Future<bool> createSolicitudAlquiler(SolicitudAlquilerModel solicitud, {BuildContext? context}) async {
  print('🚀🚀🚀 [INICIO] createSolicitudAlquiler LLAMADO 🚀🚀🚀');
  print('🔍 [INICIO] Solicitud recibida: inmuebleId=${solicitud.inmuebleId}');
  print('🔍 [INICIO] Context proporcionado: ${context != null}');
  print('🔍 [INICIO] Services initialized: ${_isServicesInitialized()}');

    // Initialize services if context is provided and not already initialized
    if (context != null && !_isServicesInitialized()) {
      initializeServices(context);
    }

    try {
      isLoading = true;
      if (solicitud.userId == null || solicitud.userId == 0) {
        await loadCurrentUser();
        if (currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }

      // Ensure the solicitud is assigned to the current user
      SolicitudAlquilerModel solicitudWithUserId = SolicitudAlquilerModel(
        id: solicitud.id,
        inmuebleId: solicitud.inmuebleId,
        userId: currentUser!.id,
        estado: solicitud.estado,
        servicios_basicos: solicitud.servicios_basicos,
        mensaje: solicitud.mensaje,
        inmueble: solicitud.inmueble,
        cliente: currentUser,
      );

      ResponseModel response = await _solicitudNegocio.createSolicitudAlquiler(solicitudWithUserId);
      print('Response from createSolicitudAlquiler: ${response.toJson()}');
      if (response.isSuccess && response.data != null) {
        _selectedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
        message = 'Solicitud de alquiler enviada exitosamente';

        // ✅ Notificación manejada por evento Reverb del backend - No enviar manualmente
        print('✅ [Provider] Solicitud creada - Backend enviará notificación vía Reverb');

        await loadSolicitudesByClienteId(); // Refresh the list
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear la solicitud de alquiler';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear la solicitud de alquiler: $e';
      isLoading = false;
      return false;
    }
  }

  Future<void> loadSolicitudesByClienteId() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    try {
      isLoading = true;
      ResponseModel response = await _solicitudNegocio.getSolicitudesByClienteId(currentUser!.id);
      print('Response from getSolicitudesByClienteId: ${response.toJson()}');
      if (response.isSuccess && response.data != null) {
        solicitudes = SolicitudAlquilerModel.fromJsonList(response.data);

        // Ensure complete data for each solicitud
        for (var solicitud in _solicitudes) {
          await _ensurePropertyDataComplete(solicitud);
          await _ensureUserDataComplete(solicitud);
        }

        print('Solicitudes loaded: ${solicitudes.length}');
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron solicitudes para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar las solicitudes del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadSolicitudesByPropietarioId() async {
    print('🔄 ═══════════════════════════════════════════════════════');
    print('🔄 CARGANDO SOLICITUDES DEL PROPIETARIO');

    if (currentUser == null) {
      print('⚠️ Usuario actual es NULL, cargando...');
      await loadCurrentUser();
      if (currentUser == null) {
        print('❌ No se pudo cargar el usuario actual');
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }

    print('👤 Usuario actual cargado:');
    print('   - Nombre: ${currentUser!.name}');
    print('   - ID: ${currentUser!.id}');
    print('   - Tipo: ${currentUser!.tipoUsuario}');
    print('   - Email: ${currentUser!.email}');

    _isLoading = true;
    notifyListeners();

    try {
      print('🌐 Llamando endpoint: getSolicitudesByPropietarioId(${currentUser!.id})');
      ResponseModel response = await _solicitudNegocio.getSolicitudesByPropietarioId(currentUser!.id);

      print('📥 Respuesta recibida:');
      print('   - isSuccess: ${response.isSuccess}');
      print('   - statusCode: ${response.statusCode}');
      print('   - message: ${response.message}');
      print('   - data: ${response.data}');
      print('   - messageError: ${response.messageError}');

      if (response.isSuccess && response.data != null) {
        print('✅ Respuesta exitosa, parseando datos...');

        // Verificar tipo de data
        if (response.data is List) {
          print('📊 Data es una Lista con ${(response.data as List).length} elementos');
        } else {
          print('⚠️ Data NO es una Lista, es: ${response.data.runtimeType}');
        }

        solicitudes = SolicitudAlquilerModel.fromJsonList(response.data);

        print('📋 Solicitudes parseadas: ${_solicitudes.length}');

        for (var i = 0; i < _solicitudes.length; i++) {
          var solicitud = _solicitudes[i];
          print('   [$i] Solicitud ID: ${solicitud.id}');
          print('       - Cliente ID: ${solicitud.userId}');
          print('       - Inmueble ID: ${solicitud.inmuebleId}');
          print('       - Estado: ${solicitud.estado}');
          print('       - Inmueble: ${solicitud.inmueble?.nombre ?? "NULL"}');
          print('       - Cliente: ${solicitud.cliente?.name ?? "NULL"}');
        }

        // Ensure complete data for each solicitud
        print('🔧 Completando datos de solicitudes...');
        for (var solicitud in _solicitudes) {
          await _ensurePropertyDataComplete(solicitud);
          await _ensureUserDataComplete(solicitud);
        }

        print('✅ Solicitudes cargadas completamente: ${_solicitudes.length}');
        message = null; // Reset message on successful load
      } else {
        print('❌ Respuesta no exitosa o data es NULL');
        message = response.messageError ?? 'No se encontraron solicitudes para este propietario';
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPCIÓN al cargar solicitudes: $e');
      print('📍 Stack trace: $stackTrace');
      message = 'Error al cargar las solicitudes del propietario: $e';
    } finally {
      print('🏁 Finalizando carga de solicitudes');
      print('   - Total solicitudes: ${_solicitudes.length}');
      print('═══════════════════════════════════════════════════════');
      isLoading = false;
    }
  }

  Future<bool> updateSolicitudEstado(int id, String estado, {BuildContext? context}) async {
    // Initialize services if context is provided and not already initialized
    if (context != null && !_isServicesInitialized()) {
      initializeServices(context);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get the solicitud before updating to have access to its data
      SolicitudAlquilerModel? solicitud;
      for (var s in _solicitudes) {
        if (s.id == id) {
          solicitud = s;
          break;
        }
      }

      ResponseModel response = await _solicitudNegocio.updateSolicitudEstado(id, estado);

      if (response.isSuccess) {
        message = 'Estado de la solicitud actualizado exitosamente';

        // Refresh the list based on user type
        if (currentUser?.tipoUsuario == 'propietario') {
          await loadSolicitudesByPropietarioId();
        } else {
          await loadSolicitudesByClienteId();
        }

        // Send notification via WebSocket if services are initialized and we have the solicitud data
        if (_isServicesInitialized() && solicitud != null && solicitud.inmueble != null && solicitud.cliente != null) {
          try {

            // Show local notification
            _notificationService.showRequestStatusChangedNotification(
              solicitudId: id,
              propertyName: solicitud.inmueble!.nombre,
              status: estado,
              userType:'cliente', // Use current user type
            );

            print('Request status change notification sent');
          } catch (notificationError) {
            print('Error sending request status change notification: $notificationError');
          }
        } else if (_isServicesInitialized()) {
          // If we don't have the solicitud data, try to get it from the response
          try {
            // Try to get the updated solicitud from the response
            if (response.data != null) {
              SolicitudAlquilerModel updatedSolicitud = SolicitudAlquilerModel.fromMap(response.data);
              if (updatedSolicitud.inmueble != null && updatedSolicitud.cliente != null) {
                // Send WebSocket notification

                // Show local notification
                _notificationService.showRequestStatusChangedNotification(
                  solicitudId: id,
                  propertyName: updatedSolicitud.inmueble!.nombre,
                  status: estado,
                  userType:'cliente', // Use current user type
                );

                print('Request status change notification sent (from response data)');
              }
            }
          } catch (notificationError) {
            print('Error sending request status change notification from response data: $notificationError');
          }
        }

        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado de la solicitud';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado de la solicitud: $e';
      isLoading = false;
      return false;
    }
  }

  void selectSolicitud(SolicitudAlquilerModel solicitud) {
    _selectedSolicitud = solicitud;
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

  List<SolicitudAlquilerModel> get solicitudes => _solicitudes;

  set solicitudes(List<SolicitudAlquilerModel> value) {
    _solicitudes = value;
    notifyListeners();
  }

  SolicitudAlquilerModel? get selectedSolicitud => _selectedSolicitud;

  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? value) {
    _currentUser = value;
    notifyListeners();
  }

  MessageType get messageType => _messageType;
  set messageType(MessageType value) {
    _messageType = value;
    notifyListeners();
  }

  // Fetch user data from API
  Future<UserModel?> _fetchUserFromApi(int userId) async {
    try {
      ResponseModel response = await _apiService.get('users/$userId');
      if (response.isSuccess && response.data != null) {
        return UserModel.mapToModel(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching user from API: $e');
      return null;
    }
  }

  // Ensure property data is complete
  Future<void> _ensurePropertyDataComplete(SolicitudAlquilerModel solicitud) async {
    if (solicitud.inmueble == null || solicitud.inmueble!.nombre.isEmpty) {
      try {
        final inmueble = await _inmuebleNegocio.getInmuebleById(solicitud.inmuebleId);
        if (inmueble != null) {
          solicitud.inmueble = inmueble;
        }
      } catch (e) {
        print('Error fetching property data: $e');
      }
    }
  }

  // Ensure user data is complete
  Future<void> _ensureUserDataComplete(SolicitudAlquilerModel solicitud) async {
    if (solicitud.cliente == null || solicitud.cliente!.name.isEmpty) {
      try {
        final user = await _fetchUserFromApi(solicitud.userId);
        if (user != null) {
          solicitud.cliente = user;
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

}
