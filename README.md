# Bitácora de Campo

Memoria de trabajo **por ubicación** para técnicos de campo. Cada lugar
(domicilio, obra, propiedad) guarda su propio historial de fotos, notas
dictadas y coordenadas, todo en el dispositivo.

## Puesta en marcha

```bash
# 1. Dentro de esta carpeta, genera las carpetas de plataforma
#    (no sobrescribe lib/ ni pubspec.yaml)
flutter create --org com.example --project-name bitacora_campo .

# 2. Dependencias
flutter pub get

# 3. Agrega los permisos (abajo) y corre
flutter run
```

### Permisos Android — `android/app/src/main/AndroidManifest.xml`

Antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

Dentro del bloque `<queries>` que ya existe (o crea uno al final de `<manifest>`):

```xml
<intent>
    <action android:name="android.speech.RecognitionService"/>
</intent>
<intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
</intent>
```

### Permisos iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Para tomar fotos de tus visitas.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para adjuntar fotos de tu galería.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Para dictar tus notas.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Para convertir tu voz en texto.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para asociar cada entrada al lugar donde estás.</string>
```

## Estructura (por capas)

```
lib/
├── main.dart                     Arranque
├── app/
│   ├── app_container.dart        Raíz de composición (inyección de dependencias)
│   └── routes.dart               Rutas con nombre + onGenerateRoute
├── core/
│   ├── errors/app_exception.dart Excepción única con mensaje para UI
│   └── utils/                    Haversine, formato de fechas
├── domain/                       Sin Flutter ni plugins
│   ├── entities/                 Ubicacion, Entrada
│   ├── repositories/             Interfaces de persistencia
│   ├── services/                 Interfaces de gadgets (GPS, cámara, voz, mapas)
│   └── usecases/                 ResolverUbicacion, GuardarEntrada (reglas de negocio)
├── data/                         Implementaciones concretas
│   ├── db/app_database.dart      SQLite (sqflite)
│   ├── models/                   Mapeo entidad ↔ fila
│   ├── repositories/             Sqlite*Repository
│   └── services/                 geolocator, image_picker, speech_to_text, url_launcher
└── presentation/
    ├── screens/                  Lista, Detalle, Nueva entrada
    └── widgets/                  Drawer, FotoLocal, vistas de error/vacío
```

## Cobertura de requisitos del Parcial 2

| Requisito | Dónde |
|---|---|
| Scaffold, AppBar, Drawer | Las 3 pantallas, `widgets/app_drawer.dart` |
| Routes + Navigator | `app/routes.dart` (lista → detalle → formulario) |
| Hero | Portada de la ubicación: lista → detalle (`Ubicacion.heroTag`) |
| SQLite + metadatos | `data/db/app_database.dart` (ruta de imagen, lat/lng, fecha) |
| try-catch | Todos los repositorios y servicios → `AppException` |
| FutureBuilder | Lista de ubicaciones y lista de entradas |
| Cámara y galería | `ImagePickerMediaService` |
| Micrófono → texto | `SpeechToTextService` (es_MX, dictado) |
| GPS | `GeolocatorLocationService` al abrir el formulario |
| Mapa interactivo + Google Maps | `flutter_map` en detalle + botón en AppBar |

## Especificación y decisiones (Spec Kit)

El proyecto usa [Spec Kit](https://github.com/github/spec-kit) para registrar qué se
construye, por qué y en qué orden:

```
.specify/memory/constitution.md   Principios del proyecto (v1.0.0)
specs/
├── 001-bitacora-por-ubicacion/   Implementada
│   ├── spec.md                   Historias de usuario, requisitos, criterios
│   ├── plan.md                   Contexto técnico y Constitution Check
│   ├── research.md               Decisiones D-001…D-011 (decisión, por qué, alternativas)
│   ├── data-model.md             Entidades, esquema SQLite, reglas RN-01…RN-08
│   ├── quickstart.md             Recorrido de prueba en dispositivo
│   └── tasks.md                  Tareas marcadas [X]
└── 002-mejoras-pre-entrega/      Borrador: notas de voz, cambiar lugar, pruebas
    ├── spec.md
    └── research.md               Decisiones D-012 (notas de voz) y D-013 (privacidad)
CHANGELOG.md                      Resumen de cada spec entregada
```

Para un cambio nuevo, con Claude Code abierto en la carpeta:
`/speckit-specify <descripción>` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.
Para instalar la CLI: `uv tool install specify-cli`.

## Commits sugeridos

1. `chore: estructura por capas y dependencias`
2. `feat(domain): entidades, repositorios y casos de uso`
3. `feat(data): base SQLite y repositorios`
4. `feat(ui): navegación, drawer y pantallas base`
5. `feat(gps): captura de ubicación y regla de asignación por radio`
6. `feat(media): cámara y galería`
7. `feat(voz): dictado por micrófono`
8. `feat(mapa): mapa en detalle y apertura en Google Maps`
9. `feat(ui): transición Hero y estados vacíos/error`
