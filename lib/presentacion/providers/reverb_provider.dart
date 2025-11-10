import 'package:flutter/material.dart';
import '../../datos/reverb_service.dart';

class ReverbProvider with ChangeNotifier {
  final ReverbService _reverbService = ReverbService();

  ReverbConnectionStatus _status = ReverbConnectionStatus.disconnected;
  Map<String, dynamic>? _lastEvent;

  // Getters
  ReverbConnectionStatus get status => _status;
  bool get isConnected => _status == ReverbConnectionStatus.connected;
  Map<String, dynamic>? get lastEvent => _lastEvent;

  ReverbProvider() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Listen to connection status
    _reverbService.connectionStatus.listen((status) {
      _status = status;
      notifyListeners();
    });

    // Listen to events
    _reverbService.onRequestStatusChanged.listen(_handleRequestStatusChanged);
    _reverbService.onContractGenerated.listen(_handleContractGenerated);
    _reverbService.onPaymentReceived.listen(_handlePaymentReceived);
    _reverbService.onDeviceStatusChanged.listen(_handleDeviceStatusChanged);

    // Initialize connection
    await _reverbService.initialize();
  }

  // Event handlers
  void _handleRequestStatusChanged(Map<String, dynamic> data) {
    debugPrint('Provider: Request status changed');
    _lastEvent = {'type': 'request-status-changed', 'data': data};
    notifyListeners();
  }

  void _handleContractGenerated(Map<String, dynamic> data) {
    debugPrint('Provider: Contract generated');
    _lastEvent = {'type': 'contract-generated', 'data': data};
    notifyListeners();
  }

  void _handlePaymentReceived(Map<String, dynamic> data) {
    debugPrint('Provider: Payment received');
    _lastEvent = {'type': 'payment-received', 'data': data};
    notifyListeners();
  }

  void _handleDeviceStatusChanged(Map<String, dynamic> data) {
    debugPrint('Provider: Device status changed');
    _lastEvent = {'type': 'device-status-changed', 'data': data};
    notifyListeners();
  }

  // Subscribe to user channel
  void subscribeToUser(int userId) {
    _reverbService.subscribeToUserChannel(userId);
  }

  // Subscribe to property channel
  void subscribeToProperty(int inmuebleId) {
    _reverbService.subscribeToPropertyChannel(inmuebleId);
  }

  // Disconnect
  Future<void> disconnect() async {
    await _reverbService.disconnect();
  }

  @override
  void dispose() {
    _reverbService.dispose();
    super.dispose();
  }
}
