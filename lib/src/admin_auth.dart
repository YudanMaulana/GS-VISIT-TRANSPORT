/// Sesi autentikasi admin GS VISIT TRANSPORT.
/// Mengelola informasi akun admin yang sedang login dan token sesi.
/// Berlaku terus selama terdaftar aktif di server atau sampai logout.
class AdminSession {
  DateTime? _unlockedAt;
  String _email = '';
  String _fullName = '';
  String _role = 'admin_transport';
  int? _branchId;
  String _token = '';

  /// Sesi aktif jika email tidak kosong
  bool get isUnlocked => _email.isNotEmpty;

  DateTime? get unlockedAt => _unlockedAt;
  String get email => _email;
  String get fullName => _fullName;
  String get role => _role;
  int? get branchId => _branchId;
  String get token => _token;

  /// Buka sesi setelah server memverifikasi kredensial Google
  void unlockFromServer({
    required String email,
    String? fullName,
    String? role,
    int? branchId,
    String? token,
  }) {
    _email = email.trim();
    _fullName = fullName?.trim() ?? '';
    _role = role?.trim() ?? 'admin_transport';
    _branchId = branchId;
    _token = token?.trim() ?? '';
    _unlockedAt = DateTime.now();
  }

  bool unlockFromStoredSession({
    required String email,
    String? fullName,
    String? role,
    int? branchId,
    String? token,
  }) {
    if (email.trim().isEmpty) return false;
    unlockFromServer(
      email: email,
      fullName: fullName,
      role: role,
      branchId: branchId,
      token: token,
    );
    return true;
  }

  void touch() {
    _unlockedAt = DateTime.now();
  }

  void lock() {
    _unlockedAt = null;
    _email = '';
    _fullName = '';
    _role = '';
    _branchId = null;
    _token = '';
  }
}
