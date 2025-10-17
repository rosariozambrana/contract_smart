import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../negocio/models/pago_model.dart';
import '../../negocio/models/response_model.dart';
import '../../negocio/models/session_model.dart';
import '../../negocio/models/user_model.dart';
import '../../negocio/AuthenticatedNegocio.dart';
import '../../negocio/PagoNegocio.dart';
import '../../negocio/SessionNegocio.dart';
import '../../negocio/UserNegocio.dart';
import '../screens/components/message_widget.dart';
import 'blockchain_provider.dart';
import '../../datos/notification_service.dart';

class PagoProvider extends ChangeNotifier {
  final BlockchainProvider _blockchainProvider = BlockchainProvider.instance;
  final PagoNegocio _pagoNegocio = PagoNegocio();
  final AuthenticatedNegocio _authenticatedNegocio = AuthenticatedNegocio();
  final NotificationService _notificationService = NotificationService();

  List<PagoModel> _pagos = [];
  List<PagoModel> _pagosContrato = [];
  List<PagoModel> _pagosPendientesCliente = [];
  List<PagoModel> _pagosCompletadosCliente = [];
  List<PagoModel> _pagosPendientesPropietario = [];
  List<PagoModel> _pagosCompletadosPropietario = [];
  bool _isLoading = false;
  String? _message;
  UserModel? _currentUser;
  MessageType _messageType = MessageType.info;

