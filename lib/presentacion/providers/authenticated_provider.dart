import 'package:flutter/material.dart';
import '../../negocio/models/response_model.dart';
import '../../negocio/models/user_model.dart';
import '../../negocio/AuthenticatedNegocio.dart';
import '../screens/components/message_widget.dart';
import '../screens/interfaces/authenticated_screen_state.dart';
import 'user_global_provider.dart';
import 'blockchain_provider.dart';
import '../../datos/reverb_service.dart';

class AuthenticatedProvider extends ChangeNotifier{
  late AuthenticatedNegocio authenticatedNegocio;
  late AuthenticatedScreenState authenticatedScreenState;
  UserModel? userActual; // Usuario actual de la sesión

  late GlobalKey formKey;
  late TextEditingController emailController;
  late TextEditingController usernickController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  late GlobalKey formCreateKey;
  late TextEditingController numIdController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController direccionController;

  late FocusNode emailFocusNode;
  late FocusNode usernickFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;
  late FocusNode numIdFocusNode;
  late FocusNode nameFocusNode;
  late FocusNode phoneFocusNode;
  late FocusNode direccionFocusNode;

  late bool _isLoading;
  late bool _isPasswordVisible;
  late bool _isPasswordRepeatedVisible;
  late bool _isSuccess;
  late String? _message;
  late bool _isPropietario;
  MessageType _messageType = MessageType.info;


  // Global user provider instance
  final UserGlobalProvider _userGlobalProvider = UserGlobalProvider();

  // Reverb service instance for WebSocket subscriptions
  final ReverbService _reverbService = ReverbService();

  AuthenticatedProvider() {
    authenticatedNegocio = AuthenticatedNegocio();

    formKey = GlobalKey<FormState>();
    formCreateKey = GlobalKey<FormState>();

    emailController = TextEditingController();
    usernickController = TextEditingController();
    numIdController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    confirmPasswordController = TextEditingController();
    phoneController = TextEditingController();
    direccionController = TextEditingController();

    emailFocusNode = FocusNode();
    usernickFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();
    numIdFocusNode = FocusNode();
    nameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();
    direccionFocusNode = FocusNode();

    _isLoading = false;
    _isPasswordVisible = false;
    _message = null;
    _isSuccess = false;
    _isPasswordRepeatedVisible = false;
    _isPropietario = false;
    _messageType = MessageType.info;

    loadUserSession();
  }

  Future<void> login(AuthenticatedScreenState screen) async {
    try{
      isLoading = true;
      authenticatedScreenState = screen;
      ResponseModel responseModel = await authenticatedNegocio.login(emailController.text, passwordController.text);
      print('Response model en provider: ${responseModel.data}');
      if (responseModel.statusCode == 200) {
        print('Response model en provider: ${responseModel.data}');
        userActual = UserModel.mapToModel(responseModel.data);

        // Update global user state
        _userGlobalProvider.updateUser(userActual);

        // Subscribe to user's personal WebSocket channel
        _subscribeToUserChannel(userActual!);

        // Wallet management is handled by backend via HTTP

        isSuccess = responseModel.isSuccess;
        isLoading = false;
        //print('Usuario actual: ${userActual!.tipoUsuario}');
        if(userActual!.tipoUsuario == 'propietario') {
          print("moviendo a dashboard propietario");
          authenticatedScreenState.navigateToHomePropietario();
        } else {
          print("moviendo a dashboard cliente");
          authenticatedScreenState.navigateToHomeCliente();
        }
      } else {
        messageType = MessageType.error;
        isLoading = false;
        isSuccess = false;
        message = ('${responseModel.message}\n${responseModel.messageError}').toString();
      }
    } catch (e) {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = 'Error al iniciar sesión: $e';
    }
  }

  Future<void> createUser(AuthenticatedScreenState screen) async {
    isLoading = true;
    authenticatedScreenState = screen;
    userActual = UserModel(
      email: emailController.text,
      usernick: usernickController.text,
      name: nameController.text,
      numId: numIdController.text,
      telefono: phoneController.text,
      direccion: direccionController.text,
      tipoUsuario: isPropietario ? 'propietario' : 'cliente',
    );
    if (userActual == null) {
      isLoading = false;
      message = 'Error al crear el usuario';
      return;
    }
    ResponseModel responseModel = await authenticatedNegocio.createUser(userActual!, passwordController.text, confirmPasswordController.text);
    print('Response model en provider: ${responseModel.data}');
    print('Status code: ${responseModel.statusCode}');
    print('Is success: ${responseModel.isSuccess}');
    if (responseModel.isSuccess) {
      // No establecer mensaje de éxito para evitar confusión
      //print('Response model en provider: ${responseModel.data}');
      userActual = UserModel.mapToModel(responseModel.data);
      if(userActual == null) {
        messageType = MessageType.error;
        isSuccess = false;
        isLoading = false;
        message = 'Error al obtener el usuario';
        return;
      }

      // Update global user state
      _userGlobalProvider.updateUser(userActual);

      // Subscribe to user's personal WebSocket channel
      _subscribeToUserChannel(userActual!);

      // Wallet management is handled by backend via HTTP

      // Establecer estado exitoso sin mensaje
      isSuccess = true;
      isLoading = false;
      print('Usuario actual: ${userActual!.tipoUsuario}');

      // Navegar al dashboard correspondiente
      if(userActual!.tipoUsuario == 'propietario') {
        print("moviendo a dashboard propietario");
        authenticatedScreenState.navigateToHomePropietario();
      } else {
        print("moviendo a dashboard cliente");
        authenticatedScreenState.navigateToHomeCliente();
      }
    } else {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = ('${responseModel.message}\n${responseModel.messageError}').toString();
    }
  }

