import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_service.dart';

enum ReverbConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  late NotificationService _notificationService;

  // Connection status
  ReverbConnectionStatus _connectionStatus = ReverbConnectionStatus.disconnected;
  final _connectionStatusController = StreamController<ReverbConnectionStatus>.broadcast();

  // Stream controllers for events
  final _contractGeneratedController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestStatusChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _deviceStatusChangedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<Map<String, dynamic>> get onContractGenerated => _contractGeneratedController.stream;
  Stream<Map<String, dynamic>> get onPaymentReceived => _paymentReceivedController.stream;
  Stream<Map<String, dynamic>> get onRequestStatusChanged => _requestStatusChangedController.stream;
  Stream<Map<String, dynamic>> get onDeviceStatusChanged => _deviceStatusChangedController.stream;
  Stream<ReverbConnectionStatus> get connectionStatus => _connectionStatusController.stream;

  // Getters
  bool get isConnected => _isConnected;
  ReverbConnectionStatus get status => _connectionStatus;

  // Subscribed channels
  final Set<String> _subscribedChannels = {};

  // Private constructor
  ReverbService._internal();

  // Factory
  factory ReverbService() {
    return _instance;
  }

  /// Initialize and connect to Laravel Reverb
  Future<void> initialize() async {
    if (_isConnected) return;

    _notificationService = NotificationService();
    _updateConnectionStatus(ReverbConnectionStatus.connecting);

    try {
      // Get configuration from .env
      final reverbHost = dotenv.env['REVERB_HOST'] ?? '192.168.100.9';
      final reverbPort = int.parse(dotenv.env['REVERB_PORT'] ?? '8080');
      final reverbAppKey = dotenv.env['REVERB_APP_KEY'] ?? '3heg5mmtgkhuzwpc0udd';

      final wsUrl = 'ws://$reverbHost:$reverbPort/app/$reverbAppKey?protocol=7&client=js&version=8.4.0-rc2&flash=false';

      debugPrint('🔌 Connecting to Reverb at $wsUrl');

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to connection
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
        cancelOnError: false,
      );

      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;
      _updateConnectionStatus(ReverbConnectionStatus.connected);

      debugPrint('✅ Reverb initialized successfully');

      // ✅ No suscribirse a canal global - usar solo canales específicos por usuario
      // subscribeToChannel('rentals'); // ELIMINADO - causaba que todos reciban todas las notificaciones

    } catch (e) {
      debugPrint('❌ Error initializing Reverb: $e');
      _updateConnectionStatus(ReverbConnectionStatus.error);
    }
  }

  /// Subscribe to a channel
  void subscribeToChannel(String channelName) {
    if (!_isConnected) {
      debugPrint('⚠️ Cannot subscribe to $channelName: not connected');
      return;
    }

    if (_subscribedChannels.contains(channelName)) {
      debugPrint('ℹ️ Already subscribed to $channelName');
      return;
    }

    try {
      final subscribeMessage = jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName}
      });

      _channel?.sink.add(subscribeMessage);
      _subscribedChannels.add(channelName);

      debugPrint('📡 Subscribed to channel: $channelName');
    } catch (e) {
      debugPrint('❌ Error subscribing to $channelName: $e');
    }
  }

  /// Subscribe to user-specific channel
  void subscribeToUserChannel(int userId) {
    subscribeToChannel('user.$userId');
  }

  /// Subscribe to property-specific channel for IoT
  void subscribeToPropertyChannel(int inmuebleId) {
    subscribeToChannel('inmueble.$inmuebleId');
  }

  /// Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      debugPrint('📨 Message received: ${data['event']}');

      // Handle different event types
      switch (data['event']) {
        case 'pusher:connection_established':
          debugPrint('✅ Connection established');
          _isConnected = true;
          _updateConnectionStatus(ReverbConnectionStatus.connected);
          break;

        case 'pusher:ping':
          debugPrint('🏓 Ping received, sending pong...');
          _sendPong();
          break;

        case 'pusher:error':
          debugPrint('❌ Reverb error: ${data['data']}');
          final errorData = jsonDecode(data['data'] ?? '{}');
          debugPrint('Error code: ${errorData['code']}');
          debugPrint('Error message: ${errorData['message']}');
          break;

        case 'pusher_internal:subscription_succeeded':
          debugPrint('✅ Subscription succeeded: ${data['channel']}');
          break;

        case 'request-status-changed':
          _handleRequestStatusChanged(jsonDecode(data['data'] ?? '{}'));
          break;

        case 'contract-generated':
          _handleContractGenerated(jsonDecode(data['data'] ?? '{}'));
          break;

        case 'payment-received':
          _handlePaymentReceived(jsonDecode(data['data'] ?? '{}'));
          break;

        case 'device-status-changed':
          _handleDeviceStatusChanged(jsonDecode(data['data'] ?? '{}'));
          break;

        default:
          // No loguear eventos pusher:* desconocidos
          if (!data['event'].toString().startsWith('pusher:')) {
            debugPrint('📨 Unknown event: ${data['event']}');
          }
      }
    } catch (e) {
      debugPrint('❌ Error parsing message: $e');
    }
  }

  /// Send pong response to pusher:ping
  void _sendPong() {
    try {
      final pongMessage = jsonEncode({
        'event': 'pusher:pong',
        'data': {}
      });

      _channel?.sink.add(pongMessage);
      debugPrint('🏓 Pong sent');
    } catch (e) {
      debugPrint('❌ Error sending pong: $e');
    }
  }

  /// Handle connection errors
  void _onError(error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    _updateConnectionStatus(ReverbConnectionStatus.error);
  }

  /// Handle disconnection
  void _onDisconnect() {
    debugPrint('🔌 Disconnected from Reverb');
    _isConnected = false;
    _subscribedChannels.clear();
    _updateConnectionStatus(ReverbConnectionStatus.disconnected);
  }

  /// Event Handlers
  void _handleRequestStatusChanged(Map<String, dynamic> data) {
    debugPrint('📥 Request status changed: $data');
    debugPrint('   - Solicitud ID: ${data['solicitud_id']}');
    debugPrint('   - Propiedad: ${data['property_name']}');
    debugPrint('   - Estado: ${data['status']}');
    debugPrint('   - Cliente ID: ${data['cliente_id']}');
    debugPrint('   - Propietario ID: ${data['propietario_id']}');

    _requestStatusChangedController.add(data);

    // Show notification
    final status = data['status'] ?? 'actualizada';
    final userType = status == 'pendiente' ? 'propietario' : 'cliente';

    _notificationService.showRequestStatusChangedNotification(
      solicitudId: data['solicitud_id'] ?? 0,
      propertyName: data['property_name'] ?? 'Propiedad',
      status: status,
      userType: userType,
    );
  }

  void _handleContractGenerated(Map<String, dynamic> data) {
    debugPrint('📥 Contract generated: $data');

    _contractGeneratedController.add(data);

    // Show notification
    _notificationService.showContractGeneratedNotification(
      solicitudId: data['solicitud_id'] ?? 0,
      propertyName: data['property_name'] ?? 'Propiedad',
    );
  }

  void _handlePaymentReceived(Map<String, dynamic> data) {
    debugPrint('📥 Payment received: $data');

    _paymentReceivedController.add(data);

    // Show notification
    _notificationService.showPaymentReceivedNotification(
      contratoId: data['contrato_id'] ?? 0,
      propertyName: data['property_name'] ?? 'Propiedad',
      amount: (data['amount'] ?? 0.0).toDouble(),
      userType: 'propietario',
    );
  }

  void _handleDeviceStatusChanged(Map<String, dynamic> data) {
    debugPrint('📥 Device status changed: $data');
    _deviceStatusChangedController.add(data);
  }

  /// Update connection status
  void _updateConnectionStatus(ReverbConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _isConnected = false;
      _subscribedChannels.clear();
      _updateConnectionStatus(ReverbConnectionStatus.disconnected);
      debugPrint('🔌 Disconnected from Reverb');
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  /// Dispose
  void dispose() {
    debugPrint('🗑️ Disposing ReverbService');

    _connectionStatusController.close();
    _contractGeneratedController.close();
    _paymentReceivedController.close();
    _requestStatusChangedController.close();
    _deviceStatusChangedController.close();

    disconnect();
  }
}
