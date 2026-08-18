# Catálogo Virtual — catalogo_app

Aplicación Flutter (Dart) multi-tenant de ecommerce que permite a las empresas crear y publicar catálogos de productos en línea de forma rápida, sin necesidad de tienda física ni pasarela de pago. Cada catálogo es público (compartible por link o WhatsApp), con contacto directo al vendedor mediante WhatsApp, lo que facilita las ventas a través de mensajería.

El sistema cuenta con dos paneles de administración (ADMIN y OWNER) y una capa pública de catálogo optimizada para móviles (con soporte web).

## Módulos y funcionalidades

### 1. Público (sin autenticación)

| Ruta | Funcionalidad |
|---|---|
| `/login` | Inicio de sesión con email y contraseña |
| `/catalogo/:companyId` | Home del catálogo público de una empresa |
| `/catalogo/:companyId/productos/:productId` | Detalle de producto |

**Catálogo público (vitrina):**
- Banner con el nombre de la empresa y botón de WhatsApp.
- Chips de filtro por categoría.
- Buscador de texto libre.
- Filtros: Todos / Destacados / Con descuento.
- Grilla de productos con paginación (12 por página).
- Tarjetas con precio, descuento y estado de disponibilidad.

**Detalle de producto:**
- Galería de imágenes: lupa en desktop, swipe táctil en móvil, thumbnails y lightbox a pantalla completa.
- Precio y precio final con descuento.
- Botón "Consultar por WhatsApp" (barra fija en móvil).

### 2. Panel ADMIN

| Ruta | Funcionalidad |
|---|---|
| `/admin/companies` | CRUD de empresas (nombre, WhatsApp, dueño OWNER, licencia, estado activo/inactivo) |
| `/admin/users` | CRUD de usuarios (email, rol, licencia, ubicación país/provincia/cantón/dirección) |
| `/admin/licenses` | CRUD de licencias/planes (límite de empresas y productos, expiración, activo/inactivo) |

### 3. Panel OWNER

| Ruta | Funcionalidad |
|---|---|
| `/owner` | Dashboard con estadísticas (empresas, productos, categorías, destacados), barra de disponibilidad e info de licencia |
| `/owner/companies` | CRUD de empresas del dueño; acciones "Ver catálogo", "Copiar link" y "Compartir por WhatsApp" |
| `/owner/companies/:companyId/products` | CRUD de productos por empresa: imágenes múltiples, imagen principal, categorías (inline), disponibilidad y destacado |
| `/owner/companies/:companyId/categories` | CRUD de categorías por empresa |

## Roles y autenticación

- **Roles:** `ADMIN` y `OWNER`.
- **Login** vía `POST /auth/login` → devuelve `{ accessToken, user }`.
- Token **JWT** guardado en `flutter_secure_storage`; el interceptor de Dio agrega `Authorization: Bearer <token>` automáticamente.
- Ante un **401** se limpia la sesión y se redirige a `/login`.
- `AuthProvider` (ChangeNotifier) mantiene el estado de sesión y controla el acceso por rol vía `GoRouter` (no autenticado → `/login`; rol no permitido → su home).
- **No hay registro público ni recuperación de contraseña**; los usuarios los crea el administrador.

## Arquitectura y estructura del código

```
lib/
├── main.dart                 # Bootstrap: dotenv, ApiClient, AuthProvider, MaterialApp.router
└── core/
    ├── api/
    │   ├── api_client.dart   # Cliente Dio + interceptor Bearer + manejo 401 → logout
    │   └── api_provider.dart # Módulos por dominio (auth, catálogo, owner, admin)
    ├── auth/
    │   ├── auth_service.dart # POST /auth/login, GET /auth/me, logout
    │   ├── auth_provider.dart# Estado de sesión (ChangeNotifier) + control de roles
    │   └── auth_storage.dart # Persistencia del JWT (flutter_secure_storage)
    ├── router/
    │   ├── app_router.dart   # GoRouter con redirects por autenticación y rol
    │   └── app_shells.dart   # Layouts por área (PublicCatalog, Admin, Owner)
    ├── models/               # Modelos Dart (User, Company, Product, License, Category…)
    ├── theme/
    │   └── app_theme.dart    # Paleta: verde profundo, ámbar, verde WhatsApp
    ├── utils/
    │   ├── crc_currency.dart # Formato de colones (₡, sin decimales)
    │   ├── whatsapp_utils.dart # Enlaces wa.me/506...
    │   └── error_utils.dart  # Mensajes de error y feedback de red
    └── widgets/              # Kit de UI reutilizable (botones, tarjetas, loader global)
```

