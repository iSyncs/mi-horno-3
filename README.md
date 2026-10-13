# Mi Horno 3

> **Copia de portafolio.** Este repositorio es una copia del proyecto original del equipo, publicada por Carlos Baranda para mostrar su trabajo. El repositorio original es privado. El historial de commits no se incluye.
>
> | Integrante | Rol en el proyecto |
> |---|---|
> | Carlos Baranda | Scrum Master · Desafíos, gamificación, generación de trivia con FoundationModels, sistema de XP |
> | Joel Téllez | Autenticación, perfil, asistente LLM on-device, traducción, localización |
> | Jorge Pereda | Mapa interior, navegación por QR, overlay de asistencia, dashboard de administración |
> | Sebastián Sánchez | Guía sensorial, resumen wrapped de visita, encuesta de satisfacción |
>
> Proyecto desarrollado de marzo a mayo de 2026 en el Tecnológico de Monterrey, con el Museo Horno 3 como empresa socia formadora.

**Transformando el patrimonio industrial mediante tecnología adaptativa**

Mi Horno 3 es una aplicación nativa para iOS que convierte la visita tradicional al Museo Horno 3 en Monterrey, México, en una experiencia autónoma, gamificada y accesible. Integra navegación interior por QR, IA on-device para desafíos visuales, un asistente con LLM local, traducción en tiempo real, una guía sensorial con Apple Intelligence, un overlay de asistencia de emergencias, una encuesta de satisfacción y un resumen visual de la visita (Wrapped).

---

## Tecnologías

### App iOS

| | |
|---|---|
| Lenguaje | Swift 5.9+ |
| Framework UI | SwiftUI con arquitectura MVVM |
| Target mínimo | iOS 17+ |
| IA visual on-device | Core ML (`ClassifierFinal.mlmodel`) para validación de desafíos de cámara |
| LLM on-device | MLX Swift — `Qwen2.5-0.5B-Instruct-4bit` vía `mlx-community` |
| Guía sensorial | Apple FoundationModels (`SystemLanguageModel`) — requiere Apple Intelligence |
| Generación de trivia | Apple FoundationModels con structs `@Generable` — adaptada al perfil del visitante |
| Traducción | Apple Translation API — completamente on-device, sin internet |
| Networking | URLSession con autenticación JWT |
| Almacenamiento local | UserDefaults para sesión y persistencia de encuesta |

### Dependencias Swift Package

| Paquete | Versión | Propósito |
|---|---|---|
| `mlx-swift` | 0.29.1 | Cómputo tensorial acelerado por Metal para el LLM on-device |
| `mlx-swift-examples` (MLXLLM) | 2.29.1 | Carga y generación en streaming del modelo LLM |
| `swift-transformers` | 1.0.0 | Tokenización (Hugging Face) |
| `swift-jinja` | 2.3.5 | Renderizado de plantillas de chat |
| `GzipSwift` | 6.0.1 | Descompresión de pesos del modelo |
| `swift-collections` | 1.4.1 | Estructuras de datos ordenadas |
| `swift-numerics` | 1.1.1 | Utilidades numéricas |

### Backend API

| | |
|---|---|
| Runtime | Node.js con Express.js 5 |
| Arquitectura | MVC — controladores, rutas, middleware, db |
| Autenticación | JWT (access token 15 min + refresh token 30 días) con hash bcrypt |
| Despliegue | Vercel (serverless) |
| Base de datos | PostgreSQL 14 en Google Cloud Platform (GCP Cloud SQL) |
| Driver | `pg` (node-postgres) |

### Infraestructura

| Servicio | Proveedor |
|---|---|
| Despliegue de la API | Vercel |
| Base de datos | GCP Cloud SQL (PostgreSQL 14) |
| IA visual on-device | Apple Core ML |
| LLM on-device | MLX Swift (mlx-community — se descarga en el primer inicio) |
| Guía sensorial y trivia IA | Apple FoundationModels / Apple Intelligence |
| Traducción | Apple Translation (on-device) |

---

## API desplegada

```
https://mi-horno-3-git-testing-joel-tellezs-projects.vercel.app
```

Prefijo base para todos los endpoints: `/api/v1`

---

## Endpoints de la API

