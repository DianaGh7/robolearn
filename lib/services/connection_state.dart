/// Global singleton to manage robot connection state across the app.
/// 
/// This ensures the robot connection only happens once when the app starts,
/// and subsequent levels can skip the connection step by checking this state.
class ConnectionState {
  static final ConnectionState _instance = ConnectionState._internal();

  bool _isConnected = false;

  // Private constructor
  ConnectionState._internal();

  /// Singleton instance
  factory ConnectionState() {
    return _instance;
  }

  /// Check if robot is currently connected
  bool get isConnected => _isConnected;

  /// Mark robot as connected
  void markConnected() {
    _isConnected = true;
  }

  /// Mark robot as disconnected (e.g., on app restart, logout)
  void markDisconnected() {
    _isConnected = false;
  }

  /// Reset connection state
  void reset() {
    _isConnected = false;
  }
}
