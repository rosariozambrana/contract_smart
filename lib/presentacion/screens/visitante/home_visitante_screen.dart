import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../negocio/models/inmueble_model.dart';
import '../../providers/inmueble_provider.dart';
import '../components/Loading.dart';
import '../components/message_widget.dart';
import '../inmueble/inmueble_card.dart';

class HomeVisitanteScreen extends StatefulWidget {
  const HomeVisitanteScreen({super.key});

  @override
  State<HomeVisitanteScreen> createState() => _HomeVisitanteScreenState();
}

class _HomeVisitanteScreenState extends State<HomeVisitanteScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar el provider de forma asíncrona después de que el frame se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InmuebleProvider>().initialize();
    });
  }

  void _handleContractRequest(InmuebleModel inmueble) {
    // Mostrar mensaje indicando que debe registrarse
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debe registrarse para solicitar un alquiler'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );

    // Navegar al login después de un breve delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  void _navigateToAuth() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Únete a nuestra comunidad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regístrate para alquilar inmuebles o publicar los tuyos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: _navigateToAuth,
            tooltip: 'Iniciar Sesión / Registrarse',
          ),
        ],
      ),
      body: context.watch<InmuebleProvider>().isLoading
          ? Loading(title: "Cargando inmuebles")
          : context.watch<InmuebleProvider>().message != null &&
                  (context.watch<InmuebleProvider>().messageType ==
                          MessageType.error ||
                      context.watch<InmuebleProvider>().messageType ==
                          MessageType.info)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: MessageWidget(
                      message: context.watch<InmuebleProvider>().message ??
                          'No hay propiedades disponibles',
                      type: context.watch<InmuebleProvider>().messageType,
                    ),
                  ),
                )
              : context.watch<InmuebleProvider>().inmuebles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay propiedades disponibles',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<InmuebleProvider>().loadInmuebles();
                            },
                            child: const Text('Intentar recargar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          context.read<InmuebleProvider>().loadInmuebles,
                      child: ListView.builder(
                        itemCount:
                            context.watch<InmuebleProvider>().inmuebles.length,
                        itemBuilder: (context, index) {
                          InmuebleModel inmueble = context
                              .watch<InmuebleProvider>()
                              .inmuebles[index];
                          return InmuebleCard(
                            inmueble: inmueble,
                            onContractRequest: () =>
                                _handleContractRequest(inmueble),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'homeVisitanteFAB', // Tag único para evitar conflictos
        onPressed: _navigateToAuth,
        icon: const Icon(Icons.person_add),
        label: const Text('Registrarse'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
