import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/socket_service.dart';
import '../../models/user_model.dart';
import '../../controllers_providers/authenticated_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ AGREGAR
import 'dart:convert'; // ✅ AGREGAR
import 'package:flutter/foundation.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String payload;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.timestamp,
    this.isRead = false,
  });

 Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'payload': payload,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    payload: json['payload'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    isRead: json['isRead'] ?? false,
  );

}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<NotificationItem> _notifications = [];
  UserModel? _currentUser;
  late SocketService _socketService;
  late NotificationService _notificationService;
  bool _isInitialized = false;

  static const String _notificationsKey = 'user_notifications';

  @override
  void initState() {
    super.initState();
    /*_socketService = Provider.of<SocketService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    _currentUser = Provider.of<AuthenticatedProvider>(context, listen: false).userActual;*/
   // _addSampleNotifications();

  }

      @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ✅ MOVER toda la inicialización aquí
    if (!_isInitialized) {
    print('🔧 [NotificationCenter] INICIO - didChangeDependencies');
    print('🔧 [NotificationCenter] Usuario actual: ${Provider.of<AuthenticatedProvider>(context, listen: false).userActual?.name}');

      _socketService = Provider.of<SocketService>(context, listen: false);
      _notificationService = Provider.of<NotificationService>(context, listen: false);
      _currentUser = Provider.of<AuthenticatedProvider>(context, listen: false).userActual;

      print('🔧 [NotificationCenter] Usuario actual: ${_currentUser?.name} (${_currentUser?.tipoUsuario})');
      print('🔧 [NotificationCenter] NotificationService: $_notificationService');

      print('🔧 [NotificationCenter] Estado del buffer ANTES de conectar:');
    _notificationService.debugBuffer();

       // ✅ AGREGAR: Conectar con NotificationService
      _notificationService.setNotificationCallback(_addNotification);


        // ✅ CARGAR notificaciones DESPUÉS
    _loadNotifications().then((_) {
      // Solo agregar samples si no hay notificaciones guardadas
      if (_notifications.isEmpty) {
        print('🔧 [NotificationCenter] Agregando notificaciones de muestra');
        _addSampleNotifications();
      }
      // ✅ AGREGAR debug final
      _debugNotificationCenter();

    });
        print('🔧 [NotificationCenter] Inicialización completada');
      _isInitialized = true;
    }
  }

  // ✅ REEMPLAZAR el método _loadNotifications completo:
Future<void> _loadNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = _currentUser?.id?.toString() ?? 'default';
    final notificationsJson = prefs.getString('${_notificationsKey}_$userId');
    
    if (notificationsJson != null && notificationsJson.isNotEmpty) {
      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      final allNotifications = notificationsList
          .map((json) => NotificationItem.fromJson(json))
          .toList();
      
      // ✅ AGREGAR: Filtrar notificaciones al cargar
      final filteredNotifications = <NotificationItem>[];
      final userRole = _currentUser?.tipoUsuario?.toLowerCase() ?? '';
      
      print('🔍 [NotificationCenter] Filtrando ${allNotifications.length} notificaciones para $userRole');
      
      for (final notification in allNotifications) {
        if (_shouldShowNotification(notification, userRole)) {
          filteredNotifications.add(notification);
          print('✅ [NotificationCenter] Cargada: ${notification.title}');
        } else {
          print('🚫 [NotificationCenter] Filtrada: ${notification.title} (no para $userRole)');
        }
      }
      
      setState(() {
        _notifications.clear();
        _notifications.addAll(filteredNotifications);
      });
      
      print('✅ [NotificationCenter] ${filteredNotifications.length} de ${allNotifications.length} notificaciones cargadas para $userRole');
    }
  } catch (e) {
    print('❌ [NotificationCenter] Error cargando notificaciones: $e');
  }
}


