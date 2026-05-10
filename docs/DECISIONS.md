# Architecture Decision Records — GrowTogetherADMIN

Decisiones de arquitectura específicas del panel de administración web.

**Proyecto**: GrowTogether — DAM 2026
**Autor**: Jordi Patuel Pons

> Este archivo cubre solo decisiones del panel admin. Las del paquete
> de datos compartido están en `GrowTogetherDATA/docs/DECISIONS.md`,
> las del backend en `GrowTogetherAPI/docs/DECISIONS.md` y las de la
> app móvil en `GrowTogetherAPP/docs/DECISIONS.md`.

---

## Índice

| # | Decisión | Estado |
|---|----------|--------|
| [ADR-001](#adr-001-flutter-web-en-vez-de-react-o-vue) | Flutter Web en vez de React o Vue | Aceptado |
| [ADR-002](#adr-002-mismo-paquete-growtogether_data-que-la-app-mvil) | Mismo paquete `growtogether_data` que la app móvil | Aceptado |
| [ADR-003](#adr-003-data_table_2-para-tablas-y-fl_chart-para-grficas) | `data_table_2` para tablas y `fl_chart` para gráficas | Aceptado |
| [ADR-004](#adr-004-solo-build-web-sin-empaquetado-mvil-ni-desktop) | Solo build web, sin empaquetado móvil ni desktop | Aceptado |
| [ADR-005](#adr-005-token-jwt-en-flutter_secure_storage-aunque-en-web-cae-a-localstorage) | Token JWT en `flutter_secure_storage` aunque en web cae a LocalStorage | Aceptado (con caveat) |

---

## ADR-001: Flutter Web en vez de React o Vue

**Fecha**: 2026-04-25

### Contexto

El panel admin necesita listados con paginación, formularios, gráficas y
un calendario de consejos. Era razonable plantear una SPA en React o
Vue separada del ecosistema Flutter.

### Decisión

**Flutter Web** comparte el lenguaje (Dart), las herramientas y, sobre
todo, el paquete `growtogether_data` con la app móvil.

### Alternativas descartadas

**React + TypeScript**
La opción más estándar para panels admin en producción. Ecosistema
maduro (TanStack Query, Material UI, Recharts). El problema es que
obligaría a duplicar todos los modelos del dominio en TS y a replicar
la lógica de DioClient, AuthInterceptor y los repositorios. La única
forma razonable de evitar la duplicación sería generar los modelos
desde el OpenAPI de la API, lo que añade complejidad de build.

**Vue 3**
Mismo problema que React: ecosistema separado del paquete Dart
compartido.

**Servicio web servido por la propia API (Spring + Thymeleaf)**
Mantiene todo en un único deploy pero acopla la UI al backend, dificulta
el desarrollo independiente y tira por la borda el trabajo ya hecho
con `growtogether_data`.

### Razones de la decisión

1. **Reúso del paquete `growtogether_data`**: los modelos, los DTOs,
   `DioClient`, `AuthInterceptor` y `AdminRepository` se importan tal
   cual desde el panel.
2. **Mismo lenguaje y herramientas**: si se gana fluidez en Dart con
   la app móvil, se aprovecha también aquí.
3. **`hot reload`** en Chrome durante el desarrollo del panel.
4. **Build estático trivial**: `flutter build web --release` produce un
   bundle servible por nginx, S3 o GitHub Pages sin runtime adicional.

### Consecuencias

- El bundle web pesa ~3 MB (compresible). Para uso interno con admins
  que entran ocasionalmente es aceptable.
- Performance ligeramente inferior a React/Vue para tablas grandes
  (>1000 filas). Mitigado con paginación en `data_table_2` y filtros
  servidor.
- Pintar SVG de gráficas funciona bien con `fl_chart`, pero tipografías
  de `intl` requieren `await initializeDateFormatting('es_ES')` en
  `main.dart` antes del primer render.

---

## ADR-002: Mismo paquete `growtogether_data` que la app móvil

**Fecha**: 2026-04-25

### Contexto

El panel necesita comunicarse con la API REST de GrowTogether. Hay dos
opciones: replicar la capa de datos en el repo del admin o reutilizar
la del proyecto móvil.

### Decisión

**Reutilizar el paquete `growtogether_data`** del repo
`devPatuel/GrowTogetherDATA`. El admin lo importa por `git: ref: vX.Y.Z`
y los tipos sensibles solo accesibles para el admin (`UsuarioAdmin`,
`AuditLog`, `MetricasAdmin`, `AdminRepository`) están exportados desde
el barrel del paquete pero no se usan desde la app móvil.

### Alternativas descartadas

**Capa de datos propia en el admin**
Duplica modelos, DioClient e interceptores. Cualquier cambio en la API
exige tocar los dos clientes y se gestionan dos versiones del contrato.

**Modelos generados desde OpenAPI**
Funciona pero los nombres y dartdocs los escribe la herramienta. Para
un dominio estable se prefirió escribir a mano.

### Razones de la decisión

1. **Una única fuente de verdad**: cuando la API cambia, se ajusta DATA
   una vez y los dos clientes se enteran al subir el ref.
2. **Modelos separados por audiencia**: `UsuarioAdmin` (con campos
   sensibles) solo se usa aquí; `Usuario` lo comparten ambos clientes.
   Decisión documentada en `GrowTogetherDATA/docs/DECISIONS.md` ADR-004.
3. **Versionado explícito**: bumpear DATA no afecta al admin hasta que
   el admin actualice su `ref`. Garantiza estabilidad en producción.

### Consecuencias

- En desarrollo local se sobreescribe el ref con `pubspec_overrides.yaml`
  apuntando a `path: ../../GrowTogetherDATA` para iterar sin publicar
  tags. El override está en `.gitignore`.
- El workflow de CI borra `pubspec_overrides.yaml` antes del build para
  garantizar que producción usa el `ref` declarado.

---

## ADR-003: `data_table_2` para tablas y `fl_chart` para gráficas

**Fecha**: 2026-04-25

### Contexto

El panel necesita tablas con scroll vertical, columnas con sort,
paginación y filtros (audit log, lista de usuarios) y gráficas
(métricas: nuevos usuarios por mes).

### Decisión

- **`data_table_2`** para todas las tablas listables.
- **`fl_chart`** para las gráficas del dashboard de métricas.

### Alternativas descartadas

**`DataTable` nativo de Material**
Sin scroll vertical interno (rompe en listas largas), sin paginación
declarativa. Hubiera obligado a envolverlo a mano y reinventar la
rueda.

**Tablas custom con `ListView` + `Row`**
Da control total pero exige replicar el scroll horizontal sincronizado
con cabecera, ordenación, etc. Demasiado curro para algo que ya hace
una librería.

**`syncfusion_flutter_charts` para gráficas**
Más completo que `fl_chart` pero con licencia comercial para uso
profesional. `fl_chart` es OSS, suficiente para una gráfica de barras
y un par de líneas.

### Razones de la decisión

1. **`data_table_2`** está pensado precisamente para los huecos del
   `DataTable` de Material en uso real (scroll vertical, fila fija,
   paginación, ancho responsive).
2. **`fl_chart`** cubre todos los tipos que el panel necesita (barras,
   líneas, pie) sin licencia comercial.
3. Ambas son librerías estables con mantenimiento activo.

---

## ADR-004: Solo build web, sin empaquetado móvil ni desktop

**Fecha**: 2026-04-25

### Contexto

El proyecto Flutter por defecto soporta android, ios, web, linux, macos,
windows. ¿Se generan todos los empaquetados para el panel admin o solo
web?

### Decisión

**Solo se mantiene la plataforma `web`.** Las carpetas `android/`,
`ios/`, `windows/`, `linux/`, `macos/` no se generan ni se empaquetan.
El `pubspec.yaml` no añade plugins específicos de plataformas nativas.

### Alternativas descartadas

**Soporte multiplataforma completo**
No tiene sentido: el admin es para uso interno desde un navegador. Una
versión "panel admin para Android" es una idea sin caso de uso real
y duplica las decisiones de seguridad (iOS Keychain vs Android
Keystore).

**Solo desktop (Windows/Linux/macOS)**
Permitiría una "app instalable" para administradores, pero supone
distribuir binarios y firmar ejecutables, complicación que no aporta
valor frente al navegador.

### Razones de la decisión

1. **Caso de uso interno**: el admin lo usa el equipo, no usuarios
   finales. Un navegador moderno es entorno suficiente.
2. **Sin distribución**: no hay store ni paquete a firmar. Se sirve
   desde nginx en EC2 (`growtogether-admin.jordipatuel.com`).
3. **Build más rápido**: solo se compila la plataforma web, sin
   binarios de Android Gradle ni Xcode.

### Consecuencias

- El `README.md` lo deja explícito: "Solo se ejecuta en navegador. No
  tiene build para móvil ni escritorio".
- El workflow de deploy en `.github/workflows/deploy.yml` solo invoca
  `flutter build web`.

---

## ADR-005: Token JWT en `flutter_secure_storage` aunque en web cae a LocalStorage

**Fecha**: 2026-04-25
**Estado**: Aceptado con caveat documentado

### Contexto

`flutter_secure_storage` (heredado de DATA) usa Keychain en iOS y
EncryptedSharedPreferences en Android. En web, sin embargo, **cae a
`window.localStorage` con cifrado AES-GCM software**, no a almacenamiento
seguro real del navegador. Cualquier código JavaScript inyectado en la
página puede leerlo.

### Decisión

**Mantener `flutter_secure_storage` en web a pesar del caveat**, porque:

1. El panel solo lo usa personal interno.
2. La autenticación real no depende del cliente: el backend valida rol
   `ADMIN` con `@PreAuthorize` en cada endpoint. Saltarse la pantalla
   de login no da acceso a recursos.
3. Ahorra duplicar el código de DATA solo para sustituir el storage.

### Alternativas descartadas

**Cookies `httpOnly` con sesión gestionada en servidor**
La opción correcta para producción pública: el JS no puede leer la
cookie ni con XSS. Implica:
- Cambiar el backend para soportar autenticación basada en cookies
  además de JWT.
- Añadir CSRF protection.
- Coordinar el flujo entre la app móvil (que necesita Bearer token) y
  el panel (que querría la cookie).

Demasiado curro para un proyecto académico de uso interno.

**No persistir el token (login en cada sesión)**
Más seguro pero molesto: cada vez que cierras la pestaña te exige
volver a logarse.

### Razones de la decisión

1. **El backend es la línea de defensa real**: el `@PreAuthorize` de
   Spring Security comprueba el rol en cada request, así que un token
   robado de un usuario sin rol ADMIN no sirve para nada.
2. **Audiencia interna**: solo entran admins internos en máquinas
   conocidas, sin extensiones de navegador sospechosas.
3. **Coste/beneficio**: pasar a cookies httpOnly cambia toda la auth
   del proyecto.

### Consecuencias

- **Documentado explícitamente** en el `README.md` (sección "Notas de
  seguridad"). Cualquier reviewer lo ve antes de mover el panel a
  acceso público.
- Si en algún momento el panel se expone en internet abierto (no es la
  intención), hay que **migrar a cookies `httpOnly`** antes de hacerlo.
- Los logs de auditoría (`audit_log`) capturan IP y admin de cada
  acción sensible: si un token se compromete, queda trazado quién y
  desde dónde se actuó.
