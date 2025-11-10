import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../negocio/models/contrato_model.dart';
import '../../../providers/contrato_provider.dart';
import 'detalle_contrato_screen.dart';
import '../../../../core/constants/crypto_constants.dart';

class ContratosClienteScreen extends StatefulWidget {
  const ContratosClienteScreen({Key? key}) : super(key: key);

  @override
  State<ContratosClienteScreen> createState() => _ContratosClienteScreenState();
}

class _ContratosClienteScreenState extends State<ContratosClienteScreen> {
  @override
  void initState() {
    super.initState();
    // Load contracts for the current client
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContratoProvider>().loadContratosByClienteId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Contratos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ContratoProvider>().loadContratosByClienteId();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ContratoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.message != null && provider.contratos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadContratosByClienteId();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.contratos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes contratos activos',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.contratos.length,
            itemBuilder: (context, index) {
              final contrato = provider.contratos[index];
              return _buildContratoCard(context, contrato, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildContratoCard(BuildContext context, ContratoModel contrato, ContratoProvider provider) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Get status color
    Color statusColor;
    switch (contrato.estado.toLowerCase()) {
      case 'pendiente':
        statusColor = Colors.orange;
        break;
      case 'aprobado':
        statusColor = Colors.green;
        break;
      case 'activo':
        statusColor = Colors.blue;
        break;
      case 'rechazado':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with property name and status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contrato.inmueble?.nombre ?? 'Inmueble sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(contrato.estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contract info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dates and amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Inicio:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(contrato.fechaInicio),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha Fin:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(contrato.fechaFin),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mostrar información de pago según el estado del contrato
                if (contrato.estado.toLowerCase() == 'aprobado') ...[
                  // Primer pago pendiente - mostrar desglose
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Primer Pago Pendiente',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildPaymentRow('Renta mensual:', CryptoConstants.formatEth(contrato.monto)),
                        _buildPaymentRow('Depósito (50%):', CryptoConstants.formatEth(contrato.monto * 0.5), isSubItem: true),
                        const Divider(),
                        _buildPaymentRow(
                          'Total primer pago:',
                          CryptoConstants.formatEth(contrato.monto * 1.5),
                          isBold: true,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '≈ ${CryptoConstants.formatUsdFromEth(contrato.monto * 1.5)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ℹ️ El depósito se devuelve al finalizar',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Contrato activo o pendiente - mostrar solo renta mensual
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Renta Mensual: ${CryptoConstants.formatEth(contrato.monto)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '≈ ${CryptoConstants.formatUsdFromEth(contrato.monto)}/mes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                // Contract details if available
                if (contrato.detalle != null && contrato.detalle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Detalles:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    contrato.detalle!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons based on contract status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to contract details screen
                        provider.selectContrato(contrato);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleContratoScreen(
                              contrato: contrato,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalles'),
                    ),
                    if (contrato.estado.toLowerCase() == 'pendiente') ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showApprovalDialog(context, contrato, provider);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Responder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else if (contrato.estado.toLowerCase() == 'aprobado' && contrato.fechaPago == null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showPaymentDialog(context, contrato, provider);
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Realizar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
      case 'activo':
        return 'Activo';
      case 'rechazado':
        return 'Rechazado';
      default:
        return status;
    }
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false, bool isSubItem = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16.0 : 0, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, ContratoModel contrato, ContratoProvider provider) {
    final double primerPago = contrato.monto * 1.5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder al Contrato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas aceptar o rechazar el contrato para "${contrato.inmueble?.nombre ?? 'este inmueble'}"?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primer pago requerido:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• Renta mensual: ${CryptoConstants.formatEth(contrato.monto)}'),
                  Text('• Depósito (50%): ${CryptoConstants.formatEth(contrato.monto * 0.5)}'),
                  const Divider(),
                  Text(
                    'Total: ${CryptoConstants.formatEth(primerPago)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '≈ ${CryptoConstants.formatUsdFromEth(primerPago)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Al aceptar, deberás realizar este pago para activar el contrato.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateContratoClienteAprobado(contrato.id, false, context: context);
            },
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateContratoClienteAprobado(contrato.id, true, context: context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, ContratoModel contrato, ContratoProvider provider) {
    String selectedPaymentMethod = 'blockchain'; // ✅ Default: Blockchain
    final bool esPrimerPago = contrato.estado.toLowerCase() == 'aprobado';
    final double montoPago = esPrimerPago ? (contrato.monto * 1.5) : contrato.monto;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Realizar Pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esPrimerPago) ...[
                const Text(
                  'Primer pago de alquiler:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• Renta mensual: ${CryptoConstants.formatEth(contrato.monto)}'),
                Text('• Depósito (50%): ${CryptoConstants.formatEth(contrato.monto * 0.5)}'),
                const Divider(),
                Text(
                  'Total: ${CryptoConstants.formatEth(montoPago)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '≈ ${CryptoConstants.formatUsdFromEth(montoPago)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ] else
                Text(
                  'Vas a realizar el pago mensual por ${CryptoConstants.formatEth(montoPago)} (≈ ${CryptoConstants.formatUsdFromEth(montoPago)})',
                ),
              const SizedBox(height: 16),
              Text(
                esPrimerPago ? 'Este pago activará tu contrato de alquiler.' : 'Este pago corresponde a la renta mensual.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona el método de pago:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Payment methods
              ListTile(
                title: const Text('Pago con Blockchain'),
                subtitle: const Text('Pago seguro mediante Ethereum (Ganache)'),
                leading: Radio<String>(
                  value: 'blockchain',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Pago Convencional'),
                subtitle: const Text('Registro manual del pago'),
                leading: Radio<String>(
                  value: 'convencional',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (selectedPaymentMethod == 'blockchain') {
                  // ✅ Pago mediante blockchain
                  await provider.registrarPagoContratoBlockchain(contrato.id, DateTime.now(), context: context);
                } else {
                  // Pago convencional
                  await provider.registrarPagoContrato(contrato.id, DateTime.now(), context: context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPaymentMethod == 'blockchain' ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(selectedPaymentMethod == 'blockchain' ? 'Pagar con Blockchain' : 'Confirmar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}
