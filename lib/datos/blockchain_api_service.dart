import 'package:flutter/material.dart';
import '../negocio/models/response_model.dart';
import 'ApiService.dart';

/// Servicio para interactuar con el blockchain a través del backend Laravel
/// Este servicio NO se conecta directamente a Ganache
/// Todas las operaciones blockchain se hacen vía HTTP al backend
class BlockchainApiService {
  final ApiService _apiService = ApiService();

  /// Obtiene el estado de la conexión blockchain del backend
  Future<ResponseModel> getBlockchainStatus() async {
    try {
      debugPrint('📡 Obteniendo estado de blockchain desde backend...');
      ResponseModel response = await _apiService.get('blockchain/status');

      if (response.isSuccess) {
        debugPrint('✅ Estado de blockchain obtenido exitosamente');
      } else {
        debugPrint('❌ Error al obtener estado de blockchain: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al obtener estado de blockchain: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Obtiene el balance de la wallet de un usuario
  Future<ResponseModel> getBalance(int userId) async {
    try {
      debugPrint('💰 Obteniendo balance para usuario $userId...');
      ResponseModel response = await _apiService.get('blockchain/balance/$userId');

      if (response.isSuccess) {
        debugPrint('✅ Balance obtenido exitosamente');
      } else {
        debugPrint('❌ Error al obtener balance: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al obtener balance: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Asigna una wallet de Ganache a un usuario
  Future<ResponseModel> assignWallet(int userId) async {
    try {
      debugPrint('🔑 Asignando wallet a usuario $userId...');
      ResponseModel response = await _apiService.post('blockchain/wallet/assign/$userId', {});

      if (response.isSuccess) {
        debugPrint('✅ Wallet asignada exitosamente');
      } else {
        debugPrint('❌ Error al asignar wallet: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al asignar wallet: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Crea un contrato en blockchain
  /// El backend se encarga de firmar la transacción con la clave del propietario
  Future<ResponseModel> createContract(int contratoId) async {
    try {
      debugPrint('📝 Creando contrato $contratoId en blockchain...');
      ResponseModel response = await _apiService.post('blockchain/contract/create', {
        'contrato_id': contratoId,
      });

      if (response.isSuccess) {
        debugPrint('✅ Contrato creado en blockchain exitosamente');
        debugPrint('   TX Hash: ${response.data['tx_hash']}');
      } else {
        debugPrint('❌ Error al crear contrato: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al crear contrato: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Aprueba un contrato en blockchain
  /// El backend se encarga de firmar la transacción con la clave del cliente
  Future<ResponseModel> approveContract(int contractId, int userId) async {
    try {
      debugPrint('✅ Aprobando contrato $contractId para usuario $userId...');
      ResponseModel response = await _apiService.post('blockchain/contract/approve', {
        'contrato_id': contractId,
        'user_id': userId,
      });

      if (response.isSuccess) {
        debugPrint('✅ Contrato aprobado exitosamente en blockchain');
        debugPrint('   TX Hash: ${response.data['tx_hash']}');
      } else {
        debugPrint('❌ Error al aprobar contrato: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al aprobar contrato: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Realiza un pago en blockchain
  /// El backend se encarga de firmar la transacción con la clave del cliente
  Future<ResponseModel> makePayment(int contratoId, int userId, double amount) async {
    try {
      debugPrint('💳 Realizando pago para contrato $contratoId...');
      debugPrint('   Usuario: $userId, Monto: $amount');
      print('🔥 API REQUEST: amount=$amount, contratoId=$contratoId, userId=$userId');
      ResponseModel response = await _apiService.post('blockchain/payment/create', {
        'contrato_id': contratoId,
        'user_id': userId,
        'amount': amount,
      });

      if (response.isSuccess) {
        debugPrint('✅ Pago realizado en blockchain exitosamente');
        debugPrint('   TX Hash: ${response.data['tx_hash']}');
        debugPrint('   Bloque: ${response.data['block_number']}');
      } else {
        debugPrint('❌ Error al realizar pago: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al realizar pago: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Obtiene los detalles de un contrato desde blockchain
  Future<ResponseModel> getContractDetails(int contractId) async {
    try {
      debugPrint('🔍 Obteniendo detalles del contrato $contractId desde blockchain...');
      ResponseModel response = await _apiService.get('blockchain/contract/$contractId');

      if (response.isSuccess) {
        debugPrint('✅ Detalles del contrato obtenidos exitosamente');
      } else {
        debugPrint('❌ Error al obtener detalles: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al obtener detalles del contrato: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Termina un contrato en blockchain
  Future<ResponseModel> terminateContract(int contratoId, int userId, String reason) async {
    try {
      debugPrint('🚫 Terminando contrato $contratoId...');
      ResponseModel response = await _apiService.post('blockchain/contract/terminate', {
        'contrato_id': contratoId,
        'user_id': userId,
        'reason': reason,
      });

      if (response.isSuccess) {
        debugPrint('✅ Contrato terminado en blockchain exitosamente');
        debugPrint('   TX Hash: ${response.data['tx_hash']}');
      } else {
        debugPrint('❌ Error al terminar contrato: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al terminar contrato: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }
  /// Calcula el monto de pago para un contrato
  /// El backend determina si requiere depósito y calcula el total
  Future<ResponseModel> calcularMontoPago(int contratoId) async {
    try {
      debugPrint('🧮 Calculando monto de pago para contrato $contratoId...');
      ResponseModel response = await _apiService.get('contratos/$contratoId/calcular-monto-pago');

      if (response.isSuccess) {
        debugPrint('✅ Monto calculado exitosamente');
        debugPrint('   Monto total: ${response.data['monto_total']}');
        debugPrint('   Requiere depósito: ${response.data['requiere_deposito']}');
      } else {
        debugPrint('❌ Error al calcular monto: ${response.messageError}');
      }

      return response;
    } catch (e) {
      debugPrint('❌ Excepción al calcular monto: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

}
