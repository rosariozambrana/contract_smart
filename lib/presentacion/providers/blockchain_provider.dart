import 'package:flutter/material.dart';
import '../../datos/blockchain_api_service.dart';
import '../../negocio/models/contrato_model.dart';
import '../../negocio/models/user_model.dart';
import '../../negocio/models/response_model.dart';

class BlockchainProvider extends ChangeNotifier {
  static BlockchainProvider? _instance;
  final BlockchainApiService _blockchainApiService = BlockchainApiService();

  bool _isLoading = false;
  String? _message;

  // Singleton pattern to ensure we have only one instance
  static BlockchainProvider get instance {
    _instance ??= BlockchainProvider._internal();
    return _instance!;
  }

  // Private constructor for singleton
  BlockchainProvider._internal();

  // Public constructor for provider system
  factory BlockchainProvider() {
    _instance ??= BlockchainProvider._internal();
    return _instance!;
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get message => _message;

  // Create a rental contract on the blockchain (vía backend Laravel)
  Future<Map<String, String>?> createRentalContract(
    ContratoModel contrato,
    UserModel propietario,
    UserModel cliente,
  ) async {
    print('📝 Creando contrato en blockchain vía backend...');

    _isLoading = true;
    _message = 'Creando contrato en blockchain...';
    notifyListeners();

    try {
      // El backend se encarga de todo: obtener claves, firmar, enviar a Ganache
      ResponseModel response = await _blockchainApiService.createContract(contrato.id);

      if (response.isSuccess && response.data != null) {
        _message = 'Contrato creado en blockchain. Transaction hash: ${response.data['tx_hash']}';
        print('✅ Blockchain contract creation result: ${response.data}');

        _isLoading = false;
        notifyListeners();

        return {
          'txHash': response.data['tx_hash'] ?? '',
          'contractAddress': response.data['contract_address'] ?? '',
        };
      } else {
        _message = response.messageError ?? 'Error al crear el contrato en blockchain';
        print('❌ Error: $_message');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _message = 'Error al crear el contrato en blockchain: $e';
      print('❌ Excepción: $_message');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Approve a contract on the blockchain (vía backend Laravel)
  Future<Map<String, String>?> approveContract(int contractId, int clienteId) async {
    print('✅ Aprobando contrato en blockchain vía backend...');

    _isLoading = true;
    _message = 'Aprobando contrato en blockchain...';
    notifyListeners();

    try {
      // El backend se encarga de todo: obtener clave del cliente, firmar, enviar a Ganache
      ResponseModel response = await _blockchainApiService.approveContract(contractId, clienteId);

      if (response.isSuccess && response.data != null) {
        _message = 'Contrato aprobado en blockchain. Transaction hash: ${response.data['tx_hash']}';
        print('✅ Contract approval result: ${response.data}');

        _isLoading = false;
        notifyListeners();

        return {
          'txHash': response.data['tx_hash'] ?? '',
        };
      } else {
        _message = response.messageError ?? 'Error al aprobar el contrato en blockchain';
        print('❌ Error: $_message');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _message = 'Error al aprobar el contrato en blockchain: $e';
      print('❌ Excepción: $_message');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Make a payment for a contract (vía backend Laravel)
  Future<Map<String, String>?> makePayment(
    int contractId,
    double amount,
    int clienteId,
  ) async {
    print('💳 Realizando pago en blockchain vía backend...');

    _isLoading = true;
    _message = 'Realizando pago en blockchain...';
    notifyListeners();

    try {
      // El backend se encarga de todo: obtener clave del cliente, firmar, enviar a Ganache
      ResponseModel response = await _blockchainApiService.makePayment(contractId, clienteId, amount);

      if (response.isSuccess && response.data != null) {
        _message = 'Pago realizado en blockchain. Transaction hash: ${response.data['tx_hash']}';
        print('✅ Payment result: ${response.data}');

        _isLoading = false;
        notifyListeners();

        return {
          'txHash': response.data['tx_hash'] ?? '',
        };
      } else {
        _message = response.messageError ?? 'Error al realizar el pago en blockchain';
        print('❌ Error: $_message');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _message = 'Error al realizar el pago en blockchain: $e';
      print('❌ Excepción: $_message');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get contract details from the blockchain (vía backend Laravel)
  Future<Map<String, dynamic>?> getContractDetails(int contractId) async {
    print('🔍 Obteniendo detalles del contrato desde blockchain vía backend...');

    _isLoading = true;
    _message = 'Obteniendo detalles del contrato desde blockchain...';
    notifyListeners();

    try {
      ResponseModel response = await _blockchainApiService.getContractDetails(contractId);

      if (response.isSuccess && response.data != null) {
        _message = 'Detalles del contrato obtenidos correctamente';
        print('✅ Contract details: ${response.data}');

        _isLoading = false;
        notifyListeners();
        return response.data['details'];
      } else {
        _message = response.messageError ?? 'Error al obtener detalles del contrato';
        print('❌ Error: $_message');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _message = 'Error al obtener detalles del contrato: $e';
      print('❌ Excepción: $_message');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Check connection to blockchain (vía backend Laravel)
  Future<bool> checkGanacheConnection() async {
    try {
      ResponseModel response = await _blockchainApiService.getBlockchainStatus();
      return response.isSuccess && response.data['connected'] == true;
    } catch (e) {
      print('❌ Error al verificar conexión blockchain: $e');
      return false;
    }
  }

  /// Assign wallet to a user (vía backend Laravel)
  Future<ResponseModel> assignWallet(int userId) async {
    try {
      print('🔑 Asignando wallet a usuario $userId...');
      ResponseModel response = await _blockchainApiService.assignWallet(userId);

      if (response.isSuccess) {
        print('✅ Wallet asignada exitosamente: ${response.data['wallet_address']}');
      } else {
        print('❌ Error al asignar wallet: ${response.messageError}');
      }

      return response;
    } catch (e) {
      print('❌ Excepción al asignar wallet: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  /// Get balance of a user (vía backend Laravel)
  Future<ResponseModel> getBalance(int userId) async {
    try {
      print('💰 Obteniendo balance para usuario $userId...');
      ResponseModel response = await _blockchainApiService.getBalance(userId);

      if (response.isSuccess) {
        print('✅ Balance obtenido: ${response.data['balance_eth']} ETH');
      } else {
        print('❌ Error al obtener balance: ${response.messageError}');
      }

      return response;
    } catch (e) {
      print('❌ Excepción al obtener balance: $e');
      return ResponseModel(
        statusCode: 500,
        isSuccess: false,
        isRequest: false,
        isMessageError: true,
        messageError: e.toString(),
      );
    }
  }

  // Set message
  set message(String? value) {
    _message = value;
    notifyListeners();
  }

  // Set loading state
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    // No resources to dispose for HTTP service
    super.dispose();
  }
}
