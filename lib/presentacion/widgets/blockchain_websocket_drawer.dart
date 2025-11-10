import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/blockchain_provider.dart';
import '../../datos/reverb_service.dart';

class BlockchainWebSocketDrawer extends StatefulWidget {
  const BlockchainWebSocketDrawer({Key? key}) : super(key: key);

  @override
  State<BlockchainWebSocketDrawer> createState() =>
      _BlockchainWebSocketDrawerState();
}

class _BlockchainWebSocketDrawerState extends State<BlockchainWebSocketDrawer> {
  bool _showCodeExamples = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final blockchainProvider = context.watch<BlockchainProvider>();
    final reverbService = Provider.of<ReverbService>(
      context,
      listen: false,
    );

    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Estado de Servicios',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitorea el estado de la blockchain y WebSocket',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(),

                // Blockchain Status
                Text(
                  'Estado de Blockchain',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusRow(
                          'Servicio Blockchain',
                          'Backend maneja vía HTTP',
                          Colors.blue,
                        ),
                        _buildStatusRow(
                          'Red',
                          dotenv.env['BLOCKCHAIN_RPC_URL_LOCAL']?.contains(
                                    '192.168.43.45',
                                  ) ==
                                  true
                              ? 'Local (Desarrollo)'
                              : dotenv.env['BLOCKCHAIN_RPC_URL_TESTNET']
                                      ?.contains('sepolia') ==
                                  true
                              ? 'Testnet (Sepolia)'
                              : 'Mainnet',
                          Colors.blue,
                        ),
                        _buildStatusRow(
                          'Chain ID',
                          dotenv.env['BLOCKCHAIN_CHAIN_ID_LOCAL'] ??
                              'No disponible',
                          Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.wifi_tethering),
                              label: const Text('Probar conexión Backend'),
                              onPressed: () async {
                                final ok =
                                    await blockchainProvider
                                        .checkGanacheConnection();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '¡Backend conectado a Blockchain!'
                                            : 'Backend no pudo conectar a Blockchain',
                                      ),
                                      backgroundColor:
                                          ok ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // WebSocket Status
                Text(
                  'Estado de Reverb (WebSocket)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusRow(
                          'Servicio Reverb',
                          reverbService.isConnected
                              ? 'Conectado'
                              : 'Desconectado',
                          reverbService.isConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                        _buildStatusRow(
                          'Estado',
                          reverbService.status.toString().split('.').last,
                          _getStatusColor(reverbService.status),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // How to use section
                Text(
                  'Cómo utilizar estos servicios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blockchain Provider',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para utilizar el BlockchainProvider desde cualquier widget:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('1. Accede a la instancia singleton:'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final blockchainProvider = BlockchainProvider.instance;',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '2. O utiliza Provider para acceder desde un widget:',
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final blockchainProvider = context.read<BlockchainProvider>();',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'WebSocket Service',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Para utilizar el ReverbService:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('1. Accede al servicio mediante Provider:'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'final reverbService = Provider.of<ReverbService>(context, listen: false);',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(
                                _showCodeExamples
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              label: Text(
                                _showCodeExamples
                                    ? 'Ocultar ejemplos'
                                    : 'Ver ejemplos de código',
                              ),
                              onPressed: () {
                                setState(() {
                                  _showCodeExamples = !_showCodeExamples;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Code examples (collapsible)
                if (_showCodeExamples) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Ejemplos de Código',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ejemplo: Verificar estado de Blockchain',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '''
Future<void> checkBlockchainStatus() async {
  final blockchainProvider = BlockchainProvider.instance;

  // Verificar conexión del backend a Ganache
  final isConnected = await blockchainProvider.checkGanacheConnection();

  if (isConnected) {
    print('Backend conectado a Blockchain');
  } else {
    print('Backend no pudo conectar a Blockchain');
  }
}
''',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ejemplo: Escuchar eventos Reverb',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '''
void listenToReverbEvents() {
  final reverbService = Provider.of<ReverbService>(
    context,
    listen: false
  );

  // Escuchar cambios de estado
  reverbService.connectionStatus.listen((status) {
    print('Estado de conexión: \$status');
  });

  // Escuchar eventos de contratos
  reverbService.onContractGenerated.listen((event) {
    print('Contrato generado: \$event');
  });

  // Escuchar eventos de pagos
  reverbService.onPaymentReceived.listen((event) {
    print('Pago recibido: \$event');
  });
}
''',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReverbConnectionStatus status) {
    switch (status) {
      case ReverbConnectionStatus.connected:
        return Colors.green;
      case ReverbConnectionStatus.connecting:
      case ReverbConnectionStatus.reconnecting:
        return Colors.orange;
      case ReverbConnectionStatus.disconnected:
        return Colors.grey;
      case ReverbConnectionStatus.error:
        return Colors.red;
    }
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color valueColor, {
    bool isLong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child:
                isLong
                    ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        value,
                        style: TextStyle(
                          color: valueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        showCursor: true,
                      ),
                    )
                    : Text(
                      value,
                      style: TextStyle(
                        color: valueColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
