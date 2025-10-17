import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_service.dart';
import 'UrlConfigProvider.dart';

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;
  bool _isConnected = false;
  //final NotificationService _notificationService = NotificationService();
  late NotificationService _notificationService;
  late UrlConfigProvider _urlConfigProvider;

  // Connection status
  SocketConnectionStatus _connectionStatus = SocketConnectionStatus.disconnected;
  final _connectionStatusController = StreamController<SocketConnectionStatus>.broadcast();

  // Reconnection settings
  bool _autoReconnect = true;
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 10;
  Duration _baseReconnectInterval = const Duration(seconds: 2);
  Duration _maxReconnectInterval = const Duration(minutes: 2);
  Timer? _reconnectTimer;

  // Heartbeat settings
  Timer? _heartbeatTimer;
  Duration _heartbeatInterval = const Duration(seconds: 30);
  int _missedHeartbeats = 0;
  int _maxMissedHeartbeats = 2;

  // Connection quality monitoring
  int _latencyMs = 0;
  List<int> _latencyHistory = [];
  int _maxLatencyHistorySize = 10;
  DateTime? _lastPingSent;
  final _latencyController = StreamController<int>.broadcast();

  // Connection statistics
  DateTime? _connectedSince;
  int _totalReconnects = 0;
  int _totalMessages = 0;
  int _totalPings = 0;
  int _totalPongs = 0;
  String _lastError = '';
  bool _wasConnected = false; // Track if we were ever connected

  // Stream controllers for different events
  final _contractGeneratedController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestStatusChangedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams that can be listened to from anywhere in the app
  Stream<Map<String, dynamic>> get onContractGenerated => _contractGeneratedController.stream;
  Stream<Map<String, dynamic>> get onPaymentReceived => _paymentReceivedController.stream;
  Stream<Map<String, dynamic>> get onRequestStatusChanged => _requestStatusChangedController.stream;
  Stream<SocketConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<int> get latency => _latencyController.stream;

  // Private constructor
  SocketService._internal();

  // Agregar este getter público después de la línea 69
  bool get isConnected => _isConnected;

  // Factory constructor to return the same instance
  factory SocketService() {
    return _instance;
  }

  // Configure the URL config provider (must be called before initialize)
  void setUrlConfigProvider(UrlConfigProvider provider) {
    _urlConfigProvider = provider;
  }

  // Initialize and connect to the socket server