### Autenticación — `/api/v1/auth`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| POST | `/api/v1/auth/register` | No | Crear una cuenta nueva |
| POST | `/api/v1/auth/login` | No | Iniciar sesión y recibir tokens |
| POST | `/api/v1/auth/refresh` | No | Renovar el access token |
| POST | `/api/v1/auth/logout` | Sí | Cerrar sesión |
| GET | `/api/v1/auth/me` | Sí | Obtener el usuario actual |
| PATCH | `/api/v1/auth/change-password` | Sí | Cambiar contraseña |
| DELETE | `/api/v1/auth/account` | Sí | Eliminar cuenta |

### Perfil — `/api/v1`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| GET | `/api/v1/avatars` | No | Listar avatares disponibles |
| GET | `/api/v1/interests` | No | Listar catálogo de intereses |
| GET | `/api/v1/profile` | Sí | Obtener perfil del usuario |
| PATCH | `/api/v1/profile` | Sí | Actualizar perfil e intereses |

### Mapa — `/map`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| GET | `/map/node/:qr` | No | Obtener nodo por código QR |
| GET | `/map/node-details/:id` | No | Obtener detalles de un nodo |
| GET | `/map/bathrooms` | No | Listar nodos de baños |
| GET | `/map/graph` | No | Obtener el grafo completo del mapa (nodos + aristas) |

### Gamificación — `/api/v1/gamification`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| GET | `/api/v1/gamification/progress/:userId` | No | Obtener XP total del usuario |
| GET | `/api/v1/gamification/history/:userId/:zoneId` | No | Obtener IDs de desafíos completados por zona |
| GET | `/api/v1/gamification/generatedQuiz/:userId/:zoneId` | No | Obtener trivia generada por IA para una zona |
| POST | `/api/v1/gamification/complete` | No | Registrar un desafío completado y otorgar XP |
| POST | `/api/v1/gamification/generatedQuiz` | No | Guardar una trivia generada por IA en el backend |
| POST | `/api/v1/gamification/resetZone` | No | Reiniciar el progreso de una zona |

### Asistencia — `/api/v1/assistance`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| POST | `/api/v1/assistance/requests` | No | Crear una solicitud de asistencia / SOS |

### Encuesta — `/api/v1/survey`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| GET | `/api/v1/survey/status` | Sí | Verificar si el usuario ya completó la encuesta |
| POST | `/api/v1/survey/submit` | Sí | Enviar respuestas de la encuesta (devuelve 409 si ya fue enviada) |

### Sensorial — `/api/v1`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| POST | `/api/v1/sensory/visit` | Sí | Registrar una visita a una sala sensorial |

### Wrapped — `/api/v1`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| POST | `/api/v1/wrapped/session/start` | Sí | Iniciar una sesión de visita |
| POST | `/api/v1/wrapped/session/end` | Sí | Finalizar una sesión de visita |
| POST | `/api/v1/wrapped/room` | Sí | Registrar la visita a una sala dentro de la sesión |

### Admin — `/api/v1/admin`

| Método | Endpoint | Auth requerida | Descripción |
|---|---|---|---|
| GET | `/api/v1/admin/users` | No | Listar todos los usuarios registrados |
| GET | `/api/v1/admin/assistance/requests` | No | Listar todas las solicitudes de asistencia |
| GET | `/api/v1/admin/assistance/hotspots` | No | Obtener hotspots de asistencia por ubicación |
| GET | `/api/v1/admin/assistance/hourly` | No | Tendencia horaria de solicitudes entrantes vs. resueltas |
| PATCH | `/api/v1/admin/assistance/requests/:id/status` | No | Actualizar el estado de una solicitud de asistencia |

---

## Backend — Cómo empezar

### Requisitos

- Node.js 18+
- Acceso a la instancia de GCP Cloud SQL PostgreSQL (proporcionada por el instructor)
- Cuenta en Vercel (para despliegue)

### Variables de entorno

Crea un archivo `.env` dentro de la carpeta `backend/`:

```env
DB_USER=tu_usuario_db
DB_HOST=tu_host_gcp
DB_NAME=tu_nombre_db
DB_PASSWORD=tu_contraseña_db
DB_PORT=5432
JWT_SECRET=tu_clave_secreta
```

> **Importante:** Nunca subas `.env` al repositorio. Ya está en el `.gitignore`.

### Desarrollo local

```bash
# Instalar dependencias
npm install

# Iniciar servidor local
npm start
# La API corre en http://localhost:3000
```

### Despliegue en Vercel

