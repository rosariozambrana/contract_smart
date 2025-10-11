import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers_providers/authenticated_provider.dart';
import '../../controllers_providers/inmueble_provider.dart';
import '../../controllers_providers/contrato_provider.dart';
import '../../widgets/notification_badge.dart';
import 'inmuebles/my_inmuebles_screen.dart';
import 'inmuebles/detalle_inmuebles.dart';
import 'solicitudes/solicitudes_screen.dart';
import 'contratos/contratos_list_screen.dart';
import '../blockchain/blockchain_control_screen.dart';
import '../pagos/blockchain_payment_screen.dart';
import 'pagos/pagos_pendientes_propietario_screen.dart';
import 'pagos/pagos_recibidos_propietario_screen.dart';

class HomePropietarioScreen extends StatefulWidget {
  const HomePropietarioScreen({super.key});

  @override
  State<HomePropietarioScreen> createState() => _HomePropietarioScreenState();
}

class _HomePropietarioScreenState extends State<HomePropietarioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSession() async {
    setState(() {
      _isLoading = true;
    });
    bool result = await context.read<AuthenticatedProvider>().logout();
    if (!result) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesión')),
      );
      return;
    }
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthenticatedProvider>().userActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Propietario'),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _cerrarSession();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Inmuebles'),
            Tab(icon: Icon(Icons.description), text: 'Contratos'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Pagos'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              // Inmuebles Tab
              _buildInmueblesTab(context, user),

              // Contratos Tab
              _buildContratosTab(context, user),

              // Pagos Tab
              _buildPagosTab(context, user),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action depends on current tab
          switch (_tabController.index) {
            case 0: // Inmuebles
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetalleInmueblesScreen(
                    isEditing: false,
                  ),
                ),
              );
              break;
            case 1: // Contratos
              _showAddContratoDialog(context);
              break;
            case 2: // Pagos
              _showPaymentOptionsDialog(context);
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInmueblesTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${user?.name ?? "Propietario"}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona tus inmuebles ofertados, contratos y pagos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Profile section
          Text(
            'Mi Perfil',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Editar Perfil'),
                  subtitle: const Text('Actualiza tu información personal'),
                  leading: const Icon(Icons.person, color: Colors.orange),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to edit profile screen
                    Navigator.pushNamed(context, '/editProfile');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Mis Inmuebles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Placeholder for inmuebles list
          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Inmuebles Publicados'),
                  subtitle: const Text('Gestiona tus inmuebles en oferta'),
                  leading: const Icon(Icons.apartment, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyInmueblesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Añadir Nuevo Inmueble'),
                  subtitle: const Text('Publica un nuevo inmueble para alquiler'),
                  leading: const Icon(Icons.add_home, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.read<InmuebleProvider>().clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DetalleInmueblesScreen(
                          isEditing: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContratosTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Contratos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Contratos Activos'),
                  subtitle: const Text('Gestiona tus contratos vigentes'),
                  leading: const Icon(Icons.description, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Load contracts for the property owner
                    context.read<ContratoProvider>().loadContratosByPropietarioId();

                    // Navigate to contracts list screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContratosListScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Solicitudes de Alquiler'),
                  subtitle: const Text('Gestiona las solicitudes de alquiler y crea contratos'),
                  leading: const Icon(Icons.request_page, color: Colors.orange),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SolicitudesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Crear Nuevo Contrato'),
                  subtitle: const Text('Establece un nuevo contrato con condicionales'),
                  leading: const Icon(Icons.add_chart, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAddContratoDialog(context),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Condicionales de Contratos'),
                  subtitle: const Text('Gestiona las cláusulas condicionales'),
                  leading: const Icon(Icons.rule, color: Colors.orange),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Condicionales de Contratos'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Historial de Contratos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Contratos Finalizados'),
                  subtitle: const Text('Revisa tus contratos anteriores'),
                  leading: const Icon(Icons.history, color: Colors.grey),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Contratos Finalizados'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagosTab(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Pagos Blockchain',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Pagos Recibidos'),
                  subtitle: const Text('Visualiza los pagos recibidos de tus inquilinos'),
                  leading: const Icon(Icons.payments, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PagosRecibidosPropietarioScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Pagos Pendientes'),
                  subtitle: const Text('Revisa los pagos pendientes y envía recordatorios'),
                  leading: const Icon(Icons.payment, color: Colors.red),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PagosPendientesPropietarioScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Condicionales Automáticas'),
                  subtitle: const Text('Gestiona las acciones automáticas por retrasos'),
                  leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Condicionales Automáticas'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Configuración de Blockchain',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Configurar Wallet'),
                  subtitle: const Text('Configura tu billetera para recibir pagos'),
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.amber),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Configurar Wallet'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Historial de Transacciones'),
                  subtitle: const Text('Revisa todas las transacciones realizadas'),
                  leading: const Icon(Icons.history, color: Colors.blue),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo: Historial de Transacciones'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Control Blockchain'),
                  subtitle: const Text('Monitorea tus transacciones en la blockchain'),
                  leading: const Icon(Icons.account_tree, color: Colors.purple),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to blockchain control screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockchainControlScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation to InmueblesScreen and DetalleInmueblesScreen is now handled directly in the UI

  void _showAddContratoDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo: Crear Contrato con Condicionales'),
      ),
    );
  }

  void _showPaymentOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opciones de Pago Blockchain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccione una opción para realizar pagos a través de blockchain:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text('Realizar Pago'),
              subtitle: const Text('Pagar un contrato existente con blockchain'),
              onTap: () {
                Navigator.pop(context);
                _showSelectContratoDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text('Ver Historial de Pagos'),
              subtitle: const Text('Consultar pagos realizados con blockchain'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockchainControlScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showSelectContratoDialog(BuildContext context) {
    // Load contracts for the property owner
    context.read<ContratoProvider>().loadContratosByPropietarioId();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Contrato'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<ContratoProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.contratos.isEmpty) {
                return const Center(
                  child: Text('No hay contratos disponibles'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.contratos.length,
                itemBuilder: (context, index) {
                  final contrato = provider.contratos[index];
                  return ListTile(
                    title: Text(contrato.inmueble?.nombre ?? 'Contrato #${contrato.id}'),
                    subtitle: Text('Cliente: ${contrato.cliente?.name ?? 'No disponible'}'),
                    trailing: Text('\$${contrato.monto.toStringAsFixed(2)}'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlockchainPaymentScreen(
                            contratoId: contrato.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