void initialize() {
  if (_isConnected) return;

  // ✅ AGREGAR esta línea al inicio del método
    _notificationService = NotificationService();

  _updateConnectionStatus(SocketConnectionStatus.connecting);
  final socketUrl = _urlConfigProvider.currentBaseUrlSocket; //'https://socketserverfpl.up.railway.app';
  debugPrint('Connecting to socket server at: $socketUrl');

  try {

     // Deshabilitar auto-reconnect temporalmente
    //_autoReconnect = false;
    // CONFIGURACIÓN EXPLÍCITA para evitar puertos aleatorios
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'], // Permitir fallback a polling
      'autoConnect': true,
      'forceNew': false,
      'timeout': 10000,
      'reconnection': false, // Manejamos reconexión manualmente
    });

    _socket.onConnect((_) {
      debugPrint('✅ Socket connected successfully to $socketUrl');
      _isConnected = true;
      _connectedSince = DateTime.now();
      _reconnectAttempts = 0;
      _cancelReconnectTimer();
      _updateConnectionStatus(SocketConnectionStatus.connected);
      _wasConnected = true;
      _startHeartbeat();
      _sendPing();
    });

    _socket.onDisconnect((_) {
      debugPrint('❌ Socket disconnected');
      _isConnected = false;
      _updateConnectionStatus(SocketConnectionStatus.disconnected);
      _stopHeartbeat();
      if (_autoReconnect) {
        _attemptReconnect();
      }
    });

    _socket.onError((error) {
      debugPrint('❌ Socket error: $error');
      _lastError = 'Error: $error';
      _updateConnectionStatus(SocketConnectionStatus.error);
    });

    _socket.onConnectError((error) {
      debugPrint('❌ Socket connect error: $error');
      _lastError = 'Connect error: $error';
      _updateConnectionStatus(SocketConnectionStatus.error);
      if (_autoReconnect) {
        _attemptReconnect();
      }
    });

    // Event listeners
    _socket.on('contract-generated', (data) {
      debugPrint('✅ Contract generated: $data');
      _totalMessages++;
      _contractGeneratedController.add(data);

       // ✅ AGREGAR: Mostrar notificación
      _notificationService.showContractGeneratedNotification(
        solicitudId: data['solicitud_id'] ?? data['solicitudId'] ?? 1,
        propertyName: data['property_name'] ?? data['propertyName'] ?? 'Propiedad',
        
      );


    });

    _socket.on('payment-received', (data) {
      debugPrint('✅ Payment received: $data');
      _totalMessages++;
      _paymentReceivedController.add(data);

       // ✅ AGREGAR: Mostrar notificación
      _notificationService.showPaymentReceivedNotification(
        contratoId: data['contrato_id'] ?? data['contratoId'] ?? 1,
        propertyName: data['property_name'] ?? data['propertyName'] ?? 'Propiedad',
        amount: (data['amount'] ?? 0.0).toDouble(),
        userType: 'propietario',
      );

    });

    _socket.on('request-status-changed', (data) {
      debugPrint('✅ Request status changed: $data');
      _totalMessages++;
      _requestStatusChangedController.add(data);


      // ✅ CORREGIR: Usar el userType del evento o determinarlo por el status
      String targetUserType = 'cliente';

      // Si el status es 'pendiente', la notificación va al propietario
      // Si el status es 'aprobada'/'rechazada', va al cliente
      if (data['status'] == 'pendiente') {
        targetUserType = 'propietario';
      }

      // ✅ AGREGAR: Mostrar notificación
      _notificationService.showRequestStatusChangedNotification(
        solicitudId: data['solicitud_id'] ?? data['solicitudId'] ?? 1,
        propertyName: data['property_name'] ?? data['propertyName'] ?? 'Propiedad',
        status: data['status'] ?? 'actualizada',
        userType: targetUserType, 
      );


    });

    // CONECTAR EXPLÍCITAMENTE
    _socket.connect();
    debugPrint('Socket connection initiated explicitly');

  } catch (e) {
    debugPrint('❌ Error initializing socket: $e');
    _lastError = e.toString();
    _updateConnectionStatus(SocketConnectionStatus.error);
  }
}



  // Update connection status and notify listeners
  void _updateConnectionStatus(SocketConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  // Start heartbeat timer to detect silent disconnections
  void _startHeartbeat() {
    _stopHeartbeat(); // Stop any existing heartbeat timer
    _missedHeartbeats = 0;

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (!_isConnected) {
        _stopHeartbeat();
        return;
      }

      // Send heartbeat to server
      _socket.emit('heartbeat', {
        'timestamp': DateTime.now().toIso8601String(),
        'clientId': 'flutter-client',
      });

      _missedHeartbeats++;
      debugPrint('Sent heartbeat (missed: $_missedHeartbeats/$_maxMissedHeartbeats)');

      // If we've missed too many heartbeats, consider the connection dead
      if (_missedHeartbeats >= _maxMissedHeartbeats) {
        debugPrint('Too many missed heartbeats, reconnecting...');
        _stopHeartbeat();

        // Force disconnect and reconnect
        if (_isConnected) {
          _socket.disconnect();
          // The onDisconnect handler will trigger reconnection
        } else {
          _attemptReconnect();
        }
      }
    });
  }

  // Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send ping to measure latency
  void _sendPing() {
    if (!_isConnected) return;

    _lastPingSent = DateTime.now();
    _totalPings++;

    _socket.emit('ping', {
      'timestamp': _lastPingSent!.toIso8601String(),
      'sequence': _totalPings,
    });

    debugPrint('Sent ping #$_totalPings');
  }

  // Calculate average latency from history
  int getAverageLatency() {
    if (_latencyHistory.isEmpty) return 0;

    final sum = _latencyHistory.reduce((a, b) => a + b);
    return sum ~/ _latencyHistory.length;
  }

  // Attempt to reconnect to the socket server with exponential backoff
  void _attemptReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    _reconnectAttempts++;
    _totalReconnects++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached ((_maxReconnectAttempts))');
      _updateConnectionStatus(SocketConnectionStatus.error);
      return;
    }

    _updateConnectionStatus(SocketConnectionStatus.reconnecting);

    // Calculate delay with exponential backoff and jitter
    final baseDelay = _baseReconnectInterval.inMilliseconds;
    final maxDelay = _maxReconnectInterval.inMilliseconds;

    // Exponential backoff: delay = baseDelay * 2^(attempts-1)
    int delay = baseDelay * math.pow(2, _reconnectAttempts - 1).toInt();

    // Add jitter to prevent reconnection storms (±20%)
    final jitter = (delay * 0.2 * (math.Random().nextDouble() * 2 - 1)).toInt();
    delay = (delay + jitter).clamp(baseDelay, maxDelay);

    debugPrint('Attempting to reconnect (${_reconnectAttempts}/${_maxReconnectAttempts}) in ${delay}ms...');

    // Schedule reconnect attempt
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!_isConnected) {
        initialize();
      }
    });
  }

  // Cancel reconnect timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Join a room for a specific user
  void joinUserRoom(int userId) {
    if (!_isConnected) initialize();
    _socket.emit('join-user-room', userId);
    debugPrint('Joined user room: $userId');
  }

  // Leave a room for a specific user
  void leaveUserRoom(int userId) {
    if (!_isConnected) return;
    _socket.emit('leave-user-room', userId);
    debugPrint('Left user room: $userId');
  }

  // Join a room for a specific property
  void joinPropertyRoom(int inmuebleId) {
    if (!_isConnected) initialize();
    _socket.emit('join-property-room', inmuebleId);
    debugPrint('Joined property room: $inmuebleId');
  }

  // Leave a room for a specific property
  void leavePropertyRoom(int inmuebleId) {
    if (!_isConnected) return;
    _socket.emit('leave-property-room', inmuebleId);
    debugPrint('Left property room: $inmuebleId');
  }

  // Emit contract generated event
  void emitContractGenerated({
    required int solicitudId,
    required int contratoId,
    required String propertyName,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('contract-generated', {
      'solicitudId': solicitudId,
      'contratoId': contratoId,
      'propertyName': propertyName,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Emit payment received event
  void emitPaymentReceived({
    required int contratoId,
    required String propertyName,
    required double amount,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('payment-received', {
      'contratoId': contratoId,
      'propertyName': propertyName,
      'amount': amount,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Emit request status changed event
  void emitRequestStatusChanged({
    required int solicitudId,
    required String propertyName,
    required String status,
    required int clientId,
    required int propietarioId,
  }) {
    if (!_isConnected) initialize();
    _socket.emit('request-status-changed', {
      'solicitudId': solicitudId,
      'propertyName': propertyName,
      'status': status,
      'clientId': clientId,
      'propietarioId': propietarioId,
      'timestamp': DateTime.now().toIso8601String(),
    });

// ✅ AGREGAR este log para debug:
  debugPrint('🚀 Emitiendo socket: request-status-changed');
  debugPrint('📤 Datos: solicitudId=$solicitudId, propertyName=$propertyName, status=$status');


  }

  // Manually reconnect to the socket server
  void reconnect() {
    disconnect();
    _reconnectAttempts = 0;
    initialize();
  }

  // Configure auto-reconnect settings
  void configureReconnect({
    bool? autoReconnect,
    int? maxAttempts,
    Duration? baseInterval,
    Duration? maxInterval,
  }) {
    if (autoReconnect != null) _autoReconnect = autoReconnect;
    if (maxAttempts != null) _maxReconnectAttempts = maxAttempts;
    if (baseInterval != null) _baseReconnectInterval = baseInterval;
    if (maxInterval != null) _maxReconnectInterval = maxInterval;

    debugPrint('Reconnect settings updated: autoReconnect=$_autoReconnect, maxAttempts=$_maxReconnectAttempts, '
        'baseInterval=${_baseReconnectInterval.inSeconds}s, maxInterval=${_maxReconnectInterval.inSeconds}s');
  }

 /* // ✅ AGREGAR este método en tu SocketService (después de la línea 400)
void testNotifications() {
  debugPrint('🧪 Testing notifications manually...');
  
  // Probar notificación de contrato
  _notificationService.showContractGeneratedNotification(
    solicitudId: 999,
    propertyName: 'Casa de Prueba Manual',
  );
  
  // Probar notificación de pago después de 3 segundos
  Timer(Duration(seconds: 3), () {
    _notificationService.showPaymentReceivedNotification(
      contratoId: 999,
      propertyName: 'Casa de Prueba Manual',
      amount: 1500.75,
    );
  });
  
  // Probar cambio de estado después de 6 segundos
  Timer(Duration(seconds: 6), () {
    _notificationService.showRequestStatusChangedNotification(
      solicitudId: 999,
      propertyName: 'Casa de Prueba Manual',
      status: 'aprobada',
    );
  });
}

// ✅ AGREGAR este método después de testNotifications():
void requestTestFromServer(String type) {
  if (!_isConnected) {
    debugPrint('❌ Socket not connected, cannot request test');
    return;
  }
  
  debugPrint('🧪 Requesting test notification from server: $type');
  _socket.emit('test-notification', type);
}

void testAllFromServer() {
  if (!_isConnected) return;
  
  requestTestFromServer('contract');
  
  Timer(Duration(seconds: 3), () {
    requestTestFromServer('payment');
  });
  
  Timer(Duration(seconds: 6), () {
    requestTestFromServer('status');
  });
}*/




  // Configure heartbeat settings
  void configureHeartbeat({
    Duration? interval,
    int? maxMissed,
  }) {
    bool restartHeartbeat = false;

    if (interval != null && interval != _heartbeatInterval) {
      _heartbeatInterval = interval;
      restartHeartbeat = true;
    }

    if (maxMissed != null) {
      _maxMissedHeartbeats = maxMissed;
    }

    debugPrint('Heartbeat settings updated: interval=${_heartbeatInterval.inSeconds}s, maxMissed=$_maxMissedHeartbeats');

    // Restart heartbeat if needed and connected
    if (restartHeartbeat && _isConnected) {
      _startHeartbeat();
    }
  }

  // Get current connection status
  SocketConnectionStatus getConnectionStatus() {
    return _connectionStatus;
  }

  // Manually send a ping to test connection and measure latency
  void testConnection() {
    if (!_isConnected) {
      debugPrint('Cannot test connection: not connected');
      return;
    }

    _sendPing();
    debugPrint('Connection test initiated');
  }

  // Clear connection statistics
  void clearConnectionStats() {
    _latencyHistory.clear();
    _totalPings = 0;
    _totalPongs = 0;
    _totalReconnects = 0;
    _totalMessages = 0;
    _lastError = '';

    debugPrint('Connection statistics cleared');
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'connectionStatus': _connectionStatus.toString(),
      'connectedSince': _connectedSince?.toIso8601String(),
      'connectionDuration': _connectedSince != null 
          ? DateTime.now().difference(_connectedSince!).toString() 
          : null,
      'totalReconnects': _totalReconnects,
      'totalMessages': _totalMessages,
      'totalPings': _totalPings,
      'totalPongs': _totalPongs,
      'currentLatency': _latencyMs,
      'averageLatency': getAverageLatency(),
      'latencyHistory': _latencyHistory,
      'missedHeartbeats': _missedHeartbeats,
      'lastError': _lastError,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'autoReconnect': _autoReconnect,
      'wasEverConnected': _wasConnected,
      'socketUrl': _urlConfigProvider.currentBaseUrlSocket,
      'heartbeatInterval': _heartbeatInterval.inSeconds,
      'reconnectBaseInterval': _baseReconnectInterval.inSeconds,
      'reconnectMaxInterval': _maxReconnectInterval.inSeconds,
    };
  }

  // Get connection quality rating (0-100)
  int getConnectionQuality() {
    if (!_isConnected) return 0;
    if (_latencyHistory.isEmpty) return 50; // Default if no data

    // Calculate average latency
    final avgLatency = getAverageLatency();

    // Calculate quality score based on latency
    // < 50ms: Excellent (90-100)
    // 50-100ms: Good (70-90)
    // 100-200ms: Fair (50-70)
    // 200-500ms: Poor (30-50)
    // > 500ms: Bad (0-30)
    int qualityScore;
    if (avgLatency < 50) {
      qualityScore = 90 + ((50 - avgLatency) * 10 ~/ 50);
    } else if (avgLatency < 100) {
      qualityScore = 70 + ((100 - avgLatency) * 20 ~/ 50);
    } else if (avgLatency < 200) {
      qualityScore = 50 + ((200 - avgLatency) * 20 ~/ 100);
    } else if (avgLatency < 500) {
      qualityScore = 30 + ((500 - avgLatency) * 20 ~/ 300);
    } else {
      qualityScore = math.max(0, 30 - (avgLatency - 500) ~/ 100);
    }

    // Adjust for reconnects and missed heartbeats
    if (_totalReconnects > 0) {
      qualityScore = (qualityScore * 0.9).toInt(); // 10% penalty for each reconnect
    }

    if (_missedHeartbeats > 0) {
      qualityScore = (qualityScore * (1 - (_missedHeartbeats * 0.1))).toInt(); // 10% penalty per missed heartbeat
    }

    return qualityScore.clamp(0, 100);
  }

  // Disconnect from the socket server
  void disconnect() {
    _cancelReconnectTimer();
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      _updateConnectionStatus(SocketConnectionStatus.disconnected);
    }
  }

  // Dispose resources
  void dispose() {
    debugPrint('Disposing SocketService');

    // Stop timers
    _cancelReconnectTimer();
    _stopHeartbeat();

    // Close all stream controllers
    _connectionStatusController.close();
    _contractGeneratedController.close();
    _paymentReceivedController.close();
    _requestStatusChangedController.close();
    _latencyController.close();

    // Disconnect from socket
    disconnect();

    debugPrint('SocketService disposed');
  }
}
