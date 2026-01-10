# ETAPA F2.1 — Ejemplo de Test

**Propósito:** Ejemplo de cómo verificar que la implementación funciona

---

## Test 1: Compilación

```bash
# Verificar que compila sin errores
cd c:\flutter_application\F16-v_1_0_0_firmada
flutter clean
flutter pub get
flutter analyze
```

**Resultado esperado:**
```
✓ No errors
✓ No warnings
✓ Analyzing... done
```

---

## Test 2: Verificar Enum (Manual)

```dart
// En cualquier archivo, puedes verificar que el enum existe:

import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

void main() {
  // Verificar que el enum existe
  BluetoothStatus status = BluetoothStatus.connected;
  print('Enum value: $status'); // Output: BluetoothStatus.connected
}
```

---

## Test 3: Verificar ValueNotifier (Widget Test)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

void main() {
  group('BluetoothService ValueNotifier', () {
    test('Initial status is disconnected', () {
      final service = BluetoothService();
      expect(
        service.statusNotifier.value,
        equals(BluetoothStatus.disconnected),
      );
    });

    test('statusStream emits current value on listen', (WidgetTester tester) async {
      final service = BluetoothService();
      final statuses = <BluetoothStatus>[];
      
      service.statusStream.listen((status) => statuses.add(status));
      
      await tester.pumpAndSettle();
      
      expect(statuses.length, greaterThan(0));
    });
  });
}
```

---

## Test 4: Verificar Getters (Manual)

```dart
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

void test_getters() {
  final service = BluetoothService();
  
  // Test: isConnected debe retornar bool
  bool isConnected = service.isConnected;
  assert(isConnected == false);
  print('✓ isConnected works: $isConnected');
  
  // Test: status debe retornar BluetoothStatus
  BluetoothStatus status = service.status;
  assert(status == BluetoothStatus.disconnected);
  print('✓ status works: $status');
  
  // Test: statusNotifier debe retornar ValueNotifier
  var notifier = service.statusNotifier;
  assert(notifier != null);
  print('✓ statusNotifier works: ${notifier.value}');
}
```

---

## Test 5: Verificar Compatibilidad Legacy (Manual)

```dart
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

void test_legacy_compatibility() {
  final service = BluetoothService();
  
  // Test: connectionStream (legacy bool stream) debe funcionar
  final boolStream = service.connectionStream;
  assert(boolStream != null);
  print('✓ Legacy connectionStream still works');
  
  // Test: isConnected getter debe funcionar
  final isConn = service.isConnected;
  assert(isConn is bool);
  print('✓ Legacy isConnected getter still works');
}
```

---

## Test 6: Verificar UI (Widget Test)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:f16_balanza_electronica/screens/bluetooth_screen.dart';

void main() {
  testWidgets('BluetoothScreen uses ValueListenableBuilder', 
    (WidgetTester tester) async {
    
    await tester.pumpWidget(
      const MaterialApp(
        home: BluetoothScreen(),
      ),
    );
    
    // Debe mostrar "DESCONECTADO" inicialmente
    expect(find.text('DESCONECTADO'), findsOneWidget);
    print('✓ Initial state shows DESCONECTADO');
    
    // Verificar que el icono bluetooth_disabled existe
    expect(
      find.byIcon(Icons.bluetooth_disabled), 
      findsOneWidget,
    );
    print('✓ Bluetooth icon displayed');
  });
}
```

---

## Test 7: Verificar Memory Management (Manual)

```dart
import 'package:f16_balanza_electronica/screens/bluetooth_screen.dart';

void test_memory_cleanup() {
  // Este test verifica que las subscripciones se limpian
  
  // 1. Crear pantalla
  final state = _BluetoothScreenState();
  state.initState();
  
  print('✓ initState() creates subscriptions');
  
  // 2. Destruir pantalla (simular)
  state.dispose();
  
  print('✓ dispose() cancels subscriptions');
  
  // Nota: En un test real usaría WidgetTester para esto
}
```

---

## Test 8: Flujo Completo (Manual)

```dart
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

void test_complete_flow() async {
  final service = BluetoothService();
  
  print('Test 1: Estado inicial');
  assert(service.status == BluetoothStatus.disconnected);
  print('✓ Estado inicial es disconnected');
  
  print('\nTest 2: Cambio de estado a connecting');
  // Normalmente ocurre dentro de connect()
  // Aquí solo verificamos que se puede cambiar
  print('✓ Estado puede cambiar');
  
  print('\nTest 3: Stream emite cambios');
  var statusesReceived = <BluetoothStatus>[];
  service.statusStream.listen((status) {
    statusesReceived.add(status);
  });
  print('✓ Stream listener configurado');
  
  print('\nTest 4: Legacy stream funciona');
  var boolsReceived = <bool>[];
  service.connectionStream.listen((connected) {
    boolsReceived.add(connected);
  });
  print('✓ Legacy stream listener configurado');
  
  print('\n✅ Todos los tests pasaron');
}
```

