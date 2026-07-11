# GrowTogether ADMIN

> Panel de administración web del ecosistema **GrowTogether**: gestión de usuarios, consejos diarios, métricas y auditoría.

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider%206.x-4CAF50)
![fl_chart](https://img.shields.io/badge/Gr%C3%A1ficos-fl__chart-FF6F00)
![Dio](https://img.shields.io/badge/HTTP-Dio%205.x-1E88E5)

---

## Sobre el proyecto

**GrowTogether** es una aplicación de seguimiento de hábitos con componente social, inspirada en *Atomic Habits* de James Clear: construye hábitos consistentes, visualiza tu progreso y compite con amigos en desafíos.

Es el **Trabajo Final de Grado de DAM** (Desarrollo de Aplicaciones Multiplataforma, 2025/2026) de **Jordi Patuel Pons**.

### Papel de este repositorio

Este repo contiene el **panel de administración web** (Flutter Web), pensado exclusivamente para uso interno del equipo: gestión de usuarios, consejos diarios, métricas de la plataforma, auditoría y alta de nuevos administradores.

> ⚠️ Solo se ejecuta en navegador. No tiene build para móvil ni escritorio.

## Ecosistema GrowTogether

| Repositorio | Descripción |
|---|---|
| [GrowTogetherAPI](https://github.com/devPatuel/GrowTogetherAPI) | Backend REST (Java 17 + Spring Boot) |
| [GrowTogetherAPP](https://github.com/devPatuel/GrowTogetherAPP) | App móvil de hábitos (Flutter) |
| **[GrowTogetherADMIN](https://github.com/devPatuel/GrowTogetherADMIN)** ← estás aquí | Panel de administración web (Flutter Web) |
| [GrowTogetherDATA](https://github.com/devPatuel/GrowTogetherDATA) | Paquete Dart compartido: modelos, cliente HTTP y repositorios |

---

## Stack técnico

- **Flutter Web** (Dart SDK ^3.10.4)
- **Provider** para gestión de estado
- **Dio 5.x** para el acceso a la API REST (cliente compartido en `growtogether_data`)
- **fl_chart** para gráficos del dashboard
- **data_table_2** para tablas con scroll, sort y paginación
- **intl** para formateo de fechas en español

La capa de datos ([`growtogether_data`](https://github.com/devPatuel/GrowTogetherDATA)) es un paquete Dart compartido con la app
móvil de GrowTogether. En CI y producción se importa por **git + tag** (`ref: vX.Y.Z`)
desde el repo `devPatuel/GrowTogetherDATA`. En desarrollo local se sobreescribe con
`pubspec_overrides.yaml` apuntando a `path: ../GrowTogetherDATA` para iterar sin
publicar tags; ese override está en `.gitignore` y el workflow de CI lo borra
antes del build.

---

## Funcionalidades

| Pestaña | Descripción |
|---|---|
| **Usuarios** | Lista de todos los usuarios. Activos primero, bloqueados al final. Bloqueo con motivo obligatorio (queda en audit log). Desbloqueo limpia los metadatos. Un admin no puede bloquearse a sí mismo. |
| **Consejos** | CRUD de consejos diarios con vista lista + calendario mensual. La fecha de publicación es opcional, pero si se asigna debe ser única (1 consejo por día). El día con consejo aparece resaltado en el calendario. |
| **Métricas** | Cards con totales (usuarios activos, hábitos creados, desafíos activos, completados hoy), card destacado del usuario más veterano y gráfico de barras de nuevos usuarios por mes (6 meses). |
| **Audit log** | Tabla paginada de las últimas 100 acciones administrativas. Filtros por admin, entidad, acción y rango de fechas. |
| **Crear admin** | Formulario para dar de alta otro administrador (solo otro admin puede hacerlo). Política de contraseña: ≥8 caracteres con mayúscula, minúscula, dígito y carácter especial. |

---

## Cómo ejecutarlo en local

### Requisitos previos

- **Flutter** 3.38+ (con soporte web habilitado: `flutter config --enable-web`).
- La **[API de GrowTogether](https://github.com/devPatuel/GrowTogetherAPI)** corriendo y accesible desde el navegador en `http://localhost:8081` (ver su README).
- El paquete **`growtogether_data`** se descarga automáticamente del repo git declarado en `pubspec.yaml`. Para iterar sobre él en local, clónalo en `../GrowTogetherDATA/` y crea un `pubspec_overrides.yaml` apuntando a ese `path:`.

### Arrancar

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8081/api/v1
```

Si el puerto 8080 (default de Flutter web) está ocupado o quieres fijar uno
estable, añade `--web-port=7780`. Si no quieres que Flutter abra Chrome y
prefieres servir el bundle para abrirlo manualmente:

```bash
flutter run -d web-server --web-port=7780 \
  --dart-define=API_URL=http://localhost:8081/api/v1
```

Luego abre `http://localhost:7780` en tu navegador.

### Crear el primer admin

El sistema solo permite crear administradores desde otro admin. Para arrancar
de cero, inserta uno directamente en la base de datos PostgreSQL:

```sql
INSERT INTO usuarios (nombre, email, password, rol, fecha_registro, puntos_totales, token_version, activo, tema, idioma)
VALUES ('Admin', 'admin@growtogether.com',
        '$2a$10$REEMPLAZA_POR_BCRYPT', 'ADMIN', NOW(), 0, 0, true, 'CLARO', 'es');
```

El hash BCrypt puedes generarlo con cualquier utilidad online o con un endpoint
de prueba. Una vez exista al menos un admin, los siguientes se crean desde la
pestaña **Crear admin** del panel. Si has sembrado el `data.sql` de la API, ya
existe el admin de prueba `admin@growtogether.com` / `Prueba123`.

---

## Build para producción

```bash
flutter build web \
  --release \
  --dart-define=API_URL=https://tu-api.example.com/api/v1
```

El resultado va a `build/web/`. Sirve esa carpeta con cualquier servidor
estático (nginx, Apache, S3 + CloudFront, GitHub Pages, etc.).

---

## Estructura del proyecto

```
lib/
├── main.dart                   Bootstrap, MultiProvider, comprobación de sesión
├── core/
│   ├── config/api_config.dart  Lectura de API_URL vía --dart-define
│   ├── theme/app_theme.dart    Material 3, paleta verde GrowTogether
│   └── utils/                  SnackHelper, Formatters
├── providers/
│   ├── auth_admin_provider.dart        Login con verificación de rol ADMIN
│   ├── usuarios_admin_provider.dart    Listado, bloqueo, desbloqueo, alta admin
│   ├── consejos_provider.dart          CRUD consejos + set de fechas ocupadas
│   ├── metricas_provider.dart          Carga snapshot de métricas
│   └── audit_provider.dart             Lista + filtros de audit log
└── screens/
    ├── login_admin_screen.dart
    ├── main_layout.dart                Sidebar + body
    ├── usuarios/
    ├── consejos/
    ├── metricas/
    ├── audit/
    └── admins/
```

---

## Generar documentación (`dart doc`)

Todas las clases públicas tienen comentarios `///` con el formato Dart estándar.
Para generar la documentación HTML:

```bash
dart doc .
```

La salida va a `doc/api/`. Abre `doc/api/index.html` en el navegador para
explorarla. La carpeta `doc/api/` está incluida en `.gitignore` por defecto:
si quieres publicarla (por ejemplo a GitHub Pages), bórrala del `.gitignore` o
publícala desde un workflow.

---

## Scripts útiles

| Acción | Comando |
|---|---|
| Análisis estático | `flutter analyze` |
| Tests | `flutter test` |
| Limpiar build | `flutter clean` |
| Generar docs | `dart doc .` |
| Servir docs en local | `dart pub global run dhttpd --path doc/api` |

---

## Decisiones de arquitectura

Las decisiones técnicas (Flutter Web vs React/Vue, reuso del paquete
`growtogether_data`, `data_table_2` + `fl_chart`, almacenamiento del
token, etc.) están documentadas en
[`docs/DECISIONS.md`](docs/DECISIONS.md). Las del paquete de datos
compartido viven en
[`GrowTogetherDATA/docs/DECISIONS.md`](https://github.com/devPatuel/GrowTogetherDATA/blob/main/docs/DECISIONS.md)
y las del backend en
[`GrowTogetherAPI/docs/DECISIONS.md`](https://github.com/devPatuel/GrowTogetherAPI/blob/main/docs/DECISIONS.md).

---

## Notas de seguridad

- El token JWT se guarda en `flutter_secure_storage`, que en web cae en
  `LocalStorage` cifrado. **No es secure storage real**: cualquier código que
  consigas inyectar en la página puede leerlo. Como el panel solo lo usa
  personal interno, es aceptable. Si en algún momento se expone públicamente,
  hay que pasar a cookies `httpOnly`.
- El backend valida rol `ADMIN` con `@PreAuthorize` en cada endpoint, así que
  saltarse la pantalla de login no da acceso real a los recursos.
- Toda acción sensible (bloqueo, alta de admin, CRUD de consejos, reset de
  password) queda registrada en `audit_log` con IP, admin que la ejecutó y
  detalle textual.

---

## Licencia

Proyecto académico — Trabajo Final de Grado de DAM · GrowTogether · Jordi Patuel Pons.
