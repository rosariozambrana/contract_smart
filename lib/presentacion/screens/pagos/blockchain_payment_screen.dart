import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/pago_provider.dart';
import '../../providers/contrato_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../../negocio/models/pago_model.dart';
import '../../../negocio/models/contrato_model.dart';
import '../components/Loading.dart';
import '../../../core/constants/crypto_constants.dart';
import '../../../datos/blockchain_api_service.dart';

class BlockchainPaymentScreen extends StatefulWidget {
  final int contratoId;

  const BlockchainPaymentScreen({
    Key? key,
    required this.contratoId,
  }) : super(key: key);

  @override
  State<BlockchainPaymentScreen> createState() => _BlockchainPaymentScreenState();
}

class _BlockchainPaymentScreenState extends State<BlockchainPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _isLoading = true;
  ContratoModel? _contrato;
  String? _errorMessage;
  bool _isBlockchainInitialized = true; // HTTP-based, no initialization needed
  bool _esPrimerPago = false;
  // Datos del cálculo de pago desde backend
  double _montoTotal = 0.0;
  bool _requiereDeposito = false;
  String _descripcionPago = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load contract details
      await context.read<ContratoProvider>().loadContratoById(widget.contratoId);
      _contrato = context.read<ContratoProvider>().selectedContrato;

      if (_contrato == null) {
        setState(() {
          _errorMessage = 'No se pudo cargar el contrato';
          _isLoading = false;
        });
        return;
      }

      // ✅ NUEVO: Llamar al backend para calcular el monto
      final blockchainService = BlockchainApiService();
      final response = await blockchainService.calcularMontoPago(widget.contratoId);

      if (response.isSuccess && response.data != null) {
        // Guardar datos del cálculo
        _montoTotal = (response.data['monto_total'] as num).toDouble();
        _requiereDeposito = response.data['requiere_deposito'] as bool;
        _descripcionPago = response.data['descripcion'] as String;
        _esPrimerPago = _requiereDeposito;

        // Mostrar monto calculado por el backend
        _montoController.text = _montoTotal.toString();

        debugPrint('✅ Monto calculado desde backend: $_montoTotal ETH');
        debugPrint('   Requiere depósito: $_requiereDeposito');
      } else {
        setState(() {
          _errorMessage = 'Error al calcular monto: ${response.messageError}';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitPayment() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // ✅ VERIFICAR mounted al inicio
  if (!mounted) return;

  // Mostrar confirmación antes de realizar el pago
  print('🔥 VALOR EN CAMPO: ${_montoController.text}');
  print('🔥 ES PRIMER PAGO: $_esPrimerPago');
  print('🔥 MONTO CONTRATO: ${_contrato?.monto}');
  final monto = double.parse(_montoController.text);
  print('🔥 MONTO PARSEADO: $monto');
  final confirmar = await


  _mostrarDialogConfirmacion(monto);

  if (confirmar != true) return;

  setState(() {
    _isLoading = true;
  });

  try {
    // Create payment model
    final pago = PagoModel(
      contratoId: widget.contratoId,
      monto: monto,
      fechaPago: DateTime.now(),
      descripcion: _descripcionController.text,
      estado: 'pendiente',
    );

    print('🔥 ENVIANDO PAGO: monto=${pago.monto}, contratoId=${pago.contratoId}');

    // Process payment through blockchain
    final success = await context.read<PagoProvider>().createPagoBlockchain(pago);

    // ✅ VERIFICAR mounted después de operación async
    if (!mounted) return;

    if (success) {
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<PagoProvider>().message ?? 'Pago procesado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      // Show error message
      setState(() {
        _errorMessage = context.read<PagoProvider>().message;
      });
    }
  } catch (e) {
    // ✅ VERIFICAR mounted antes de setState
    if (!mounted) return;

    setState(() {
      _errorMessage = 'Error al procesar el pago: $e';
    });
  } finally {
    // ✅ AGREGAR: Siempre resetear loading si el widget sigue montado
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  /// Muestra dialog de confirmación con desglose del pago
  Future<bool?> _mostrarDialogConfirmacion(double monto) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_esPrimerPago) ...[
              const Text(
                'Este es tu PRIMER PAGO que incluye:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• Depósito (50%): ${CryptoConstants.formatEth(_contrato!.monto * 0.5)}'),
              Text('• Primer mes: ${CryptoConstants.formatEth(_contrato!.monto)}'),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'ℹ️ El depósito se devolverá al finalizar el contrato si no hay daños',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text('Pago mensual de renta'),
              const SizedBox(height: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monto total: ${CryptoConstants.formatEth(monto)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '≈ ${CryptoConstants.formatUsdFromEth(monto)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta operación en blockchain NO puede revertirse',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con Blockchain'),
      ),
      body: _isLoading
          ? Loading(title: 'Cargando datos...')
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blockchain info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información Blockchain',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Estado Blockchain',
                                  _isBlockchainInitialized
                                      ? 'Conectado'
                                      : 'No inicializado',
                                  _isBlockchainInitialized
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                _buildInfoRow(
                                  'Red',
                                  dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL']?.contains('127.0.0.1') == true
                                      ? 'Local (Desarrollo)'
                                      : dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET']?.contains('sepolia') == true
                                          ? 'Testnet (Sepolia)'
                                          : 'Mainnet',
                                  Colors.blue,
                                ),
                                _buildInfoRow(
                                  'Chain ID',
                                  dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ?? 'No disponible',
                                  Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nota: El servicio blockchain se inicializará automáticamente al realizar el pago si aún no está inicializado.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contract info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información del Contrato',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Inmueble',
                                  _contrato?.inmueble?.nombre ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Propietario',
                                  _contrato?.propietario?.name ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Cliente',
                                  _contrato?.cliente?.name ?? 'No disponible',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Monto Mensual',
                                  '${CryptoConstants.formatEth(_contrato?.monto ?? 0.0)} (≈ ${CryptoConstants.formatUsdFromEth(_contrato?.monto ?? 0.0)})',
                                  Colors.black,
                                ),
                                _buildInfoRow(
                                  'Estado',
                                  _contrato?.estado ?? 'No disponible',
                                  _contrato?.estado == 'activo' ? Colors.green : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Desglose del primer pago
                        if (_esPrimerPago) ...[
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Primer Pago',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildDetalleRow('Depósito (50%):', '${CryptoConstants.formatEth(_contrato!.monto * 0.5)} (≈ ${CryptoConstants.formatUsdFromEth(_contrato!.monto * 0.5)})'),
                                  _buildDetalleRow('Primer mes de renta:', '${CryptoConstants.formatEth(_contrato!.monto)} (≈ ${CryptoConstants.formatUsdFromEth(_contrato!.monto)})'),
                                  const Divider(),
                                  _buildDetalleRow(
                                    'TOTAL A PAGAR:',
                                    '${CryptoConstants.formatEth(_montoTotal)} (≈ ${CryptoConstants.formatUsdFromEth(_montoTotal)})',
                                    bold: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ℹ️ El depósito se devolverá al finalizar el contrato si no hay daños',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Payment form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalles del Pago',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _montoController,
                                  enabled: !_esPrimerPago, // Deshabilitar edición en primer pago
                                  decoration: InputDecoration(
                                    labelText: _esPrimerPago
                                        ? 'Monto (calculado automáticamente)'
                                        : 'Monto (ETH)',
                                    suffixText: 'ETH',
                                    border: const OutlineInputBorder(),
                                    helperText: _esPrimerPago
                                        ? 'El monto del primer pago incluye depósito + renta'
                                        : 'Ingrese el monto en ETH',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese un monto';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Por favor ingrese un número válido';
                                    }
                                    if (double.parse(value) <= 0) {
                                      return 'El monto debe ser mayor a cero';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descripcionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitPayment,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text(
                                      'REALIZAR PAGO CON BLOCKCHAIN',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 14 : 13,
              color: bold ? Colors.blue[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