// ✅ AGREGAR: Método helper para determinar si mostrar notificación
bool _shouldShowNotification(NotificationItem notification, String userRole) {
  final payload = notification.payload;
  final title = notification.title;
  
  print('🔍 [Filter] Evaluando: $title para $userRole');
  
  if (payload.startsWith('request_status_')) {
    if (title.contains('Nueva Solicitud')) {
      // Nueva solicitud → Solo propietarios
      final shouldShow = userRole == 'propietario';
      print('🔍 [Filter] Nueva solicitud - Propietario requerido: $shouldShow');
      return shouldShow;
    } else if (title.contains('Solicitud Actualizada') || title.contains('aprobada') || title.contains('rechazada')) {
      // Estado actualizado → Solo clientes
      final shouldShow = userRole == 'cliente';
      print('🔍 [Filter] Actualización - Cliente requerido: $shouldShow');
      return shouldShow;
    }
  } 
  else if (payload.startsWith('payment_received_')) {
    // Pagos → Solo propietarios
    final shouldShow = userRole == 'propietario';
    print('🔍 [Filter] Pago - Propietario requerido: $shouldShow');
    return shouldShow;
  } 
  else if (payload.startsWith('contract_generated_')) {
    // Contratos → Ambos
    final shouldShow = userRole == 'cliente' || userRole == 'propietario';
    print('🔍 [Filter] Contrato - Ambos permitidos: $shouldShow');
    return shouldShow;
  }
  
  // Por defecto, permitir notificaciones generales
  print('🔍 [Filter] Notificación general - Permitida: true');
  return true;
}

  // ✅ AGREGAR: Método para guardar notificaciones
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUser?.id?.toString() ?? 'default';
      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList()
      );
      
      await prefs.setString('${_notificationsKey}_$userId', notificationsJson);
      print('✅ [NotificationCenter] Notificaciones guardadas');
    } catch (e) {
      print('❌ [NotificationCenter] Error guardando notificaciones: $e');
    }
  }

 // ✅ REEMPLAZAR el método _addNotification completo:
void _addNotification({
  required int id,
  required String title,
  required String body,
  required String payload,
}) async {

  print('🔔 [NotificationCenter] ===== RECIBIENDO NOTIFICACIÓN =====');
  print('🔔 [NotificationCenter] ID: $id');
  print('🔔 [NotificationCenter] Título: $title');
  print('🔔 [NotificationCenter] Payload: $payload');
  print('🔔 [NotificationCenter] Usuario actual: ${_currentUser?.name} (${_currentUser?.tipoUsuario})');
  
  if (!mounted) return;
  
  final userRole = _currentUser?.tipoUsuario?.toLowerCase() ?? '';
  
  // ✅ CREAR notificación temporal para usar el filtro
  final tempNotification = NotificationItem(
    id: id,
    title: title,
    body: body,
    payload: payload,
    timestamp: DateTime.now(),
  );
  
  // ✅ USAR el método helper para filtrar
  if (!_shouldShowNotification(tempNotification, userRole)) {
    print('🚫 [NotificationCenter] Notificación FILTRADA para $userRole');
    return;
  }
  
  print('✅ [NotificationCenter] Notificación APROBADA para $userRole');

  // ✅ Evitar duplicados
  final exists = _notifications.any((n) => 
    n.id == id && n.payload == payload
  );
  
  if (exists) {
    print('🚫 [NotificationCenter] Duplicado ignorado: $title');
    return;
  }

  print('🎯 [NotificationCenter] AGREGANDO notificación para $userRole');
  setState(() {
    _notifications.insert(0, tempNotification);
  });
  
  await _saveNotifications();
  print('✅ [NotificationCenter] Notificación agregada y guardada: $title');
}