1. Sube el código a GitHub.
2. Importa el repositorio en [vercel.com](https://vercel.com).
3. Configura todas las variables de entorno en **Settings → Environment Variables**.
4. Vercel hace deploy automático en cada push a la rama configurada.

El archivo `vercel.json` ya está configurado para rutear todo a través de `server.js`:

```json
{
  "version": 2,
  "builds": [{ "src": "server.js", "use": "@vercel/node" }],
  "routes": [{ "src": "/(.*)", "dest": "server.js" }]
}
```

### Estructura del backend

```
backend/
├── controllers/
│   ├── authController.js
│   ├── profileController.js
│   ├── mapController.js
│   ├── adminController.js
│   ├── gamificationController.js
│   ├── assistanceController.js
│   ├── sensoryController.js
│   ├── surveyController.js
│   └── wrappedController.js
├── routes/
│   ├── auth.js
│   ├── profile.js
│   ├── map.js
│   ├── admin.js
│   ├── gamification.js
│   ├── assistance.js
│   ├── sensory.js
│   ├── survey.js
│   └── wrapped.js
├── middleware/
│   └── authGuard.js
├── services/
│   └── assistanceService.js
├── db/
│   ├── pool.js
│   ├── assistanceSchema.js
│   └── mapSchema.js
├── server.js
├── vercel.json
└── package.json
```

---

## App iOS — Cómo empezar

### Requisitos

- macOS 14 (Sonoma) o posterior
- Xcode 15.3+
- Dispositivo o simulador con iOS 17+
- Cuenta de Apple Developer (requerida para los entitlements de Translation y FoundationModels)
- Se recomienda un iPhone 15 Pro o posterior para inferencia LLM on-device y funciones de Apple Intelligence

### Entitlements

La app solicita `com.apple.developer.kernel.increased-memory-limit` para poder cargar los pesos del modelo Qwen2.5-0.5B en memoria.

### Configuración

1. Abre `Mi Horno 3.xcodeproj` en Xcode.
2. Ve a `Services/Config.swift` y verifica la URL base de la API:

```swift
enum Config {
    static let baseURL = "https://mi-horno-3-git-testing-joel-tellezs-projects.vercel.app/api/v1"
}
```

> Asegúrate de que `Config.swift` esté en el `.gitignore` para no subir la URL al repo.

### Correr la app

- Selecciona tu dispositivo o simulador en Xcode.
- Presiona **⌘R** para compilar y correr.
- Para una compilación limpia: **⇧⌘K** y luego **⌘R**.

> **Nota sobre el LLM:** En el primer inicio, `AssistantView` descarga los pesos del modelo `Qwen2.5-0.5B-Instruct-4bit` (~300 MB) desde Hugging Face vía `mlx-community`. Después de la primera descarga, el modelo queda en caché y carga instantáneamente. El `ModelContainer` se guarda como singleton estático — solo se carga una vez por sesión sin importar cuántas veces se abra la pantalla del asistente.

> **Nota sobre Apple Intelligence:** La guía sensorial (`SensoryAdvisorService`) y la generación de trivia (`ChallengesViewModel`) usan `FoundationModels.SystemLanguageModel`. Ambas funciones tienen fallback graceful cuando Apple Intelligence no está disponible — la guía sensorial usa respuestas predefinidas y la trivia cae al banco estático de `TriviaRepository`.

### Estructura de la app iOS

```
Mi Horno 3/
├── Models/
│   ├── Models.swift                   # Modelos Codable principales
│   ├── GamificationModels.swift       # XP, zonas, desafíos, medallas
│   ├── SurveyModels.swift             # Preguntas y payload de encuesta
│   ├── WrappedModel.swift             # Modelos del resumen de visita
│   ├── SensoryRoomData.swift          # Metadata de salas y system prompt sensorial
│   ├── SensoryRoomInfo.swift          # Nivel sensorial por sala
│   ├── PREGUNTA_TRIVIA.swift          # Structs @Generable para trivia con FoundationModels
│   ├── TriviaRepository.swift         # Banco estático de preguntas (fallback)
│   └── CameraMissionRepository.swift
├── ViewModels/
│   ├── AppRouter.swift
│   ├── AssistantViewModel.swift       # LLM on-device vía MLX + entrada por voz
│   ├── ChallengesViewModel.swift      # Generación de trivia con FoundationModels + Core ML
│   ├── LoginViewModel.swift
│   ├── HomeViewModel.swift
│   ├── MuseumNavViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── SensoryViewModel.swift
│   ├── SurveyViewModel.swift          # Encuesta offline-first con sincronización en background
│   ├── TranslationViewModel.swift
│   └── WrappedViewModel.swift
├── Views/
│   ├── Auth/                          # Pantallas de login y registro
│   ├── Home/
│   │   ├── Assistant/                 # AssistantView — chat con LLM on-device y voz
│   │   ├── Sensory/                   # SensoryView — guía sensorial con Apple Intelligence
│   │   ├── Explore/
│   │   └── Suggestions/
│   ├── Challenges/                    # Trivia, desafíos de cámara, perfilamiento, overlay de medalla
│   ├── Map/                           # Mapa interior con navegación QR y cálculo de rutas
│   ├── Profile/
│   │   ├── SurveyView.swift           # Encuesta de satisfacción de 6 preguntas
│   │   └── Wrapped/                   # Resumen animado de visita estilo stories
│   ├── Translation/                   # Subtítulos en vivo, traducción visual y conversacional
│   └── Main/                          # Tab bar y overlay de asistencia arrastrable
├── Services/
│   ├── Config.swift                   # URL base de la API (en .gitignore)
│   ├── LocalizationManager.swift      # Traducción dinámica vía Apple Translation
│   ├── SensoryAdvisorService.swift    # Guía sensorial con FoundationModels y fallback
│   ├── MuseumContext.swift             # Contexto del museo inyectado como system prompt
│   ├── VisionService.swift            # Wrapper de inferencia Core ML
│   └── GESTOR_CONTEXTO.swift
├── Components/
│   └── DesignSystem.swift             # Colores, tipografía y componentes compartidos
├── Mapa_vision/                       # Renderizado del mapa interior y navegación por QR
└── Resources/
    ├── ContextoIA/                     # Archivos Markdown de contexto para el system prompt
    └── Localizable.xcstrings
```

---

## Funciones de IA on-device

### Asistente LLM (MLX)

`AssistantView` carga `Qwen2.5-0.5B-Instruct-4bit` usando `MLXLLM`. Las respuestas se generan en streaming token a token con un máximo de 150 tokens a temperatura 0.6. El system prompt se inyecta desde `MuseumContext.swift` e instruye al modelo a responder siempre en el idioma del dispositivo del visitante. El caché de GPU está limitado a 20 MB mediante `MLX.GPU.set(cacheLimit:)`.

### Guía sensorial (FoundationModels)

`SensoryAdvisorService` usa `SystemLanguageModel.default` con una `LanguageModelSession` y un tipo de salida estructurado `SensoryResponse`. La respuesta incluye una respuesta en lenguaje natural, un consejo práctico y el nivel sensorial general de la zona consultada. En simuladores o dispositivos no compatibles, el servicio usa respuestas predefinidas para mantener la funcionalidad.

### Generación de trivia (FoundationModels)

`ChallengesViewModel` usa structs `@Generable` para generar 5 preguntas de trivia por zona, condicionadas al contexto del museo, la zona seleccionada y el perfil del visitante (edad, género, necesidades de accesibilidad). El límite de 50 preguntas generadas por IA por zona evita el abuso. Las trivias generadas se persisten localmente en UserDefaults y se sincronizan al backend en `/api/v1/gamification/generatedQuiz`.

---

## Base de datos

La base de datos PostgreSQL está alojada en GCP Cloud SQL y es administrada por el instructor del curso. El esquema cubre usuarios, perfiles, intereses, avatares, medallas, nodos y aristas del mapa, historial de desafíos, progreso de gamificación, reportes de asistencia, visitas sensoriales, respuestas de encuesta, sesiones wrapped y preguntas de trivia generadas por IA.

La conexión se maneja mediante un pool compartido en `db/pool.js` con SSL habilitado.

---

## Equipo

| Integrante | Módulo |
|---|---|
| Joel Téllez | Autenticación, perfil, asistente LLM on-device, traducción, localización |
| Carlos Baranda | Desafíos, gamificación, generación de trivia con FoundationModels, sistema de XP |
| Jorge Pereda | Mapa interior, navegación por QR, overlay de asistencia, dashboard de administración |
| Sebastián Sánchez | Guía sensorial, resumen wrapped de visita, encuesta de satisfacción |

**Materia:** Integración de seguridad informática en redes y sistemas de software  
**Profesora:** Elvia Itzamná Rosas Herrera  
**Institución:** Tecnológico de Monterrey
