# Arquitectura — base para el reporte técnico

## Diagrama de clases

```mermaid
classDiagram
    direction LR

    class Ubicacion {
      +int id
      +String nombre
      +double latitud
      +double longitud
      +double radioMetros
      +String fotoPortada
      +DateTime creadaEn
    }
    class Entrada {
      +int id
      +int ubicacionId
      +String texto
      +String imagenPath
      +double latitud
      +double longitud
      +DateTime creadaEn
    }
    Ubicacion "1" --> "*" Entrada : contiene

    class UbicacionRepository {
      <<interface>>
      +obtenerTodas()
      +crear(Ubicacion)
      +actualizarPortada(id, ruta)
      +eliminar(id)
    }
    class EntradaRepository {
      <<interface>>
      +obtenerPorUbicacion(id)
      +crear(Entrada)
    }
    class LocationService { <<interface>> +obtenerPosicionActual() }
    class MediaService { <<interface>> +tomarFoto() +elegirDeGaleria() }
    class SpeechService { <<interface>> +escuchar(cb) +detener() }
    class MapLauncher { <<interface>> +abrirEnMapas(lat, lng) }

    class ResolverUbicacion { +call(Coordenadas) Ubicacion? }
    class GuardarEntrada { +call(...) Entrada }

    ResolverUbicacion --> UbicacionRepository
    GuardarEntrada --> UbicacionRepository
    GuardarEntrada --> EntradaRepository

    SqliteUbicacionRepository ..|> UbicacionRepository
    SqliteEntradaRepository ..|> EntradaRepository
    SqliteUbicacionRepository --> AppDatabase
    SqliteEntradaRepository --> AppDatabase
    GeolocatorLocationService ..|> LocationService
    ImagePickerMediaService ..|> MediaService
    SpeechToTextService ..|> SpeechService
    UrlMapLauncher ..|> MapLauncher

    class AppContainer
    AppContainer ..> SqliteUbicacionRepository : crea
    AppContainer ..> GuardarEntrada : crea
    AppRouter --> AppContainer
    AppRouter ..> UbicacionesListScreen
    AppRouter ..> UbicacionDetailScreen
    AppRouter ..> NuevaEntradaScreen
    NuevaEntradaScreen --> GuardarEntrada
    NuevaEntradaScreen --> ResolverUbicacion
    NuevaEntradaScreen --> LocationService
    NuevaEntradaScreen --> MediaService
    NuevaEntradaScreen --> SpeechService
    UbicacionDetailScreen --> EntradaRepository
    UbicacionDetailScreen --> MapLauncher
    UbicacionesListScreen --> UbicacionRepository
```

## Flujo de datos — guardar una entrada

```mermaid
sequenceDiagram
    actor T as Técnico
    participant UI as NuevaEntradaScreen
    participant GPS as LocationService
    participant R as ResolverUbicacion
    participant G as GuardarEntrada
    participant DB as SQLite

    T->>UI: Abre "Nueva entrada"
    UI->>GPS: obtenerPosicionActual()
    GPS-->>UI: Coordenadas
    UI->>R: call(coordenadas)
    R->>DB: SELECT ubicaciones
    R-->>UI: Ubicación dentro del radio / null
    T->>UI: Foto (cámara/galería) + dictado
    T->>UI: Guardar
    UI->>G: call(coords, texto, imagen, ubicación?)
    alt No hay ubicación cercana
        G->>DB: INSERT ubicaciones
    end
    G->>DB: INSERT entradas
    G->>DB: UPDATE portada (si es la primera foto)
    G-->>UI: Entrada
    UI-->>T: Regresa a la lista (recarga con FutureBuilder)
```

## Principios SOLID aplicados

- **S** — cada clase tiene una responsabilidad: repositorios persisten, servicios hablan con el hardware, casos de uso aplican reglas, pantallas muestran.
- **O** — se puede cambiar SQLite por otra persistencia creando otra implementación del repositorio, sin tocar dominio ni UI.
- **L** — cualquier implementación de `LocationService` (real o falsa para pruebas) funciona igual en la pantalla.
- **I** — un servicio por gadget, en lugar de una interfaz "Dispositivo" gigante.
- **D** — dominio y UI dependen de interfaces; solo `AppContainer` conoce las clases concretas, y las pantallas reciben dependencias por constructor.