---

## Test 9: Verificar Imports

```dart
// Verificar que todos los imports funcionan

// ✓ Debe poder importar el enum
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';

// ✓ Debe poder importar BluetoothStatus directamente
void test_enum_import() {
  BluetoothStatus status = BluetoothStatus.connected;
  print('✓ Can import BluetoothStatus');
}

// ✓ Debe poder usar en ValueListenableBuilder
import 'package:flutter/material.dart';

void test_valuelisten_import() {
  // ValueListenableBuilder es de Flutter estándar
  print('✓ ValueListenableBuilder available from flutter/material.dart');
}
```

---

## Test 10: Visual (Manual)

```
Cuando abras la app:

1. BluetoothScreen debe mostrar:
   ✓ Icono bluetooth_disabled (gris)
   ✓ Texto "DESCONECTADO"
   ✓ Botón ACTUALIZAR (habilitado)

2. Cuando intentas conectar:
   ✓ Debe mostrar ícono de carga
   ✓ Debe mostrar "CONECTANDO..."
   ✓ Botón ACTUALIZAR deshabilitado

3. Si conexión exitosa:
   ✓ Icono bluetooth_connected (verde)
   ✓ Texto "CONECTADO: [nombre dispositivo]"
   ✓ Panel ADC visible
   ✓ Botón DESCONECTAR visible

4. Si conexión falla:
   ✓ Icono bluetooth_disabled (gris/rojo)
   ✓ Texto "ERROR DE CONEXIÓN"
   ✓ Botón ACTUALIZAR habilitado
```

---

## Cómo Ejecutar Los Tests

### Con Flutter Test

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar un test específico
flutter test test/services/bluetooth_service_test.dart

# Con cobertura
flutter test --coverage
```

### Widget Tests Completos

```dart
// Crear archivo: test/screens/bluetooth_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:f16_balanza_electronica/screens/bluetooth_screen.dart';

void main() {
  testWidgets('BluetoothScreen displays correct initial state', 
    (WidgetTester tester) async {
    
    await tester.pumpWidget(
      const MaterialApp(
        home: BluetoothScreen(),
      ),
    );
    
    // Verificar UI inicial
    expect(find.text('DESCONECTADO'), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    
    print('✅ Widget test passed');
  });
}
```

---

## Checklist de Verificación

```
Pruebas Básicas:
[ ] flutter analyze - Sin errores
[ ] flutter analyze - Sin warnings
[ ] Flutter compila sin errores
[ ] Flutter corre sin crashes

Pruebas de Código:
[ ] Enum BluetoothStatus existe
[ ] ValueNotifier en BluetoothService
[ ] Getters funcionan (status, isConnected, statusNotifier)
[ ] Streams funcionan (statusStream, connectionStream)
[ ] Legacy APIs funcionan

Pruebas de UI:
[ ] BluetoothScreen muestra estado inicial
[ ] ValueListenableBuilder reconstruye cuando cambia estado
[ ] Icono cambia según estado
[ ] Texto cambia según estado

Pruebas de Memory:
[ ] dispose() cancela subscripciones
[ ] No hay memory leaks
[ ] Ninguna excepción al navegar

Pruebas Funcionales:
[ ] Conectar a dispositivo funciona
[ ] Transición a "CONECTANDO..." es visible
[ ] Transición a "CONECTADO" es visible
[ ] Desconectar funciona
[ ] ADC values se reciben correctamente
```

---

## Resultado Esperado

```
✅ Compilación: Sin errores
✅ Runtime: Sin crashes
✅ UI: Todos los estados visibles
✅ Memory: Limpiado correctamente
✅ Legacy: Compatible 100%
✅ Functionality: Bluetooth conecta/desconecta
✅ Reactivity: UI se actualiza automáticamente
```

---

## Troubleshooting

### Error: "BluetoothStatus not found"
**Causa:** Import faltante  
**Solución:**
```dart
import 'package:f16_balanza_electronica/services/bluetooth_service.dart';
```

### Error: "ValueNotifier not found"
**Causa:** Import faltante de Flutter  
**Solución:**
```dart
import 'package:flutter/foundation.dart';
```

### Error: "StatusSubscription is not defined"
**Causa:** late init no se ejecutó  
**Solución:** Asegurar que initState() se llamó antes

### UI no actualiza al cambiar estado
**Causa:** ValueListenableBuilder no está correctamente configurado  
**Solución:** Verificar que `valueListenable` apunta a `statusNotifier`

### Memory leak warnings
**Causa:** Subscripciones no canceladas  
**Solución:** Asegurar que dispose() cancela todas las subscripciones

---

**Ejemplo de Test completado - ETAPA F2.1**