  Future<void> loadUserSession() async {
    userActual = await getUserSession();
    // Update global user state
    _userGlobalProvider.updateUser(userActual);

    // Subscribe to user's personal channel if user exists
    if (userActual != null) {
      _subscribeToUserChannel(userActual!);
    }
  }

  /// Subscribe user to their personal WebSocket channel with robust retry mechanism
  void _subscribeToUserChannel(UserModel user) {
    print('🔔 Iniciando suscripción al canal user.${user.id}...');

    bool subscribed = false;
    int attempts = 0;
    const maxAttempts = 15; // 15 intentos = 30 segundos (cada 2s)

    void trySubscribe() {
      if (subscribed) return;

      attempts++;

      if (_reverbService.isConnected) {
        _reverbService.subscribeToUserChannel(user.id);
        subscribed = true;
        print('✅ Usuario suscrito al canal: user.${user.id} (${user.tipoUsuario}) [intento $attempts]');
        return;
      }

      if (attempts >= maxAttempts) {
        print('❌ No se pudo suscribir al canal user.${user.id} después de $maxAttempts intentos (30s)');
        print('⚠️ Estado de Reverb: ${_reverbService.status}');
        print('💡 Las notificaciones en tiempo real NO funcionarán hasta que se reconecte');
        return;
      }

      // Reintentar cada 2 segundos
      Future.delayed(const Duration(seconds: 2), trySubscribe);
    }

    // Estrategia 1: Verificación inmediata
    trySubscribe();

    // Estrategia 2: Escuchar eventos de conexión (backup)
    final subscription = _reverbService.connectionStatus.listen((status) {
      if (status == ReverbConnectionStatus.connected && !subscribed) {
        _reverbService.subscribeToUserChannel(user.id);
        subscribed = true;
        print('✅ Usuario suscrito al canal: user.${user.id} (${user.tipoUsuario}) [vía evento]');
      }
    });

    // Limpiar listener después de 35 segundos
    Future.delayed(const Duration(seconds: 35), () {
      subscription.cancel();
    });
  }

  Future<UserModel?> getUserSession() async {
    try{
      isLoading = true;
      UserModel? userAct = await authenticatedNegocio.getUserSession();
      if (userAct != null) {
        isSuccess = true;
        print('Usuario actual: ${userAct.tipoUsuario}');
      } else {
        isSuccess = false;
        // No establecer mensaje cuando no hay usuario en la carga inicial
      }
      isLoading = false;
      return userAct;
    } catch (e) {
      message = 'Error al obtener la sesión del usuario: $e';
      return null;
    }
  }

  Future<bool> logout() async {
    print('🚪 LOGOUT INICIADO');
    print('   - Usuario actual antes de logout: ${userActual?.email} (ID: ${userActual?.id})');

    isLoading = true;

    // Unsubscribe from WebSocket channels before logout
    if (userActual != null) {
      print('📡 Desconectando usuario del canal WebSocket...');
      // Note: ReverbService doesn't have unsubscribe method,
      // but disconnecting on app close handles cleanup
    }

    ResponseModel responseModel = await authenticatedNegocio.logout(userActual!.id);
    if (responseModel.statusCode == 200) {
      message = responseModel.message;
      userActual = null; // Limpiar el usuario actual

      // Clear global user state
      _userGlobalProvider.clearUser();

      // Clear text controllers
      emailController.clear();
      passwordController.clear();

      messageType = MessageType.success;
      isSuccess = true;
      isLoading = false;

      print('✅ LOGOUT EXITOSO - Usuario limpiado');
    } else {
      messageType = MessageType.error;
      isLoading = false;
      isSuccess = false;
      message = ('${responseModel.message}\n${responseModel.messageError}').toString();
      print('❌ LOGOUT FALLÓ');
    }
    return isSuccess;
  }

  // Actualizar perfil de usuario
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      isLoading = true;
      ResponseModel responseModel = await authenticatedNegocio.updateUserProfile(updatedUser);

      if (responseModel.isSuccess) {
        // Actualizar el usuario actual
        userActual = UserModel.mapToModel(responseModel.data);

        // Actualizar el usuario global
        _userGlobalProvider.updateUser(userActual);

        messageType = MessageType.success;
        message = responseModel.message;
        isSuccess = true;
        isLoading = false;
        return true;
      } else {
        messageType = MessageType.error;
        message = responseModel.messageError ?? 'Error al actualizar el perfil';
        isSuccess = false;
        isLoading = false;
        return false;
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al actualizar el perfil: $e';
      isSuccess = false;
      isLoading = false;
      return false;
    }
  }

  String? get message => _message;
  set message(String? value) {
    _message = value;
    notifyListeners();
  }
  bool get isSuccess => _isSuccess;
  set isSuccess(bool value) {
    _isSuccess = value;
    notifyListeners();
  }
  bool get isPasswordVisible => _isPasswordVisible;
  set isPasswordVisible(bool value) {
    _isPasswordVisible = value;
    notifyListeners();
  }
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  bool get isPasswordRepeatedVisible => _isPasswordRepeatedVisible;
  set isPasswordRepeatedVisible(bool value) {
    _isPasswordRepeatedVisible = value;
    notifyListeners();
  }
  bool get isPropietario => _isPropietario;
  set isPropietario(bool value) {
    _isPropietario = value;
    notifyListeners();
  }
  MessageType get messageType => _messageType;
  set messageType(MessageType value) {
    _messageType = value;
    notifyListeners();
  }
}