### Estado global
- **AuthProvider** (`provider`): sesión de usuario + token.
- La gestión de peticiones y notificaciones (snackbars success/error) se centraliza en los servicios y widgets compartidos de `core/`.

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter / Dart | SDK ^3.13 | UI y lógica multiplataforma (Android/iOS/Web) |
| dio | ^5.4 | Cliente HTTP con interceptores |
| go_router | ^14.2 | Enrutamiento declarativo con guardas |
| provider | ^6.1 | Estado global (AuthProvider) |
| flutter_secure_storage | ^9.2 | Almacenamiento seguro del JWT |
| shared_preferences | ^2.2 | Preferencias locales |
| jwt_decoder | ^2.0 | Decodificación y lectura del token |
| flutter_dotenv | ^5.1 | Variables de entorno (`.env`) |
| image_picker | ^1.1 | Selección de imágenes (multipart) |
| url_launcher | ^6.3 | Apertura de WhatsApp / enlaces externos |

## API (backend en Render)

- **Auth:** `POST /auth/login`, `GET /auth/me`
- **Catálogo público:** `GET /catalog/:companyId`, `GET /catalog/:companyId/products`, `GET /catalog/:companyId/products/:productId`, `GET /catalog/:companyId/pdf`
- **Owner:** CRUD de categorías, productos (con subida de imágenes multipart), empresas
- **Admin:** CRUD de empresas, usuarios y licencias

## Reglas de negocio clave

- **Moneda:** Colones costarricenses (CRC `₡`, sin decimales).
- **WhatsApp:** números con prefijo `506`; el CTA principal del catálogo es "Consultar por WhatsApp" (`wa.me/506...`).
- **Multi-tenancy:** cada usuario tiene `tenantId`; las empresas pertenecen a un OWNER y están acotadas por licencia (`maxCompanies`, `maxProducts`).
- **Productos:** código único, precio, descuento (`finalPrice` calculado en backend), imágenes múltiples con principal, flags `isAvailable` e `isFeatured`.
- **Categorías:** por empresa.

## Diseño UX/UI

- Tema claro con verde profundo como color de marca, ámbar para acentos y verde WhatsApp para CTAs de contacto.
- Responsive: sidebar en desktop, navegación inferior fija en móvil (respeta `safe-area-inset`).
- Optimizado para consultas de venta rápida por WhatsApp.

## Configuración

- Instalar Flutter SDK y ejecutar `flutter pub get`.
- Crear un archivo `.env` con `API_URL` apuntando al backend (ya incluido en assets).
- Backend de producción alojado en Render.

## Scripts

| Comando | Descripción |
|---|---|
| `flutter pub get` | Instalar dependencias |
| `flutter run` | Ejecutar en emulador/dispositivo |
| `flutter run -d chrome` | Ejecutar versión web |
| `flutter build apk` | Build de Android |
| `flutter build web` | Build de web |
| `flutter analyze` | Análisis estático |
| `flutter test` | Ejecutar tests |

## Notas pendientes / deuda técnica

- `lib/main.dart` ya importa `core/api/api_client.dart`, `core/auth/auth_service.dart`, `core/auth/auth_provider.dart` y `core/router/app_router.dart`; estos archivos aún no existen y deben implementarse.
- El resto de la estructura de `lib/core/` y las páginas por módulo están pendientes de creación según este documento.