// ✅ REEMPLAZAR el método _addSampleNotifications:
void _addSampleNotifications() {
  // Solo en debug y si no hay notificaciones
  if (_notifications.isNotEmpty) {
    print('🔧 [NotificationCenter] Ya existen notificaciones, omitiendo samples');
    return;
  }
  
  final userRole = _currentUser?.tipoUsuario?.toLowerCase() ?? '';
  print('🔧 [NotificationCenter] Agregando samples para $userRole');
  
  assert(() {
    // Usar Future.delayed para evitar conflictos con setState
    Future.delayed(Duration.zero, () {
      if (mounted) {
        // ✅ CORREGIR: Samples específicos según el rol
        if (userRole == 'propietario') {
          _addNotification(
            id: 1001,
            title: '🔔 Nueva Solicitud',
            body: 'Has recibido una nueva solicitud para: Apartamento en Miraflores',
            payload: 'request_status_1001',
          );
          _addNotification(
            id: 1002,
            title: '💰 Pago Recibido',
            body: 'Se ha recibido un pago de \$1,200.00 para la propiedad: Casa en San Isidro',
            payload: 'payment_received_1002',
          );
        } else if (userRole == 'cliente') {
          _addNotification(
            id: 1003,
            title: '✅ Solicitud Actualizada',
            body: 'Tu solicitud para la propiedad "Departamento en San Borja" ha sido aprobada',
            payload: 'request_status_1003',
          );
        }
        
        // ✅ Contratos para ambos
        _addNotification(
          id: 1004,
          title: '📄 Contrato Generado',
          body: 'Se ha generado un contrato para la propiedad: Villa en La Molina',
          payload: 'contract_generated_1004',
        );
      }
    });
    return true;
  }());
}



  

  void _markAllAsRead() async { // ✅ HACER async
    if (_notifications.isEmpty) return;
    
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    
    // ✅ AGREGAR: Guardar cambios
    await _saveNotifications();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las notificaciones marcadas como leídas')),
    );
  }

 void _clearAll() async { // ✅ HACER async
    if (_notifications.isEmpty) return;
    
    // ✅ AGREGAR: Confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Estás seguro de que quieres borrar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _notifications.clear();
      });
      
      // ✅ AGREGAR: Guardar cambios
      await _saveNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificaciones eliminadas')),
      );
    }
  }

  void _handleNotificationTap(NotificationItem notification) async { // ✅ AGREGAR async
  if (!mounted) return; // ✅ AGREGAR verificación
  
  // Mark as read
  setState(() {
    notification.isRead = true;
  });

  // ✅ AGREGAR: Guardar cambio de estado
  await _saveNotifications();

  // Handle navigation based on payload
  final payload = notification.payload;
  if (payload.startsWith('contract_generated_')) {
    // Navigate to contract details
    final contratoId = int.tryParse(payload.split('_').last) ?? 0;
    if (contratoId > 0) {
      // Navigate to contract details screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navegando al contrato #$contratoId')),
      );
    }
  } else if (payload.startsWith('payment_received_')) {
    // Navigate to payment details
    final contratoId = int.tryParse(payload.split('_').last) ?? 0;
    if (contratoId > 0) {
      // Navigate to payment details screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navegando al pago del contrato #$contratoId')),
      );
    }
  } else if (payload.startsWith('request_status_')) {
    // Navigate to request details
    final solicitudId = int.tryParse(payload.split('_').last) ?? 0;
    if (solicitudId > 0) {
      // Navigate to request details screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navegando a la solicitud #$solicitudId')),
      );
    }
  }
}


   @override
void dispose() {
  // ✅ VERIFICAR que existe antes de setear null
  if (_isInitialized) {
    _notificationService.setNotificationCallback(null);
  }
  super.dispose();
}


// ✅ AGREGAR método de debug
void _debugNotificationCenter() {
  print('🔍 [DEBUG] ===== ESTADO DEL CENTRO DE NOTIFICACIONES =====');
  print('🔍 [DEBUG] Usuario actual: ${_currentUser?.name} (${_currentUser?.tipoUsuario})');
  print('🔍 [DEBUG] Total notificaciones: ${_notifications.length}');
  print('🔍 [DEBUG] Callback conectado: ${_notificationService != null}');
  print('🔍 [DEBUG] Inicializado: $_isInitialized');
  
  for (int i = 0; i < _notifications.length; i++) {
    final notif = _notifications[i];
    print('🔍 [DEBUG] [$i] ${notif.title} - ${notif.payload} - Leída: ${notif.isRead}');
  }
  print('🔍 [DEBUG] ===============================================');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Notificaciones'),
        actions: [
             // ✅ AGREGAR botón de debug
        IconButton(
          icon: const Icon(Icons.bug_report),
          tooltip: 'Debug',
          onPressed: _debugNotificationCenter,
        ),
        // ✅ AGREGAR botón de test
        IconButton(
          icon: const Icon(Icons.science),
          tooltip: 'Test Notification',
          onPressed: () async {
            print('🧪 [TEST] Enviando notificación de prueba');
            await _notificationService.showTestNotification();
          },
        ),

          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Borrar todas',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: notification.isRead ? null : Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
                      child: Icon(
                        _getNotificationIcon(notification.payload),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _handleNotificationTap(notification),
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(String payload) {
    if (payload.startsWith('contract_generated_')) {
      return Icons.description;
    } else if (payload.startsWith('payment_received_')) {
      return Icons.payment;
    } else if (payload.startsWith('request_status_')) {
      return Icons.home;
    } else {
      return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Justo ahora';
    }
  }
}