  PagoProvider() {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;
      currentUser = await _authenticatedNegocio.getUserSession();
      if (currentUser == null) {
        messageType = MessageType.info;
        message = 'Usuario no encontrado, se ha creado un usuario temporal';
      } else {
        messageType = MessageType.success;
        message = 'Usuario actual cargado exitosamente';
      }
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al cargar el usuario actual: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createPago(PagoModel pago) async {
    try {
      isLoading = true;
      if (_currentUser == null) {
        await loadCurrentUser();
        if (_currentUser == null) {
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }
      ResponseModel response = await _pagoNegocio.createPago(pago);
      if (response.isSuccess && response.data != null) {
        message = 'Pago creado exitosamente';
        // ✅ AGREGAR: Notificación de pago normal al propietario
      print('💰 [PagoProvider] Enviando notificación de pago normal');
      print('💰 [PagoProvider] Monto: ${pago.monto}');
      print('💰 [PagoProvider] Contrato ID: ${pago.contratoId}');
      
      // Notificar al propietario sobre el pago recibido
      await _notificationService.showPaymentReceivedNotification(
        contratoId: pago.contratoId,
        propertyName: 'Propiedad ID: ${pago.contratoId}',
        amount: pago.monto,
        userType: 'propietario',
      );
      
      print('✅ [PagoProvider] Notificación de pago normal enviada');



        // Refresh the list
        await loadPagosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al crear el pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al crear el pago: $e';
      isLoading = false;
      return false;
    }
  }

  // Method to create a payment through blockchain
  Future<bool> createPagoBlockchain(PagoModel pago) async {
    try {
      isLoading = true;
      messageType = MessageType.info;
      message = 'Procesando pago a través de blockchain...';

      if (_currentUser == null) {
        await loadCurrentUser();
        if (_currentUser == null) {
          messageType = MessageType.error;
          message = 'No se pudo cargar el usuario actual';
          isLoading = false;
          return false;
        }
      }

      // The blockchain will be automatically initialized when needed

      // Make payment through blockchain first
      final blockchainResult = await _blockchainProvider.makePayment(pago.contratoId, pago.monto);
      if (blockchainResult == null) {
        messageType = MessageType.error;
        message = 'Error al procesar el pago en blockchain: ${_blockchainProvider.message}';
        isLoading = false;
        return false;
      }

      // Get blockchain transaction ID
      final txHash = blockchainResult['txHash'];
      if (txHash == null) {
        messageType = MessageType.error;
        message = 'Error: No se pudo obtener el ID de transacción blockchain';
        isLoading = false;
        return false;
      }

      // Now create the payment record in the database after blockchain processing
      pago.blockChainId = txHash; // Set the blockchain ID in the model
      pago.estado = 'completado'; // Set status to completed

      ResponseModel response = await _pagoNegocio.createPago(pago);
      if (!response.isSuccess || response.data == null) {
        messageType = MessageType.error;
        message = response.messageError ?? 'Error al crear el registro de pago en la base de datos';
        isLoading = false;
        return false;
      }

      messageType = MessageType.success;
      message = 'Pago procesado exitosamente a través de blockchain. ID de transacción: $txHash';

        // ✅ AGREGAR: Notificación de pago blockchain al propietario
        print('🔗💰 [PagoProvider] Enviando notificación de pago blockchain');
        print('🔗💰 [PagoProvider] Monto: ${pago.monto}');
        print('🔗💰 [PagoProvider] TX Hash: $txHash');
        print('🔗💰 [PagoProvider] Contrato ID: ${pago.contratoId}');
        
        // Notificar al propietario sobre el pago blockchain recibido
        await _notificationService.showPaymentReceivedNotification(
          amount: pago.monto,
          propertyName: 'Propiedad ID: ${pago.contratoId}', // Si tienes el nombre, úsalo
          contratoId: pago.contratoId,
          userType: 'propietario', // La notificación va al propietario
        );


      // Refresh the list
      await loadPagosByClienteId();
      isLoading = false;
      return true;
    } catch (e) {
      messageType = MessageType.error;
      message = 'Error al procesar el pago a través de blockchain: $e';
      isLoading = false;
      return false;
    }
  }

  Future<void> loadPagosContratoId(int contratoId) async {
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosContratoId(contratoId);
      if (response.isSuccess && response.data != null) {
        pagosContrato = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos para este contrato';
      }
    } catch (e) {
      message = 'Error al cargar los pagos del contrato: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosPendientesCliente() async {
    if (currentUser == null) {
      message = 'No se pudo cargar el usuario actual';
      return;
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosPendientesByClienteId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosPendientesCliente = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos pendientes para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos pendientes del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosCompletadosCliente() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosCompletadosByClienteId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosCompletadosCliente = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos completados para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos completados del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosPendientesPropietario() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosPendientesByPropietarioId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosPendientesPropietario = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos pendientes para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos pendientes del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosCompletadosPropietario() async {
    if (currentUser == null) {
      await loadCurrentUser();
      if (currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosCompletadosByPropietarioId(currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagosCompletadosPropietario = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos completados para este propietario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos completados del propietario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadPagosByClienteId() async {
    if (_currentUser == null) {
      await loadCurrentUser();
      if (_currentUser == null) {
        message = 'No se pudo cargar el usuario actual';
        return;
      }
    }
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.getPagosByClienteId(_currentUser!.id);
      if (response.isSuccess && response.data != null) {
        pagos = PagoModel.fromList(response.data);
        message = null; // Reset message on successful load
      } else {
        message = response.messageError ?? 'No se encontraron pagos para este usuario';
      }
    } catch (e) {
      message = 'Error al cargar los pagos del usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updatePagoEstado(int id, String estado) async {
    try {
      isLoading = true;
      ResponseModel response = await _pagoNegocio.updatePagoEstado(id, estado);
      if (response.isSuccess) {
        message = 'Estado del pago actualizado exitosamente';
        // Refresh the list
        await loadPagosByClienteId();
        isLoading = false;
        return true;
      } else {
        message = response.messageError ?? 'Error al actualizar el estado del pago';
        isLoading = false;
        return false;
      }
    } catch (e) {
      message = 'Error al actualizar el estado del pago: $e';
      isLoading = false;
      return false;
    }
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

  List<PagoModel> get pagos => _pagos;

  set pagos(List<PagoModel> value) {
    _pagos = value;
    notifyListeners();
  }

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

  List<PagoModel> get pagosPendientesPropietario => _pagosPendientesPropietario;

  set pagosPendientesPropietario(List<PagoModel> value) {
    _pagosPendientesPropietario = value;
    notifyListeners();
  }

  List<PagoModel> get pagosPendientesCliente => _pagosPendientesCliente;

  set pagosPendientesCliente(List<PagoModel> value) {
    _pagosPendientesCliente = value;
    notifyListeners();
  }

  List<PagoModel> get pagosCompletadosCliente => _pagosCompletadosCliente;
  set pagosCompletadosCliente(List<PagoModel> value) {
    _pagosCompletadosCliente = value;
    notifyListeners();
  }
  List<PagoModel> get pagosContrato => _pagosContrato;
  set pagosContrato(List<PagoModel> value) {
    _pagosContrato = value;
    notifyListeners();
  }

  List<PagoModel> get pagosCompletadosPropietario => _pagosCompletadosPropietario;
  set pagosCompletadosPropietario(List<PagoModel> value) {
    _pagosCompletadosPropietario = value;
    notifyListeners();
  }
}
