import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../negocio/models/contrato_model.dart';
import 'dart:typed_data';

/// Singleton service for interacting with the Ethereum blockchain.
///
/// Usage: Always initialize with [initialize] before use.
/// All configuration must be provided via parameters (do not hardcode or read from disk).
class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();

  // Cache para el ABI del contrato (evita leerlo múltiples veces)
  static String? _cachedContractABI;

  // Ethereum client
  late Web3Client _client;

  // Contract details
  late DeployedContract _contract;
  late ContractFunction _createContract;
  late ContractFunction _approveContract;
  late ContractFunction _makePayment;
  late ContractFunction _getContractDetails;

  // Ethereum credentials
  late Credentials _credentials;

  // Network details
  late String _rpcUrl;
  late int _chainId;
  late EthereumAddress _contractAddress;

  // Private constructor
  BlockchainService._internal();

  // Singleton pattern
  factory BlockchainService() {
    return _instance;
  }

  /// Initialize the blockchain service.
  /// All parameters are required and must be provided by the caller (e.g., from .env via provider).
  Future<void> initialize({
    required String rpcUrl,
    required String privateKey,
    required int chainId,
    required String contractAddress,
  }) async {
    _rpcUrl = rpcUrl;
    _chainId = chainId;
    _contractAddress = EthereumAddress.fromHex(contractAddress);

    // Initialize Ethereum client
    _client = Web3Client(_rpcUrl, Client());

    // Load contract ABI (con cache para evitar múltiples lecturas)
    if (_cachedContractABI == null) {
      _cachedContractABI = await rootBundle.loadString(
        'assets/rentals/build/contracts/RentalContract.json',
      );
    }
    final contractData = jsonDecode(_cachedContractABI!);

    // Check if privateKey is a mnemonic phrase or a hex private key
    String hexPrivateKey;
    if (privateKey.contains(' ')) {
      // It's a mnemonic phrase, validate and convert to private key
      if (!bip39.validateMnemonic(privateKey)) {
        throw FormatException('Invalid mnemonic phrase.');
      }
      final seed = bip39.mnemonicToSeedHex(privateKey);
      hexPrivateKey = seed.substring(0, 64);
    } else {
      if (!_isValidHex(privateKey)) {
        throw FormatException('Invalid hex private key.');
      }
      hexPrivateKey = privateKey;
    }

    // Create credentials from private key
    _credentials = EthPrivateKey.fromHex(hexPrivateKey);

    // Load contract
    _contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(contractData['abi']), 'RentalContract'),
      _contractAddress,
    );

    // Get contract functions
    _createContract = _contract.function('createContract');
    _approveContract = _contract.function('approveContract');
    _makePayment = _contract.function('makePayment');
    _getContractDetails = _contract.function('getContractDetails');
  }

  /// Deploy the contract to the blockchain (advanced, rarely used in app)
  Future<String> deployContract({
    required String contractBinPath,
    required String contractAbiPath,
  }) async {
    final contractBytecode = await rootBundle.loadString(contractBinPath);
    final contractABI = await rootBundle.loadString(contractAbiPath);
    final contractData = jsonDecode(contractABI);
    final abi = ContractAbi.fromJson(
      jsonEncode(contractData['abi']),
      'RentalContract',
    );

    // Deploy contract (simplified, may need adjustment for real deployment)
    final deployTransaction = Transaction(data: hexToBytes(contractBytecode));
    final txHash = await _client.sendTransaction(
      _credentials,
      deployTransaction,
      chainId: _chainId,
    );
    final receipt = await _client.getTransactionReceipt(txHash);
    final contractAddress = receipt?.contractAddress?.hex;
    return contractAddress ?? '';
  }

  /// Create a new rental contract on the blockchain
  Future<Map<String, String>?> createRentalContract(
    ContratoModel contrato,
    String landlordAddress,
    String tenantAddress,
  ) async {
    try {
      final contractId = BigInt.from(contrato.id);
      final propertyId = BigInt.from(contrato.inmuebleId);
      final rentAmount = BigInt.from((contrato.monto * 1e18).toInt());
      final depositAmount = BigInt.from((contrato.monto * 1e18).toInt());
      final startDate = BigInt.from(
        contrato.fechaInicio.millisecondsSinceEpoch ~/ 1000,
      );
      final endDate = BigInt.from(
        contrato.fechaFin.millisecondsSinceEpoch ~/ 1000,
      );
      final termsHash =
          'ipfs://QmHash'; // Replace with actual IPFS hash if available

      final transaction = Transaction.callContract(
        contract: _contract,
        function: _createContract,
        parameters: [
          contractId,
          EthereumAddress.fromHex(landlordAddress),
          EthereumAddress.fromHex(tenantAddress),
          propertyId,
          rentAmount,
          depositAmount,
          startDate,
          endDate,
          termsHash,
        ],
      );
      final txHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: _chainId,
      );
      final receipt = await _client.getTransactionReceipt(txHash);
      final contractAddress = receipt?.contractAddress?.hex ?? '';
      return {'txHash': txHash, 'contractAddress': contractAddress};
    } catch (e, stack) {
      print('Error creating rental contract: $e');
      print('Stacktrace: $stack');
      return null;
    }
  }

  /// Approve a contract on the blockchain
  Future<Map<String, String>> approveContract(int contractId) async {
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _approveContract,
      parameters: [BigInt.from(contractId)],
    );
    final txHash = await _client.sendTransaction(
      _credentials,
      transaction,
      chainId: _chainId,
    );
    final receipt = await _client.getTransactionReceipt(txHash);
    return {
      'txHash': txHash,
      'status': receipt?.status == 1 ? 'success' : 'failed',
    };
  }

  /// Make a payment for a contract
  Future<Map<String, String>> makePayment(int contractId, double amount) async {
    final amountInWei = BigInt.from((amount * 1e18).toInt());
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _makePayment,
      parameters: [BigInt.from(contractId)],
      value: EtherAmount.inWei(amountInWei),
    );
    final txHash = await _client.sendTransaction(
      _credentials,
      transaction,
      chainId: _chainId,
    );
    final receipt = await _client.getTransactionReceipt(txHash);
    return {
      'txHash': txHash,
      'status': receipt?.status == 1 ? 'success' : 'failed',
      'amount': amount.toString(),
    };
  }

  /// Get contract details from the blockchain
  Future<Map<String, dynamic>> getContractDetails(int contractId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getContractDetails,
      params: [BigInt.from(contractId)],
    );
    if (result.isEmpty) {
      throw Exception('Contract not found');
    }
    return {
      'landlord': (result[0] as EthereumAddress).hex,
      'tenant': (result[1] as EthereumAddress).hex,
      'propertyId': (result[2] as BigInt).toInt(),
      'rentAmount': (result[3] as BigInt).toDouble() / 1e18,
      'depositAmount': (result[4] as BigInt).toDouble() / 1e18,
      'startDate': DateTime.fromMillisecondsSinceEpoch(
        (result[5] as BigInt).toInt() * 1000,
      ),
      'endDate': DateTime.fromMillisecondsSinceEpoch(
        (result[6] as BigInt).toInt() * 1000,
      ),
      'lastPaymentDate':
          (result[7] as BigInt).toInt() > 0
              ? DateTime.fromMillisecondsSinceEpoch(
                (result[7] as BigInt).toInt() * 1000,
              )
              : null,
      'state': (result[8] as BigInt).toInt(),
      'termsHash': result[9] as String,
    };
  }

  /// Helper method to validate hex strings
  bool _isValidHex(String hex) {
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex) && hex.length % 2 == 0;
  }

  /// Helper method to convert hex string to bytes
  Uint8List hexToBytes(String hex) {
    hex = hex.replaceAll('0x', '');
    final length = hex.length ~/ 2;
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Get the wallet address from the credentials
  String getWalletAddress() {
    if (_credentials is EthPrivateKey) {
      return (_credentials as EthPrivateKey).address.hex;
    }
    throw Exception('Credentials not initialized or not EthPrivateKey');
  }

  /// Get the wallet balance in Ether
  Future<double> getBalance() async {
    final balance = await _client.getBalance(
      (_credentials as EthPrivateKey).address,
    );
    return balance.getValueInUnit(EtherUnit.ether);
  }

  /// Check connection to Ganache by fetching the current block number
  Future<bool> checkGanacheConnection() async {
    try {
      final blockNumber = await _client.getBlockNumber();
      print('Ganache block number: $blockNumber');
      return true;
    } catch (e) {
      print('Error connecting to Ganache: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}
