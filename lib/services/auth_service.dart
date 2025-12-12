import 'dart:math';

/// ⚠️ ATENCIÓN: CONTRASEÑAS DE DEMO/BETA - CAMBIAR ANTES DE RELEASE OFICIAL
/// Las contraseñas están ofuscadas pero siguen siendo inseguras.
/// Para producción: implementar hash seguro (bcrypt/Argon2) o autenticación remota.
class AuthService {
  static const double _factorSecreto = 1.47;

  Future<bool> validateFixed(int input, int requiredValue) async {
    return input == requiredValue;
  }

  Future<int> generateDynamicKey() async {
    final Random random = Random();
    return 1000 + random.nextInt(9000);
  }

  Future<bool> validateDynamic(int input, int key) async {
    return input == (key * _factorSecreto).round();
  }
}
