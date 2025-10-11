import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/condicional_model.dart';
import '../../models/contrato_model.dart';
import '../../models/pago_model.dart';
import '../../controllers_providers/contrato_provider.dart';
import '../../controllers_providers/pago_provider.dart';

class AdministrarContratoScreen extends StatefulWidget {
  final ContratoModel contrato;

  const AdministrarContratoScreen({
    Key? key,
    required this.contrato,
  }) : super(key: key);

  @override
  State<AdministrarContratoScreen> createState() => _AdministrarContratoScreenState();
}

class _AdministrarContratoScreenState extends State<AdministrarContratoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormat = DateFormat('dd/MM/yyyy');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load payments for this contract
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPagos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPagos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await context.read<PagoProvider>().loadPagosContratoId(widget.contrato.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los pagos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Contrato'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detalles'),
            Tab(text: 'Pagos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetallesTab(),
          _buildPagosTab(),
        ],
      ),
    );
  }

  Widget _buildDetallesTab() {
    final contrato = widget.contrato;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract header
          _buildContractHeader(contrato),
          const SizedBox(height: 24),
          
          // Client information
          _buildSectionTitle('Información del Cliente'),
          _buildClientInfo(contrato),
          const SizedBox(height: 24),
          
          // Property information
          _buildSectionTitle('Información del Inmueble'),
          _buildPropertyInfo(contrato),
          const SizedBox(height: 24),
          
          // Contract details
          _buildSectionTitle('Detalles del Contrato'),
          _buildContractDetails(contrato),
          const SizedBox(height: 24),
          
          // Contract conditions
          _buildSectionTitle('Condiciones del Contrato'),
          _buildContractConditions(contrato),
          const SizedBox(height: 24),
          
          // Blockchain information
          _buildSectionTitle('Información Blockchain'),
          _buildBlockchainInfo(contrato),
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(contrato),
        ],
      ),
    );
  }

  Widget _buildPagosTab() {
    return Consumer<PagoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.pagos.isEmpty) {
          return const Center(
            child: Text('No hay pagos registrados para este contrato'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.pagos.length,
          itemBuilder: (context, index) {
            final pago = provider.pagos[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text('Pago #${pago.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha: ${dateFormat.format(pago.fechaPago)}'),
                    Text('Monto: \$${pago.monto.toStringAsFixed(2)}'),
                    Text('Estado: ${pago.estado}'),
                  ],
                ),
                trailing: pago.blockChainId != null
                    ? const Tooltip(
                        message: 'Verificado en blockchain',
                        child: Icon(Icons.verified, color: Colors.green),
                      )
                    : null,
                onTap: () {
                  // Show payment details
                  _showPaymentDetailsDialog(pago);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContractHeader(ContratoModel contrato) {
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contrato.inmueble?.nombre ?? 'Inmueble sin nombre',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
            const SizedBox(height: 8),
            Text(
              'Contrato #${contrato.id}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildClientInfo(ContratoModel contrato) {
    final cliente = contrato.cliente;
    
    if (cliente == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Información del cliente no disponible'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cliente.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${cliente.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Teléfono: ${cliente.telefono ?? 'No disponible'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(ContratoModel contrato) {
    final inmueble = contrato.inmueble;
    
    if (inmueble == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Información del inmueble no disponible'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inmueble.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inmueble.detalle.toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: ${inmueble.tipoInmueble}',
              style: const TextStyle(fontSize: 16),
            ),
            if (inmueble.detalle != null && inmueble.detalle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                inmueble.detalle!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetails(ContratoModel contrato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        style: const TextStyle(fontSize: 16),
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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Monto Mensual: \$${contrato.monto.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (contrato.fechaPago != null) ...[
              const SizedBox(height: 12),
              Text(
                'Fecha de Pago Inicial: ${dateFormat.format(contrato.fechaPago!)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
            if (contrato.detalle != null && contrato.detalle!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Detalles Adicionales:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contrato.detalle!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractConditions(ContratoModel contrato) {
    if (contrato.condicionales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay condiciones especiales para este contrato.'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < contrato.condicionales.length; i++) ...[
              if (i > 0) const Divider(),
              _buildConditionItem(contrato.condicionales[i], i + 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(CondicionalModel condicion, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condición $index: ${condicion.tipoCondicion}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            condicion.descripcion,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Acción: ${condicion.accion}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainInfo(ContratoModel contrato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contrato.blockchainAddress != null && contrato.blockchainAddress!.isNotEmpty) ...[
              const Text(
                'Dirección del Smart Contract:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contrato.blockchainAddress!,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement view on blockchain explorer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad en desarrollo: Ver en explorador blockchain'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ver en Explorador'),
              ),
            ] else ...[
              const Text(
                'Este contrato aún no está registrado en la blockchain.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ContratoModel contrato) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (contrato.estado.toLowerCase() == 'pendiente') ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showUpdateStatusDialog(contrato);
                },
                icon: const Icon(Icons.update),
                label: const Text('Actualizar Estado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else if (contrato.estado.toLowerCase() == 'activo') ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showRegisterPaymentDialog(contrato);
                },
                icon: const Icon(Icons.payment),
                label: const Text('Registrar Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1); // Switch to payments tab
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial de Pagos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(ContratoModel contrato) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Estado del Contrato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccione el nuevo estado del contrato:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              value: contrato.estado,
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'aprobado', child: Text('Aprobado')),
                DropdownMenuItem(value: 'activo', child: Text('Activo')),
                DropdownMenuItem(value: 'finalizado', child: Text('Finalizado')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (value) {
                // Store temporarily
              },
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
              // Get the selected value from the dropdown
              final newStatus = 'aprobado'; // This would be the selected value
              
              Navigator.pop(context);
              
              final provider = Provider.of<ContratoProvider>(context, listen: false);
              final success = await provider.updateContratoEstado(contrato.id, newStatus);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Estado actualizado exitosamente'
                          : 'Error al actualizar el estado',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showRegisterPaymentDialog(ContratoModel contrato) {
    final montoController = TextEditingController(text: contrato.monto.toString());
    final fechaPagoController = TextEditingController(
      text: dateFormat.format(DateTime.now()),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingrese los detalles del pago:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: montoController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: fechaPagoController,
              decoration: const InputDecoration(
                labelText: 'Fecha de Pago',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
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
              
              try {
                final provider = Provider.of<PagoProvider>(context, listen: false);
                
                final pago = PagoModel(
                  contratoId: contrato.id,
                  fechaPago: DateTime.now(),
                  monto: double.tryParse(montoController.text) ?? contrato.monto,
                  estado: 'completado',
                );
                
                final success = await provider.createPago(pago);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Pago registrado exitosamente'
                            : 'Error al registrar el pago',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  
                  if (success) {
                    // Refresh payments
                    await _loadPagos();
                    // Switch to payments tab
                    _tabController.animateTo(1);
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al registrar el pago: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailsDialog(PagoModel pago) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Pago #${pago.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${dateFormat.format(pago.fechaPago)}'),
            const SizedBox(height: 8),
            Text('Monto: \$${pago.monto.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Estado: ${pago.estado}'),
            const SizedBox(height: 8),
            if (pago.blockChainId != null) ...[
              const Text(
                'ID de Blockchain:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                pago.blockChainId!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
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
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}