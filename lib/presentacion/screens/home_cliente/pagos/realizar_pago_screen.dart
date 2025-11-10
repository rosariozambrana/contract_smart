import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/pago_provider.dart';
import '../../../providers/blockchain_provider.dart';
import '../../../../negocio/models/pago_model.dart';
import '../../../../negocio/models/contrato_model.dart';
import '../../../../core/constants/crypto_constants.dart';

class RealizarPagoScreen extends StatefulWidget {
  final PagoModel pago;
  final ContratoModel contrato;

  const RealizarPagoScreen({
    Key? key,
    required this.pago,
    required this.contrato,
  }) : super(key: key);

  @override
  State<RealizarPagoScreen> createState() => _RealizarPagoScreenState();
}

class _RealizarPagoScreenState extends State<RealizarPagoScreen> {
  bool _isLoading = false;
  bool _blockchainEnabled = true; // HTTP-based, always available
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  bool _esPrimerPago = false;

  @override
  void initState() {
    super.initState();
    _checkBlockchainStatus();
    _detectarPrimerPago();
  }

  /// Detecta si es el primer pago basado en el estado del contrato
  void _detectarPrimerPago() {
    _esPrimerPago = widget.contrato.estado == 'aprobado';
  }

  Future<void> _checkBlockchainStatus() async {
    final blockchainProvider = context.read<BlockchainProvider>();
    // Check if backend is connected to blockchain
    final isConnected = await blockchainProvider.checkGanacheConnection();
    setState(() {
      _blockchainEnabled = isConnected;
    });
  }

  Future<void> _realizarPago() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Mostrar confirmación antes de realizar el pago
    final confirmar = await _mostrarDialogConfirmacion();
    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ PAGO MEDIANTE BLOCKCHAIN - Descuenta ETH del cliente
      final success = await context.read<PagoProvider>().createPagoBlockchain(widget.pago);

      if (success) {
        // Mostrar mensaje de éxito y volver a la pantalla anterior
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago realizado con éxito mediante blockchain'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Volver con resultado exitoso
      } else {
        // Mostrar mensaje de error
        setState(() {
          _errorMessage = context.read<PagoProvider>().message ?? 'Error al realizar el pago';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al realizar el pago: $e';
        _isLoading = false;
      });
    }
  }

  /// Muestra dialog de confirmación con desglose del pago
  Future<bool?> _mostrarDialogConfirmacion() async {
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
              Text('• Depósito (50%): ${CryptoConstants.formatEth(widget.contrato.monto * 0.5)}'),
              Text('• Primer mes: ${CryptoConstants.formatEth(widget.contrato.monto)}'),
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
                  'Monto total: ${CryptoConstants.formatEth(widget.pago.monto)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '≈ ${CryptoConstants.formatUsdFromEth(widget.pago.monto)}',
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
        title: const Text('Realizar Pago'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Desglose del primer pago
                    if (_esPrimerPago) ...[
                      Card(
                        color: Colors.blue.shade50,
                        margin: const EdgeInsets.only(bottom: 16),
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
                              _buildDetalleRow('Depósito (50%):', '${CryptoConstants.formatEth(widget.contrato.monto * 0.5)} (≈ ${CryptoConstants.formatUsdFromEth(widget.contrato.monto * 0.5)})'),
                              _buildDetalleRow('Primer mes de renta:', '${CryptoConstants.formatEth(widget.contrato.monto)} (≈ ${CryptoConstants.formatUsdFromEth(widget.contrato.monto)})'),
                              const Divider(),
                              _buildDetalleRow(
                                'TOTAL A PAGAR:',
                                '${CryptoConstants.formatEth(widget.pago.monto)} (≈ ${CryptoConstants.formatUsdFromEth(widget.pago.monto)})',
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
                    ],

                    // Detalles del pago
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
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
                            _buildInfoRow('Propiedad:', widget.contrato.inmueble?.nombre ?? 'Propiedad'),
                            _buildInfoRow('Monto a pagar:', '${CryptoConstants.formatEth(widget.pago.monto)} (≈ ${CryptoConstants.formatUsdFromEth(widget.pago.monto)})'),
                            _buildInfoRow('Fecha de pago:', _formatDate(widget.pago.fechaPago)),
                            _buildInfoRow('Propietario:', widget.contrato.inmueble?.propietario?.name ?? 'Propietario'),
                          ],
                        ),
                      ),
                    ),

                    // Método de pago
                    Text(
                      'Método de Pago',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Opciones de pago
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text('Pago con Blockchain'),
                            subtitle: Text(_blockchainEnabled 
                              ? 'Pago seguro mediante contrato inteligente' 
                              : 'No disponible - Wallet no configurada'),
                            value: true,
                            groupValue: _blockchainEnabled,
                            onChanged: _blockchainEnabled ? (_) {} : null,
                            activeColor: Colors.green,
                          ),
                          const Divider(),
                          RadioListTile<bool>(
                            title: const Text('Pago Tradicional'),
                            subtitle: const Text('Registrar pago realizado por otro medio'),
                            value: false,
                            groupValue: !_blockchainEnabled,
                            onChanged: (_) {},
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    // Mensaje de error
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón de pago
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _realizarPago,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirmar Pago',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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