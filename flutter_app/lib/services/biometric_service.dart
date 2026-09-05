import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Result of a biometric / device-credential unlock attempt.
enum BiometricUnlockResult {
  success,
  failed,
  unavailable,
  canceled,
}

/// On-device biometric / PIN unlock (fingerprint, Face ID, Windows Hello).
class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  static final BiometricService instance = BiometricService();

  final LocalAuthentication _auth;

  /// True when the platform can offer biometrics or a device credential.
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final biometric = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return biometric || supported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String> availabilityMessage() async {
    if (kIsWeb) {
      return 'Biometric lock is not available on web. Use the mobile or desktop app.';
    }
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return 'This device does not support biometric or screen-lock authentication.';
      }
      final biometric = await _auth.canCheckBiometrics;
      if (!biometric) {
        return 'No biometrics enrolled. Add a fingerprint or face unlock in device settings, or use your device PIN.';
      }
      return 'Ready';
    } catch (_) {
      return 'Could not check biometric availability on this device.';
    }
  }

  Future<BiometricUnlockResult> authenticate({
    String reason = 'Unlock Pockify',
  }) async {
    if (kIsWeb) return BiometricUnlockResult.unavailable;

    final available = await canAuthenticate();
    if (!available) return BiometricUnlockResult.unavailable;

    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricUnlockResult.success : BiometricUnlockResult.failed;
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled ||
          e.code == LocalAuthExceptionCode.userRequestedFallback) {
        return BiometricUnlockResult.canceled;
      }
      if (e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          e.code == LocalAuthExceptionCode.noCredentialsSet) {
        return BiometricUnlockResult.unavailable;
      }
      return BiometricUnlockResult.failed;
    } on PlatformException {
      return BiometricUnlockResult.failed;
    } catch (_) {
      return BiometricUnlockResult.failed;
    }
  }
}
