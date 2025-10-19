import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
// CAPA DE PRESENTACIÓN
import 'presentacion/providers/authenticated_provider.dart';
import 'presentacion/providers/blockchain_provider.dart';
import 'presentacion/providers/contrato_provider.dart';
import 'presentacion/providers/inmueble_provider.dart';
import 'presentacion/providers/pago_provider.dart';
import 'presentacion/providers/solicitud_alquiler_provider.dart';
import 'presentacion/providers/user_global_provider.dart';
import 'presentacion/screens/auth/login_screen.dart';
import 'presentacion/screens/auth/register_screen.dart';
import 'presentacion/screens/auth/edit_profile_screen.dart';
import 'presentacion/screens/home_cliente/home_cliente_screen.dart';
import 'presentacion/screens/home_propietario/home_propietario_screen.dart';
import 'presentacion/screens/inmueble/inmueble_screen.dart';
import 'presentacion/screens/visitante/home_visitante_screen.dart';
import 'presentacion/screens/admin/websocket_admin_screen.dart';
import 'presentacion/screens/notifications/notification_center_screen.dart';

// CAPA DE DATOS
import 'datos/ApiService.dart';
import 'datos/UrlConfigProvider.dart';
import 'datos/notification_service.dart';
import 'datos/socket_service.dart';
import 'datos/websocket_admin_service.dart';
import 'package:overlay_support/overlay_support.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Blockchain se inicializa lazy (cuando se necesite por primera vez)
  // Usa ensureInitialized() automáticamente antes de cada operación

  // Initialize notification service
  final notificationService = NotificationService();
  final socketService = SocketService();
  await notificationService.initialize();

  // Create and initialize the UrlConfigProvider first (espera a que cargue SharedPreferences)
  final urlConfigProvider = await UrlConfigProvider.create();

  // Set it as the shared provider for ApiService and SocketService
  ApiService.setSharedUrlConfigProvider(urlConfigProvider);
  socketService.setUrlConfigProvider(urlConfigProvider);

  // Initialize socket service after UrlConfigProvider is created

  //socketService.initialize();

  // Initialize websocket admin service
  final websocketAdminService = WebSocketAdminService(socketService);

  runApp(MyApp(
    urlConfigProvider: urlConfigProvider,
    notificationService: notificationService,
    socketService: socketService,
    websocketAdminService: websocketAdminService,
  ));
}

class MyApp extends StatefulWidget {
  final UrlConfigProvider urlConfigProvider;
  final NotificationService notificationService;
  final SocketService socketService;
  final WebSocketAdminService websocketAdminService;

  const MyApp({
    super.key,
    required this.urlConfigProvider,
    required this.notificationService,
    required this.socketService,
    required this.websocketAdminService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.socketService.dispose();
    widget.websocketAdminService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use the provided UrlConfigProvider (ya inicializado en main)
        ChangeNotifierProvider<UrlConfigProvider>.value(
          value: widget.urlConfigProvider,
        ),
        // Global user provider (singleton)
        ChangeNotifierProvider<UserGlobalProvider>.value(
          value: UserGlobalProvider(),
        ),
        // Provide socket service
         Provider<SocketService>.value(
            value: widget.socketService,
         ),
        // Provide websocket admin service
        Provider<WebSocketAdminService>.value(
            value: widget.websocketAdminService,
        ),
        // Provide notification service
       Provider<NotificationService>.value(
          value: widget.notificationService,
        ),
        // BlockchainProvider is already provided as a singleton below
        ChangeNotifierProvider(create: (context) => AuthenticatedProvider()),
        ChangeNotifierProvider(create: (context) => InmuebleProvider()),
        ChangeNotifierProvider(create: (context) => SolicitudAlquilerProvider()),
        // Use the singleton instance of BlockchainProvider
        ChangeNotifierProvider<BlockchainProvider>.value(value: BlockchainProvider.instance),
        ChangeNotifierProvider(create: (context) => ContratoProvider()),
        ChangeNotifierProvider(create: (context) => PagoProvider()),
      ],

       builder: (context, child) {
      // Inicializar socket DESPUÉS de que el provider esté disponible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Simplemente llamar initialize (ya verifica internamente si está conectado)
            widget.socketService.initialize();
        });
        
        return child!;
      },
      child: OverlaySupport.global(
        child: MaterialApp(
        title: dotenv.env['PROJECT_NAME'] ?? 'Alquileres',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => const InmuebleScreen(),
          '/homeVisitante': (context) => const HomeVisitanteScreen(),
          '/homePropietario': (context) => HomePropietarioScreen(),
          '/homeCliente': (context) => HomeClienteScreen(),
          '/editProfile': (context) => EditProfileScreen(),
          '/websocketAdmin': (context) => WebSocketAdminScreen(),
          '/notifications': (context) => NotificationCenterScreen(),
        },
      ),
      ),
    );
  }
}
