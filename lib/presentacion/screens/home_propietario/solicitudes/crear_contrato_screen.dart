import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../negocio/models/solicitud_alquiler_model.dart';
import '../../../../negocio/models/contrato_model.dart';
import '../../../providers/contrato_provider.dart';
import '../../../../negocio/models/condicional_model.dart';
import '../../../../core/constants/crypto_constants.dart';

class CrearContratoScreen extends StatefulWidget {
  final SolicitudAlquilerModel solicitud;

  const CrearContratoScreen({
    Key? key,
    required this.solicitud,
  }) : super(key: key);

  @override
  State<CrearContratoScreen> createState() => _CrearContratoScreenState();
}

class _CrearContratoScreenState extends State<CrearContratoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detalleController = TextEditingController();
  final _montoController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 365));
  String _usdEquivalent = ''; // Para mostrar conversión en tiempo real

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });

  }
  void loadData() {
    // This method can be used to load any initial data if needed
    // Currently, it is not used but can be implemented later
    // Set initial monto based on property price
    if (widget.solicitud.inmueble != null) {
      _montoController.text = widget.solicitud.inmueble!.precio.toString();
      // Calcular conversión USD inicial
      setState(() {
        _usdEquivalent = CryptoConstants.formatUsdFromEth(widget.solicitud.inmueble!.precio);
      });
    }

    // Initialize date controllers
    final dateFormat = DateFormat('dd/MM/yyyy');
    _fechaInicioController.text = dateFormat.format(_fechaInicio);
    _fechaFinController.text = dateFormat.format(_fechaFin);

  }

  @override
  void dispose() {
    _detalleController.dispose();
    _montoController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
        // Update controller text
        _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(_fechaInicio);

        // Ensure fechaFin is after fechaInicio
        if (_fechaFin.isBefore(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(days: 365));
          // Update fechaFin controller text as well
          _fechaFinController.text = DateFormat('dd/MM/yyyy').format(_fechaFin);
        }
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: _fechaInicio.add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
        // Update controller text
        _fechaFinController.text = DateFormat('dd/MM/yyyy').format(_fechaFin);
      });
    }
  }

  void _addCondicional() {
    String tempDescripcion = '';
    String tempTipoCondicion = 'otro';
    String tempAccion = 'otro';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Condicional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Retraso en el pago mensual',
                ),
                maxLines: 2,
                onChanged: (value) {
                  tempDescripcion = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Condición',
                ),
                value: tempTipoCondicion,
                items: const [
                  DropdownMenuItem(value: 'retraso_pago', child: Text('Retraso en el Pago')),
                  DropdownMenuItem(value: 'daños', child: Text('Daños a la Propiedad')),
                  DropdownMenuItem(value: 'incumplimiento', child: Text('Incumplimiento de Contrato')),
                  DropdownMenuItem(value: 'seguridad', child: Text('Seguridad de accesos')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  if (value != null) tempTipoCondicion = value;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Acción a Tomar',
                ),
                value: tempAccion,
                items: const [
                  DropdownMenuItem(value: 'multa', child: Text('Aplicar Multa')),
                  DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                  DropdownMenuItem(value: 'rescision', child: Text('Rescisión de Contrato')),
                  DropdownMenuItem(value: 'accesos', child: Text('Control de Accesos')),
                  DropdownMenuItem(value: 'otro', child: Text('Otra Acción')),
                ],
                onChanged: (value) {
                  if (value != null) tempAccion = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempDescripcion.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingrese una descripción'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                context.read<ContratoProvider>().condicionales.add(
                  CondicionalModel(
                    id: context.read<ContratoProvider>().condicionales.length + 1,
                    descripcion: tempDescripcion,
                    tipoCondicion: tempTipoCondicion,
                    accion: tempAccion,
                    parametros: {},
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeCondicional(int index) {
    setState(() {
      context.read<ContratoProvider>().condicionales.removeAt(index);
    });
  }

  Future<void> _submitContrato() async {
    // Add null check for _formKey.currentState
    final formState = _formKey.currentState;
    if (formState == null) return;

    if (formState.validate()) {
      try {
        context.read<ContratoProvider>().isLoading = true;
        final provider = Provider.of<ContratoProvider>(context, listen: false);
        final success = await provider.createContratoFromSolicitud(
          widget.solicitud,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          monto: double.parse(_montoController.text),
          detalle: _detalleController.text,
          condicionales: context.read<ContratoProvider>().condicionales,
          context: context,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Contrato creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.message ?? 'Error al crear el contrato'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Update loading state only if still mounted
          context.read<ContratoProvider>().isLoading = false;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear el contrato: $e'),
              backgroundColor: Colors.red,
            ),
          );
          context.read<ContratoProvider>().isLoading = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Contrato'),
      ),
      body: context.read<ContratoProvider>().isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property and client info card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.solicitud.inmueble?.nombre ?? 'Inmueble sin nombre',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliente: ${widget.solicitud.cliente?.name ?? "Cliente desconocido"}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${widget.solicitud.cliente?.email ?? ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Teléfono: ${widget.solicitud.cliente?.telefono ?? ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contract details section
                    Text(
                      'Detalles del Contrato',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Fecha inicio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: _fechaInicioController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Inicio',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => _selectFechaInicio(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: _fechaFinController,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Fin',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => _selectFechaFin(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Monto
                    TextFormField(
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto Mensual (ETH)',
                        border: OutlineInputBorder(),
                        hintText: '2.0',
                        helperText: 'Rango recomendado: 0.2 - 10 ETH',
                        suffixText: 'ETH',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        final eth = double.tryParse(value);
                        if (eth != null && eth > 0) {
                          setState(() {
                            _usdEquivalent = CryptoConstants.formatUsdFromEth(eth);
                          });
                        } else {
                          setState(() {
                            _usdEquivalent = '';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un monto en ETH';
                        }
                        final eth = double.tryParse(value);
                        if (eth == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        if (eth <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                        if (eth > 100) {
                          return 'Monto muy alto. Usar rango 0.2 - 10 ETH';
                        }
                        return null;
                      },
                    ),
                    if (_usdEquivalent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '≈ $_usdEquivalent USD/mes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Detalle
                    TextFormField(
                      controller: _detalleController,
                      decoration: const InputDecoration(
                        labelText: 'Detalles adicionales',
                        border: OutlineInputBorder(),
                        hintText: 'Ingrese detalles adicionales del contrato...',
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    // Conditionals section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Condicionales',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addCondicional,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Defina las condiciones que se aplicarán en caso de incumplimiento:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Conditionals list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: context.read<ContratoProvider>().condicionales.length,
                      itemBuilder: (context, index) {
                        final condicional = context.read<ContratoProvider>().condicionales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(condicional.descripcion),
                            subtitle: Text('Acción: ${_getAccionText(condicional.accion)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeCondicional(index),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitContrato,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Crear y Enviar Contrato',
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

  String _getAccionText(String accion) {
    switch (accion.toLowerCase()) {
      case 'multa':
        return 'Aplicar Multa';
      case 'reparacion':
        return 'Reparación';
      case 'rescision':
        return 'Rescisión de Contrato';
      default:
        return accion;
    }
  }
}
