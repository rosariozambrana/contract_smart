import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  bool _isInitialized = false;

  NotificationService._internal();
  factory NotificationService() => _instance;

  void Function({
    required int id,
    required String title,
    required String body,
    required String payload,
  })? _onNotificationReceived;

   static final List<Map<String, dynamic>> _pendingNotifications = [];

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('✅ OverlaySupport NotificationService initialized');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // ✅ Notificar al centro PRIMERO
    _notifyNotificationCenter(
      id: id,
      title: title,
      body: body,
      payload: payload ?? 'general_notification_$id',
    );

    showOverlayNotification(
      (context) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SafeArea(
            child: ListTile(
              leading: SizedBox.fromSize(
                size: const Size(40, 40),
                child: ClipOval(
                  child: Container(
                    color: Colors.blue,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                ),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(body),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => OverlaySupportEntry.of(context)?.dismiss(),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 4),
    );
    debugPrint('✅ Notification shown: $title');
  }

  Future<void> showContractGeneratedNotification({
    required int solicitudId,
    required String propertyName,
    String? userType, 
  }) async {
    // ✅ Notificar al centro PRIMERO
    _notifyNotificationCenter(
      id: solicitudId,
      title: '📄 Contrato Generado',
      body: 'Se ha generado un contrato para: $propertyName',
      payload: 'contract_generated_$solicitudId',
    );

    showOverlayNotification(
      (context) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SafeArea(
            child: ListTile(
              leading: SizedBox.fromSize(
                size: const Size(40, 40),
                child: ClipOval(
                  child: Container(
                    color: Colors.blue,
                    child: const Icon(Icons.description, color: Colors.white),
                  ),
                ),
              ),
              title: const Text('📄 Contrato Generado', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Se ha generado un contrato para: $propertyName'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => OverlaySupportEntry.of(context)?.dismiss(),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> showPaymentReceivedNotification({
    required int contratoId,
    required String propertyName,
    required double amount,
     required String userType,
  }) async {
    // ✅ AGREGAR: Notificar al centro PRIMERO
  _notifyNotificationCenter(
    id: contratoId,
    title: '💰 Pago Recibido',
    body: 'Pago de \$${amount.toStringAsFixed(2)} para: $propertyName',
    payload: 'payment_received_$contratoId',
    
  );
    showOverlayNotification(
      (context) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: SafeArea(
            child: ListTile(
              leading: SizedBox.fromSize(
                size: const Size(40, 40),
                child: ClipOval(
                  child: Container(
                    color: Colors.green,
                    child: const Icon(Icons.payment, color: Colors.white),
                  ),
                ),
              ),
              title: const Text('💰 Pago Recibido', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Pago de \$${amount.toStringAsFixed(2)} para: $propertyName'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => OverlaySupportEntry.of(context)?.dismiss(),
              ),
            ),
          ),
        );
      },
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> showRequestStatusChangedNotification({
    required int solicitudId,
    required String propertyName,
    required String status,
    required String userType,
  }) async {
    String statusText;
    String emoji;
    Color notificationColor;
    
    switch (status.toLowerCase()) {
      case 'aprobada':
        statusText = 'aprobada';
        emoji = '✅';
        notificationColor = Colors.green;
        break;
      case 'rechazada':
        statusText = 'rechazada';
        emoji = '❌';
        notificationColor = Colors.red;
        break;
      case 'anulada':
        statusText = 'anulada';
        emoji = '🚫';
        notificationColor = Colors.grey;
        break;
      case 'contrato_generado':
        statusText = 'procesada y se ha generado un contrato';
        emoji = '📄';
        notificationColor = Colors.blue;
        break;
      default:
        statusText = status;
        emoji = '🔔';
        notificationColor = Colors.blue;
    }

  String title;
  String body;

  // ✅ CORREGIR: Diferentes mensajes según el tipo de usuario
  if (userType.toLowerCase() == 'cliente') {
    title = '$emoji Solicitud Actualizada';
    body = 'Tu solicitud para "$propertyName" ha sido $statusText';
  } else if (userType.toLowerCase() == 'propietario') {
    title = '$emoji Nueva Solicitud';
    body = 'Has recibido una nueva solicitud para "$propertyName"';
  } else {
    title = '$emoji Solicitud';
    body = 'Solicitud para "$propertyName" - $statusText';
  }
    
      // ✅ Notificar al centro PRIMERO
   _notifyNotificationCenter(
    id: solicitudId,
    title: title,
    body: body,
    payload: 'request_status_$solicitudId',
    );

      showOverlayNotification(
        (context) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: SafeArea(
              child: ListTile(
                leading: SizedBox.fromSize(
                  size: const Size(40, 40),
                  child: ClipOval(
                    child: Container(
                      color: notificationColor,
                      child: const Icon(Icons.home, color: Colors.white),
                    ),
                  ),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(body),
                trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => OverlaySupportEntry.of(context)?.dismiss(),
                ),
              ),
            ),
          );
        },
        duration: const Duration(seconds: 4),
      );
      
      print('✅ [NotificationService] Notificación enviada a $userType');
 }

  void setNotificationCallback(void Function({
    required int id,
    required String title,
    required String body,
    required String payload,
  })? callback) {
    _onNotificationReceived = callback;
    
    if (callback != null) {
      print('✅ [NotificationService] Callback conectado exitosamente');
      print('✅ [NotificationService] Callback type: ${callback.runtimeType}');
      
      // ✅ PROCESAR notificaciones pendientes
      if (_pendingNotifications.isNotEmpty) {
        print('📦 [NotificationService] Procesando ${_pendingNotifications.length} notificaciones pendientes...');
        
        final notificationsToProcess = List.from(_pendingNotifications);
        _pendingNotifications.clear();
        
        for (final notification in notificationsToProcess) {
          try {
            print('📦 [NotificationService] Procesando pendiente: ${notification['title']}');
            callback(
              id: notification['id'],
              title: notification['title'],
              body: notification['body'],
              payload: notification['payload'],
            );
            print('✅ [NotificationService] Notificación pendiente procesada: ${notification['title']}');
          } catch (e) {
            print('❌ [NotificationService] Error procesando notificación pendiente: $e');
          }
        }
        
        print('🧹 [NotificationService] Buffer de ${notificationsToProcess.length} notificaciones procesado');
      }
    } else {
      print('⚠️ [NotificationService] Callback desconectado (null)');
    }
  }

 // ✅ REEMPLAZAR el método _notifyNotificationCenter:
  void _notifyNotificationCenter({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) {
    print('🔔 [NotificationService] Enviando al NotificationCenter: $title');
    print('🔔 [NotificationService] Callback estado: ${_onNotificationReceived != null ? 'CONECTADO' : 'NULL'}');
    
    if (_onNotificationReceived != null) {
      try {
        _onNotificationReceived!(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
        print('✅ [NotificationService] Notificación enviada al centro exitosamente');
      } catch (e) {
        print('❌ [NotificationService] Error enviando al centro: $e');
      }
    } else {
      print('! [NotificationService] No hay callback conectado - GUARDANDO EN BUFFER');
      
      // ✅ GUARDAR en buffer
      _pendingNotifications.add({
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('📦 [NotificationService] Notificación guardada en buffer');
      print('📦 [NotificationService] Total en buffer: ${_pendingNotifications.length}');
      print('📦 [NotificationService] ID: $id, Título: $title');
    }
  }

  // ✅ AGREGAR método para debug del buffer
  void debugBuffer() {
    print('🔍 [NotificationService] ===== ESTADO DEL BUFFER =====');
    print('🔍 [NotificationService] Callback conectado: ${_onNotificationReceived != null}');
    print('🔍 [NotificationService] Notificaciones en buffer: ${_pendingNotifications.length}');
    
    for (int i = 0; i < _pendingNotifications.length; i++) {
      final notif = _pendingNotifications[i];
      print('🔍 [NotificationService] [$i] ${notif['title']} (ID: ${notif['id']})');
    }
    print('🔍 [NotificationService] ===================================');
  }


  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'Esta es una notificación de prueba',
    );
  }
}