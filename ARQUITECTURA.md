# 🏗️ Arquitectura de 3 Capas - Proyecto Rentals

## 📋 Tabla de Contenidos
1. [Introducción](#introducción)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Descripción de las Capas](#descripción-de-las-capas)
4. [Flujo de Comunicación](#flujo-de-comunicación)
5. [Reglas de la Arquitectura](#reglas-de-la-arquitectura)
6. [Mapeo de Archivos](#mapeo-de-archivos)
7. [Ejemplos de Uso](#ejemplos-de-uso)

---

## 📖 Introducción

Este proyecto implementa una **Arquitectura de 3 Capas** (Three-Tier Architecture), un patrón de diseño que separa la aplicación en tres niveles independientes:

1. **Capa de PRESENTACIÓN** - Interfaz de usuario
2. **Capa de NEGOCIO** - Lógica de negocio y reglas
3. **Capa de DATOS** - Acceso a datos (API, Blockchain, Base de datos)

### Principio Fundamental

```
PRESENTACIÓN → solo conoce → NEGOCIO
NEGOCIO → solo conoce → DATOS
DATOS → no conoce a nadie
```

**La arquitectura NO se rompe** porque:
- Presentación NO importa directamente de Datos
- El flujo de dependencias es unidireccional (de arriba hacia abajo)
- Cada capa tiene responsabilidades claramente definidas

---

## 📁 Estructura del Proyecto

```
lib/
├── datos/                              ← CAPA 1 (Datos)
│   ├── ApiService.dart
│   ├── blockchain_service.dart
│   ├── socket_service.dart
│   ├── notification_service.dart
│   ├── websocket_admin_service.dart
│   ├── ResponseHandler.dart
│   ├── UrlConfigProvider.dart
│   └── database/
│       ├── database.dart
│       ├── session_dao.dart
│       └── user_dao.dart
│
├── negocio/                            ← CAPA 2 (Negocio)
│   ├── models/                         ← Models AQUÍ (capa intermedia)
│   │   ├── inmueble_model.dart
│   │   ├── contrato_model.dart
│   │   ├── pago_model.dart
│   │   ├── user_model.dart
│   │   ├── solicitud_alquiler_model.dart
│   │   ├── galeria_inmueble_model.dart
│   │   ├── tipo_inmueble_model.dart
│   │   ├── servicio_basico_model.dart
│   │   ├── session_model.dart
│   │   ├── condicional_model.dart
│   │   └── response_model.dart
│   │
│   ├── AuthenticatedNegocio.dart
│   ├── ContratoNegocio.dart
│   ├── DashboardNegocio.dart
│   ├── InmuebleNegocio.dart
│   ├── PagoNegocio.dart
│   ├── SessionNegocio.dart
│   ├── SolicitudAlquilerNegocio.dart
│   └── UserNegocio.dart
│
└── presentacion/                       ← CAPA 3 (Presentación)
    ├── providers/
    │   ├── authenticated_provider.dart
    │   ├── blockchain_provider.dart
    │   ├── contrato_provider.dart
    │   ├── inmueble_provider.dart
    │   ├── pago_provider.dart
    │   ├── solicitud_alquiler_provider.dart
    │   └── user_global_provider.dart
    │
    ├── screens/
    │   ├── admin/
    │   ├── auth/
    │   ├── blockchain/
    │   ├── components/
    │   ├── home_cliente/
    │   ├── home_propietario/
    │   ├── inmueble/
    │   ├── interfaces/
    │   ├── notifications/
    │   └── pagos/
    │
    └── widgets/
        ├── blockchain_websocket_drawer.dart
        ├── notification_badge.dart
        └── websocket_status_widget.dart
```

---

## 🎯 Descripción de las Capas

### 1️⃣ Capa de DATOS (datos/)

**Responsabilidad:** Acceso a fuentes de datos externas (APIs REST, Blockchain, Base de datos local, Sockets).

**Archivos principales:**
- `ApiService.dart` - Cliente HTTP para comunicación con API REST
- `blockchain_service.dart` - Interacción con contratos inteligentes en Ethereum
- `socket_service.dart` - Comunicación en tiempo real con WebSockets
- `notification_service.dart` - Gestión de notificaciones push
- `database/` - Base de datos local SQLite (DAOs)

**NO contiene:**
- ❌ Lógica de negocio
- ❌ Validaciones de reglas de negocio
- ❌ Transformaciones complejas de datos

**SÍ contiene:**
- ✅ Llamadas HTTP (GET, POST, PUT, DELETE)
- ✅ Serialización/deserialización JSON
- ✅ Conexión con blockchain
- ✅ Operaciones CRUD en base de datos

**Imports permitidos:**
```dart
import 'package:http/http.dart';           // ✅ Librerías externas
import 'package:web3dart/web3dart.dart';   // ✅ Librerías externas
import '../negocio/models/response_model.dart';  // ✅ Models de negocio (para usar en respuestas)
```

**Imports NO permitidos:**
```dart
import '../presentacion/...';  // ❌ NO puede importar de presentación
import '../negocio/*Negocio.dart';  // ❌ NO debe conocer lógica de negocio
```

---

### 2️⃣ Capa de NEGOCIO (negocio/)

**Responsabilidad:** Contiene toda la lógica de negocio, validaciones y reglas del dominio de la aplicación.

**Archivos principales:**
- `InmuebleNegocio.dart` - Lógica para gestión de inmuebles
- `ContratoNegocio.dart` - Lógica para contratos de alquiler
- `PagoNegocio.dart` - Lógica para procesamiento de pagos
- `AuthenticatedNegocio.dart` - Lógica de autenticación y sesiones
- `models/` - Modelos de dominio (representan conceptos de negocio)

**Contiene:**
- ✅ Validaciones de negocio (ej: "un inmueble debe tener precio > 0")
- ✅ Transformaciones de datos
- ✅ Orquestación de múltiples servicios de datos
- ✅ Definición de modelos del dominio

**Ejemplo de lógica de negocio:**
```dart
// negocio/InmuebleNegocio.dart
class InmuebleNegocio {
  final ApiService apiService;  // ← Usa servicio de DATOS

  Future<ResponseModel> getInmuebles(String query) async {
    // Llama al servicio de datos
    ResponseModel response = await apiService.post('inmuebles/query', {'query': query});

    // Aquí podría haber validaciones adicionales, filtros, etc.

    return response;
  }
}
```

**Imports permitidos:**
```dart
import '../datos/ApiService.dart';           // ✅ Puede usar servicios de DATOS
import '../datos/blockchain_service.dart';   // ✅ Puede usar servicios de DATOS
import 'models/inmueble_model.dart';         // ✅ Usa sus propios models
```

**Imports NO permitidos:**
```dart
import '../presentacion/...';  // ❌ NO puede conocer la capa de presentación
```

---

### 3️⃣ Capa de PRESENTACIÓN (presentacion/)

**Responsabilidad:** Interfaz de usuario, gestión de estado y lógica de presentación.

**Subdivisiones:**

#### **a) Providers** (ViewModels / Controladores de estado)
Gestionan el estado de la UI y sirven de puente entre las vistas y la capa de negocio.

```dart
// presentacion/providers/inmueble_provider.dart
class InmuebleProvider extends ChangeNotifier {
  final InmuebleNegocio _inmuebleNegocio = InmuebleNegocio();  // ← Usa NEGOCIO

  List<InmuebleModel> _inmuebles = [];
  bool _isLoading = false;

  Future<void> loadInmuebles() async {
    isLoading = true;
    _responseModel = await _inmuebleNegocio.getInmuebles("");  // ← Llama a NEGOCIO
    inmuebles = InmuebleModel.fromList(_responseModel.data);
    notifyListeners();  // ← Notifica a la UI
  }
}
```

#### **b) Screens** (Pantallas/Vistas)
Interfaces de usuario que muestran datos y capturan interacciones del usuario.

```dart
// presentacion/screens/inmueble/inmueble_screen.dart
class InmuebleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InmuebleProvider>();  // ← Usa Provider

    return ListView.builder(
      itemCount: provider.inmuebles.length,
      itemBuilder: (context, index) {
        final inmueble = provider.inmuebles[index];
        return ListTile(
          title: Text(inmueble.titulo),
          subtitle: Text('\$${inmueble.precio}'),
        );
      },
    );
  }
}
```

#### **c) Widgets** (Componentes reutilizables)
Componentes UI reutilizables en múltiples pantallas.

**Imports permitidos:**
```dart
import '../../negocio/models/inmueble_model.dart';  // ✅ Puede importar models de NEGOCIO
import '../../negocio/InmuebleNegocio.dart';         // ✅ Puede usar lógica de NEGOCIO
import '../providers/inmueble_provider.dart';        // ✅ Usa sus propios providers
```

**Imports NO permitidos:**
```dart
import '../../datos/ApiService.dart';  // ❌ NO puede acceder directamente a DATOS
```

---

## 🔄 Flujo de Comunicación

### Ejemplo: Usuario quiere ver lista de inmuebles

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USUARIO                                                  │
│    Abre la pantalla de inmuebles                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. PRESENTACIÓN (InmuebleScreen)                           │
│    - Llama a provider.loadInmuebles()                      │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. PRESENTACIÓN (InmuebleProvider)                         │
│    - Llama a inmuebleNegocio.getInmuebles()                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. NEGOCIO (InmuebleNegocio)                               │
│    - Valida datos (si es necesario)                        │
│    - Llama a apiService.post()                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. DATOS (ApiService)                                      │
│    - Hace petición HTTP a la API                           │
│    - Recibe respuesta JSON                                 │
│    - Deserializa a ResponseModel                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. NEGOCIO (InmuebleNegocio)                               │
│    - Recibe ResponseModel de ApiService                    │
│    - Retorna a Provider                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. PRESENTACIÓN (InmuebleProvider)                         │
│    - Convierte data a List<InmuebleModel>                  │
│    - Actualiza estado (_inmuebles)                         │
│    - Llama a notifyListeners()                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. PRESENTACIÓN (InmuebleScreen)                           │
│    - Se re-construye con nuevos datos                      │
│    - Muestra lista de inmuebles al usuario                 │
└─────────────────────────────────────────────────────────────┘
```

### Diagrama de Secuencia

```
Usuario  →  Screen  →  Provider  →  Negocio  →  ApiService  →  API
   │          │          │            │            │            │
   │ abrir    │          │            │            │            │
   │─────────>│          │            │            │            │
   │          │ load()   │            │            │            │
   │          │─────────>│            │            │            │
   │          │          │ getInm()   │            │            │
   │          │          │───────────>│            │            │
   │          │          │            │ post()     │            │
   │          │          │            │───────────>│            │
   │          │          │            │            │ GET /api   │
   │          │          │            │            │───────────>│
   │          │          │            │            │<───────────│
   │          │          │            │<───────────│            │
   │          │          │<───────────│            │            │
   │          │ notify() │            │            │            │
   │          │<─────────│            │            │            │
   │ muestra  │          │            │            │            │
   │<─────────│          │            │            │            │
```

---

## ✅ Reglas de la Arquitectura

### 1. Dependencias Unidireccionales

```
PRESENTACIÓN  →  (depende de)  →  NEGOCIO
NEGOCIO       →  (depende de)  →  DATOS
DATOS         →  (NO depende de nadie)
```

**✅ CORRECTO:**
```dart
// presentacion/providers/inmueble_provider.dart
import '../../negocio/InmuebleNegocio.dart';  // ✅ Presentación usa Negocio
import '../../negocio/models/inmueble_model.dart';  // ✅ Presentación usa Models de Negocio
```

**❌ INCORRECTO:**
```dart
// presentacion/providers/inmueble_provider.dart
import '../../datos/ApiService.dart';  // ❌ Presentación NO debe usar Datos directamente
```

### 2. Los Models están en NEGOCIO

Los modelos representan **conceptos de negocio** (Inmueble, Contrato, Pago), por lo tanto pertenecen a la capa de NEGOCIO.

**¿Por qué?**
- "Inmueble" es un concepto de negocio, no un detalle técnico
- Los models definen QUÉ es un Inmueble para el sistema
- Todas las capas necesitan usar estos models

**Imports de models:**
```dart
// Desde NEGOCIO
import 'models/inmueble_model.dart';  // ✅ Mismo nivel

// Desde PRESENTACIÓN
import '../../negocio/models/inmueble_model.dart';  // ✅ Importa de negocio

// Desde DATOS
import '../negocio/models/response_model.dart';  // ✅ Importa de negocio
```

### 3. Cada Capa Tiene Responsabilidad Única

| Capa | SÍ hace | NO hace |
|------|---------|---------|
| **DATOS** | - Llamadas HTTP<br>- Consultas DB<br>- Transacciones blockchain | - Validaciones de negocio<br>- Transformaciones complejas<br>- Lógica de UI |
| **NEGOCIO** | - Validaciones<br>- Reglas de negocio<br>- Orquestación de datos | - Llamadas HTTP directas<br>- Gestión de estado UI<br>- Widgets |
| **PRESENTACIÓN** | - Mostrar UI<br>- Gestionar estado<br>- Capturar eventos | - Llamadas directas a API<br>- Lógica de negocio compleja |

### 4. NO Saltar Capas

```dart
// ❌ MAL - Presentación salta Negocio y va directo a Datos
class InmuebleProvider {
  final ApiService apiService = ApiService();  // ❌ NO HACER ESTO

  Future<void> loadInmuebles() async {
    final response = await apiService.get('/inmuebles');  // ❌ Saltó Negocio
  }
}

// ✅ BIEN - Presentación usa Negocio
class InmuebleProvider {
  final InmuebleNegocio negocio = InmuebleNegocio();  // ✅ Correcto

  Future<void> loadInmuebles() async {
    final response = await negocio.getInmuebles("");  // ✅ Pasa por Negocio
  }
}
```

---

## 📝 Mapeo de Archivos

### De estructura antigua a nueva:

| Ubicación Anterior | Ubicación Nueva | Capa |
|-------------------|-----------------|------|
| `models/inmueble_model.dart` | `negocio/models/inmueble_model.dart` | NEGOCIO |
| `models/contrato_model.dart` | `negocio/models/contrato_model.dart` | NEGOCIO |
| `models/database/` | `datos/database/` | DATOS |
| `negocio/InmuebleNegocio.dart` | `negocio/InmuebleNegocio.dart` | NEGOCIO |
| `services/ApiService.dart` | `datos/ApiService.dart` | DATOS |
| `services/socket_service.dart` | `datos/socket_service.dart` | DATOS |
| `blockchain/blockchain_service.dart` | `datos/blockchain_service.dart` | DATOS |
| `controllers_providers/inmueble_provider.dart` | `presentacion/providers/inmueble_provider.dart` | PRESENTACIÓN |
| `vista/auth/login_screen.dart` | `presentacion/screens/auth/login_screen.dart` | PRESENTACIÓN |
| `widgets/notification_badge.dart` | `presentacion/widgets/notification_badge.dart` | PRESENTACIÓN |

---

## 💡 Ejemplos de Uso

### Ejemplo 1: Crear un Nuevo Inmueble

```dart
// 1. PRESENTACIÓN - Usuario interactúa con formulario
// presentacion/screens/inmueble/inmueble_form_screen.dart
class InmuebleFormScreen extends StatelessWidget {
  void _submit(BuildContext context) {
    final provider = context.read<InmuebleProvider>();

    final inmueble = InmuebleModel(
      titulo: _tituloController.text,
      precio: double.parse(_precioController.text),
      // ... otros campos
    );

    provider.createInmueble(inmueble);  // → Va al Provider
  }
}

// 2. PRESENTACIÓN - Provider gestiona estado
// presentacion/providers/inmueble_provider.dart
class InmuebleProvider extends ChangeNotifier {
  final InmuebleNegocio _negocio = InmuebleNegocio();

  Future<bool> createInmueble(InmuebleModel inmueble) async {
    isLoading = true;
    _responseModel = await _negocio.createInmueble(inmueble);  // → Va a Negocio

    if (_responseModel.isSuccess) {
      message = 'Inmueble creado exitosamente';
      isLoading = false;
      return true;
    }
    return false;
  }
}

// 3. NEGOCIO - Valida y orquesta
// negocio/InmuebleNegocio.dart
class InmuebleNegocio {
  final ApiService apiService;

  Future<ResponseModel> createInmueble(InmuebleModel inmueble) async {
    // Validaciones de negocio
    if (inmueble.precio <= 0) {
      return ResponseModel(
        isSuccess: false,
        messageError: 'El precio debe ser mayor a 0',
      );
    }

    // Llama al servicio de datos
    ResponseModel response = await apiService.post(
      'inmuebles/store',
      inmueble.toMap(),  // → Va a Datos
    );

    return response;
  }
}

// 4. DATOS - Ejecuta petición HTTP
// datos/ApiService.dart
class ApiService {
  Future<ResponseModel> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: defaultHeaders,
      body: jsonEncode(body),  // → API REST
    );
    return ResponseHandler.processResponse(response);
  }
}
```

### Ejemplo 2: Listar Inmuebles Disponibles

```dart
// 1. Screen pide datos al Provider
final provider = context.watch<InmuebleProvider>();

// 2. Provider llama a Negocio
await _negocio.getInmuebles("");

// 3. Negocio llama a Datos
await apiService.post('inmuebles/query', {'query': query});

// 4. Datos hace petición HTTP
final response = await http.post(url);

// 5. Respuesta regresa por el mismo camino
Datos → Negocio → Provider → Screen
```

---

## 🎯 Beneficios de esta Arquitectura

1. **✅ Separación de Responsabilidades**
   - Cada capa tiene un propósito claro
   - Fácil saber dónde agregar nuevo código

2. **✅ Mantenibilidad**
   - Cambios en UI no afectan lógica de negocio
   - Cambios en API no afectan UI

3. **✅ Testabilidad**
   - Cada capa se puede testear independientemente
   - Fácil mockear dependencias

4. **✅ Escalabilidad**
   - Agregar nuevas features es agregar archivos en cada capa
   - Claro cómo organizar código nuevo

5. **✅ Trabajo en Equipo**
   - Un desarrollador puede trabajar en Negocio
   - Otro en UI
   - Otro en integración con APIs

---

## 📚 Conclusión

La arquitectura de 3 capas implementada en este proyecto asegura:
- ✅ Código limpio y organizado
- ✅ Fácil mantenimiento
- ✅ Escalabilidad a futuro
- ✅ Cumplimiento de principios SOLID
- ✅ Separación clara de responsabilidades

**Recuerda siempre:**
> "Presentación solo conoce Negocio, Negocio solo conoce Datos, Datos no conoce a nadie"

---

**Última actualización:** 2025-01-16
**Versión:** 1.0
**Autor:** Equipo de Desarrollo Rentals
