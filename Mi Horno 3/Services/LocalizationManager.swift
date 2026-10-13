// LocalizationManager.swift
// Usa Apple Translation framework (iOS 17+) para traducir la app
// al idioma nativo del dispositivo, sin internet tras la primera descarga.

import Foundation
import Combine
import SwiftUI
import Translation

// ─────────────────────────────────────────────
// MARK: - Base strings (español)
// ─────────────────────────────────────────────
struct L {
    static let appSubtitle              = "MUSEO DEL ACERO"
    static let loginTabSignin           = "Iniciar sesión"
    static let loginTabRegister         = "Crear cuenta"
    static let loginFieldName           = "Nombre completo"
    static let loginFieldEmail          = "Correo electrónico"
    static let loginFieldPassword       = "Contraseña"
    static let loginCtaSignin           = "Entrar"
    static let loginCtaRegister         = "Crear cuenta"
    static let loginDemoHint            = "Demo: joel@horno3.com  /  Shakira123"
    static let loginErrName             = "Ingresa tu nombre"
    static let loginErrEmail            = "Ingresa un correo válido"
    static let loginErrPassword         = "La contraseña debe tener mínimo 6 caracteres"
    static let loginErrFields           = "Completa tus datos"
    static let loginErrWrongPwd         = "Contraseña incorrecta"
    static let loginSubtitleRegister    = "Únete a la experiencia horno³"
    static let loginSubtitleSignin      = "Bienvenido de nuevo"
    static let loginFieldLastName       = "Apellido"
    static let loginAlreadyHaveAccount  = "¿Ya tienes cuenta?"
    static let loginNoAccount           = "¿No tienes cuenta?"
    static let tabHome                  = "Inicio"
    static let tabChallenges            = "Desafíos"
    static let tabMap                   = "Mapa"
    static let tabTranslation           = "Traducción"
    static let tabProfile               = "Perfil"
    static let homeVisitor              = "Visitante"
    static let homeSuggestionsTitle     = "Sugerencias para ti"
    static let homeExploreTitle         = "Explora"
    static let homeExploreAssistant     = "Asistente de visita"
    static let homeExploreAssistantDesc = "Pregunta lo que quieras sobre el museo con IA"
    static let homeExploreChallenges    = "Mis Desafíos"
    static let homeExploreChallengesDesc = "Pon a prueba lo que aprendiste"
    static let homeExploreMap           = "Mapa del museo"
    static let homeExploreMapDesc       = "Navega por el recinto fácilmente"
    static let homeExploreSensory       = "Guía Sensorial"
    static let homeExploreSensoryDesc   = "Experiencia accesible para todos"
    static let homeProgressTitle        = "Mi progreso"
    static let homeProgressDone         = "Desafíos completados"
    static let homeProgressEmpty        = "Completa desafíos para ver tus estadísticas"
    static let homeProgressStart        = "¡Comenzar desafíos!"
    static let homeProgressContinue     = "Continuar desafíos"
    static let museumOpen               = "Museo abierto ahora"
    static let museumClosed             = "Museo cerrado"
    static let museumClosedTitle        = "El museo está cerrado ahora"
    static let museumSchedule           = "Mar–Jue 11am–6pm  ·  Vie–Dom 12pm–7pm  ·  Lun cerrado"
    static let attractionSoon           = "¡Pronto!"
    static let attractionAllDay         = "Todo el día"
    static let attractionShowIn         = "%lld min para el show"
    static let statsAnswered            = "Respondidas"
    static let statsCorrect             = "Correctas"
    static let statsIncorrect           = "Incorrectas"
    static let challengesTitle          = "Desafíos"
    static let challengesSubtitle       = "Demuestra lo que aprendiste en el museo"
    static let challengesOf             = "de"
    static let challengesQuestions      = "preguntas"
    static let challengesReset          = "Reiniciar"
    static let challengesComplete       = "¡Desafío completado!"
    static let challengesScore          = "%lld de %lld respuestas correctas"
    static let challengesRetry          = "Volver a intentar"

    // Challenge zones
    static let challengeZoneGeneral              = "General"
    static let challengeZoneGeneralSubtitle      = "Conocimiento general del museo"
    static let challengeZoneHistory              = "Historia"
    static let challengeZoneHistorySubtitle      = "La historia del acero en México"
    static let challengeZoneSteelGallery         = "Galería del Acero"
    static let challengeZoneSteelGallerySubtitle = "Ciencia e innovación siderúrgica"

    // Challenge card titles & subtitles
    static let challengeGeneralTitle             = "Desafío General"
    static let challengeGeneralSubtitle          = "Pon a prueba tu conocimiento del museo"
    static let challengeHistoryTitle             = "Historia del Acero"
    static let challengeHistorySubtitle          = "Preguntas sobre la Fundidora y su legado"
    static let challengeSteelGalleryTitle        = "Galería del Acero"
    static let challengeSteelGallerySubtitle     = "Ciencia y tecnología del acero"

    // Quiz flow buttons & labels
    static let challengesCheck                   = "Verificar"
    static let challengesContinue                = "Continuar"
    static let challengesSeeResults              = "Ver resultados"
    static let challengesQuestionLabel           = "Pregunta %lld de %lld"

    static let mapMuseumName            = "horno³ Museo del Acero"
    static let mapAddress               = "Av. Fundidora 501, Monterrey"
    static let mapAttractions           = "Atracciones"
    static let mapDirections            = "Cómo llegar"
    static let mapScanTitle             = "Escaneando QR"
    static let mapQrDetected            = "QR detectado"
    static let mapCurrentPosition       = "Posición actual"
    static let mapAlignQr               = "Alinea el QR para ubicar al usuario"
    static let mapPendingLocation       = "Ubicación pendiente"
    static let mapRoutes                = "Rutas"
    static let mapQuickDestination      = "Destino rápido"
    static let mapMuseumIndoor          = "Mapa del museo"
    static let mapEndpointFallback      = "QR leído sin respuesta del endpoint"
    static let mapLoadingDetails        = "Cargando información..."
    static let mapSettings              = "Ajustes"
    static let mapWheelchairMode        = "Modo silla de ruedas"
    static let mapGoHere                = "Ir a este lugar"
    static let mapIntroTitle            = "Cómo usar el mapa"
    static let mapIntroMessage          = "Escanea un QR para ubicarte dentro del museo. Después abre Rutas o Destino rápido, elige a dónde quieres ir y sigue el camino marcado. El botón de accesibilidad prioriza elevadores y evita escaleras."
    static let mapIntroButton           = "Entendido"
    static let mapCameraUnavailable     = "La cámara no está disponible en este dispositivo"
    static let mapCameraInputError      = "No se pudo inicializar la cámara"
    static let mapNodeDetailsError      = "No se pudieron cargar los detalles del nodo"
    static let mapRouteGeneral          = "Ruta General"
    static let mapRouteSculptures       = "Ruta Esculturas"
    static let mapRoutePaintings        = "Ruta Pinturas"
    static let mapNodeEntrance          = "Entrada"
    static let mapNodeCentral           = "Nodo Central"
    static let mapNodeBathrooms         = "Baños"
    static let mapNodeSnacks            = "Snacks"
    static let mapNodeSouvenirs         = "Recuerdos"
    static let mapNodeInfo              = "Información"
    static let mapNodeRestArea          = "Área de descanso"
    static let mapNodeEmergencyExitNorth = "Salida de emergencia norte"
    static let mapNodeEmergencyExitSouth = "Salida de emergencia sur"
    static let mapNodeRampNorth         = "Rampa norte"
    static let mapNodeRampSouth         = "Rampa sur"
    static let mapNodeElevator          = "Elevador"
    static let mapAttrAllDay            = "Todo el horario"
    static let translationTitle         = "Traducción"
    static let translationSubtitle      = "Herramientas de accesibilidad para tu visita"
    static let translationSubtitlesTitle    = "Subtítulos en vivo"
    static let translationSubtitlesSubtitle = "Transcripción automática al idioma de tu dispositivo. Ideal para exposiciones y guías."
    static let translationVisualTitle       = "Descripción visual"
    static let translationVisualSubtitle    = "Apunta tu cámara a textos o señalizaciones y se traducirán en pantalla al instante."
    static let translationConvTitle         = "Conversación 1 a 1"
    static let translationConvSubtitle      = "Habla con guías del museo en tu idioma. La pantalla muestra ambas traducciones en tiempo real."
    static let translationBack              = "Volver"
    static let translationLive              = "EN VIVO"
    static let translationPlaceholder       = "Las transcripciones aparecerán aquí mientras hablen los expositores…"
    static let translationMicDenied         = "Activa el micrófono en Ajustes > horno³"
    static let translationCameraActive      = "Cámara activa"
    static let translationCameraHint        = "Apunta a texto, señales o exhibiciones\npara verlos traducidos al instante"
    static let translationVisualResult      = "Traducción detectada"
    static let translationVisualNote        = "Usa Vision + Translation de Apple para reconocer y traducir texto en tiempo real. Requiere iOS 17+."
    static let translationMicPress          = "Presionar para hablar"
    static let translationMicListening      = "Escuchando…"
    static let translationSpanish           = "Español"
    static let translationDetecting         = "Detectando: %@"
    static let assistantTitle               = "Asistente de visita"
    static let assistantIdleHint            = "Presiona + para encender la cámara\ny hacer tu primera pregunta"
    static let assistantEmptyHint           = "Pregunta lo que quieras sobre el museo"
    static let assistantError               = "Hubo un error. Intenta de nuevo."
    static let assistantNetworkError        = "Sin conexión. Revisa tu internet."
    static let assistantStateIdle           = "Listo para ayudarte"
    static let assistantStateActive         = "Toca el micrófono para preguntar"
    static let assistantStateListening      = "Escuchando…"
    static let assistantStateReady          = "Listo para enviar"
    static let assistantStateProcessing     = "Procesando tu pregunta…"
    static let assistantStateWaiting        = "Pensando…"
    static let assistantStateResponding     = "Respondiendo"
    static let greetingMorning              = "Buenos días"
    static let greetingAfternoon            = "Buenas tardes"
    static let greetingEvening              = "Buenas noches"

    // Attraction names & descriptions
    static let attrHistoryName    = "Galería de Historia"
    static let attrShowName       = "Show del Horno"
    static let attrPaseoName      = "Paseo por la Cima"
    static let attrSteelName      = "Galería del Acero"
    static let attrPlanetName     = "horno³ Planeta Tierra"
    static let attrChainName      = "Reacción en Cadena"
    static let attrHistoryDesc    = "Viaja a través del tiempo desde 1900 hasta la actualidad. Encuentra videos históricos, testimonios de ex trabajadores, artefactos antiguos y mucho más."
    static let attrShowDesc       = "Espectáculo en la Casa de Vaciados con vapor, humo, fuego real y chispas. Conoce el interior del Horno Alto No.3, una experiencia única en el mundo."
    static let attrPaseoDesc      = "Sube en cabinas panorámicas abiertas 40 metros sobre el Horno Alto. Vista espectacular de Monterrey de día y de noche con iluminación ornamental."
    static let attrSteelDesc      = "Experiencia interactiva: baja en elevador a 200 m bajo tierra a una mina de carbón, explota una mina a cielo abierto y visita el Núcleo Científico."
    static let attrPlanetDesc     = "Observa huracanes, terremotos y tsunamis. Descubre el cambio climático y datos científicos de nuestro planeta. Patrocinado por GRUMA."
    static let attrChainDesc      = "Instalación permanente en el lobby. Visualiza cómo acciones simples desencadenan eventos complejos con engranajes, poleas y catapultas."

    // Schedule notes
    static let scheduleAllDay        = "Disponible todo el horario"
    static let scheduleHourly        = "Cada hora en punto"
    static let scheduleAsk           = "Consultar en taquilla"
    static let scheduleClimate       = "Sujeto al clima"
    static let scheduleAvailability  = "Sujeto a disponibilidad"

    // Group titles
    static let groupGalleries        = "Galerías"
    static let groupPaseo            = "Paseo por la Cima"
    static let groupShows            = "Shows"

    // Profile
    static let profileTitle             = "Mi perfil"
    static let profileOptionalInfo      = "Información opcional"
    static let profileFirstName         = "Nombre"
    static let profileLastName          = "Apellido"
    static let profileEmail             = "Correo electrónico"
    static let profileCountry           = "País de origen"
    static let profileCity              = "Ciudad de origen"
    static let profileAgeRange          = "Rango de edad"
    static let profileYears             = "años"
    static let profileMyInterests       = "Mis intereses"
    static let profileChangePassword    = "Cambiar contraseña"
    static let profileCurrentPassword   = "Contraseña actual"
    static let profileNewPassword       = "Nueva contraseña"
    static let profileUpdatePassword    = "Actualizar contraseña"
    static let profilePasswordUpdated   = "¡Contraseña actualizada!"
    static let profilePasswordMinChars  = "Mínimo 6 caracteres"
    static let profilePasswordWrong     = "Contraseña actual incorrecta"
    static let profileLogout            = "Cerrar sesión"
    static let profileLogoutConfirm     = "¿Cerrar sesión?"
    static let profileLogoutMessage     = "Se cerrará tu sesión en este dispositivo."
    static let profileDeleteAccount     = "Eliminar cuenta"
    static let profileDeleteConfirm     = "¿Eliminar tu cuenta?"
    static let profileDeleteMessage     = "Esta acción es permanente y no se puede deshacer."
    static let profileDeleteCancel      = "Cancelar"
    static let profileLoginInfo         = "Información de acceso"
    static let profileInterestsCount    = "seleccionados"
    static let profileSave              = "Confirmar cambios"
    static let profileSaved             = "¡Guardado!"
    static let profileMedals            = "Medallas"
    // Badge detail view
    static let badgeSectionTitle        = "Mis Insignias"
    static let badgeSectionHint         = "Sigue haciendo desafíos para liberar más rangos"
    static let badgeLocked              = "Bloqueada"
    static let badgeLockedHint          = "Completa más desafíos para desbloquear esta insignia"
    static let badgeLevelGold           = "Nivel Oro"
    static let badgeLevelSilver         = "Nivel Plata"
    static let badgeLevelBronze         = "Nivel Bronce"
    static let badgeLabelPioneer        = "Pionero"
    static let badgeLabelVoice          = "Voz del Horno"
    static let badgeLabelMaster         = "Máster Desafíos"
    static let badgeLabelSpecial        = "Insignia Especial"
    // Badge display names — zones and specials
    static let badgeZoneGeneral         = "General"
    static let badgeZoneHistory         = "Historia"
    static let badgeZoneSteel           = "Acero"
    static let badgeNamePioneer         = "Pionero"
    static let badgeNameVoice           = "Voz del Horno"
    static let badgeNameMaster          = "Máster"

    static let profileMetrics           = "Métricas de visita"
    static let profileSummaryTitle      = "Ver tu resumen de la visita"
    static let profileSummaryDesc       = "Genera un resumen personalizado de tu experiencia en horno³, incluyendo los lugares que visitaste, tus resultados en desafíos y estadísticas."
    static let profileSummaryGenerate   = "Generar"
    static let profileSummaryChallenges = "Desafíos"
    static let profileSummaryCorrect    = "Correctas"
    static let profileSummaryAccuracy   = "Precisión"
    static let profilePickAvatar        = "Elige tu avatar"
    static let profileNoAvatars         = "Sin avatares disponibles"

    // Medals
    static let medalFirstStep           = "Primer paso"
    static let medalFirstStepDesc       = "Responde tu primer desafío"
    static let medalStreak              = "En racha"
    static let medalStreakDesc          = "5 desafíos completados"
    static let medalComplete            = "Completista"
    static let medalCompleteDesc        = "Todos los desafíos completados"
    static let medalPrecision           = "Precisión"
    static let medalPrecisionDesc       = "5 respuestas correctas"
    static let medalPerfect             = "Perfecto"
    static let medalPerfectDesc         = "10 de 10 correctas"
    static let medalExplorer            = "Explorador horno³"
    static let medalExplorerDesc        = "Visita completada con 7+ correctas"

    // Challenge questions & answers
    static let q0 = "¿Qué era originalmente la estructura que hoy alberga al Museo Horno 3?"
    static let q1 = "¿En qué año se fundó la «Fundidora de Fierro y Acero de Monterrey»?"
    static let q2 = "El Horno 3 es famoso por ser el primero en México en utilizar…"
    static let q3 = "¿Cómo se llama la zona del museo con experimentos científicos interactivos?"
    static let q4 = "¿Qué mineral se extraía para ser fundido junto con carbón y caliza?"
    static let q5 = "¿Cuál es el nombre del espectáculo que recrea el horno con fuego real?"
    static let q6 = "¿Qué altura aproximada tiene la estructura del Horno 3?"
    static let q7 = "¿Cómo se llama la atracción que permite ver toda la ciudad desde la cima?"
    static let q8 = "¿Cuál es un subproducto del proceso de fundición explicado en el museo?"
    static let q9 = "¿En qué año fue declarado el Horno 3 Monumento Artístico de la Nación?"
    static let q0a = "Una fábrica de textiles"
    static let q0b = "Un alto horno de fundición de hierro"
    static let q0c = "Una planta eléctrica"
    static let q1a = "1900"; static let q1b = "1950"; static let q1c = "1880"
    static let q2a = "Energía solar"
    static let q2b = "Gas natural en lugar de carbón"
    static let q2c = "Sistema de refrigeración por agua de circuito cerrado"
    static let q3a = "Galería de la Historia"
    static let q3b = "Galería del Acero"
    static let q3c = "Observatorio de la Tierra"
    static let q4a = "Cobre"; static let q4b = "Mineral de Hierro"; static let q4c = "Plata"
    static let q5a = "El Show de la Chispa"
    static let q5b = "El Show del Horno (Vaciado simbólico)"
    static let q5c = "La Danza del Acero"
    static let q6a = "40 metros"; static let q6b = "70 metros"; static let q6c = "110 metros"
    static let q7a = "Mirador de la Fundidora"
    static let q7b = "Paseo por la Cima"
    static let q7c = "El Faro del Norte"
    static let q8a = "Escoria"; static let q8b = "Petróleo"; static let q8c = "Arena sílica"
    static let q9a = "1986 (cierre de la empresa)"
    static let q9b = "2007 (apertura como museo)"
    static let q9c = "2015"
    static let e0 = "El Horno Alto No.3 fue parte de la Fundidora de Fierro y Acero de Monterrey, dedicada a la fundición de hierro."
    static let e1 = "La Fundidora fue establecida en 1900, siendo uno de los primeros complejos siderúrgicos de América Latina."
    static let e2 = "El sistema de refrigeración por agua de circuito cerrado fue una innovación tecnológica importante para su época."
    static let e3 = "La Galería del Acero alberga el Núcleo Científico con demostraciones de ciencia en vivo."
    static let e4 = "El mineral de hierro es la materia prima fundamental en el proceso de producción del acero."
    static let e5 = "El Show del Horno se lleva a cabo en la antigua Casa de Vaciados con vapor, humo y fuego real."
    static let e6 = "El Horno Alto No.3 alcanza aproximadamente 70 metros, siendo uno de los más grandes de México."
    static let e7 = "El Paseo por la Cima ofrece cabinas panorámicas que ascienden los 40 metros del trayecto."
    static let e8 = "La escoria es el residuo del proceso de fundición del hierro, explicado en las galerías interactivas."
    static let e9 = "En 2007, al abrir como museo, el Horno 3 fue declarado Monumento Artístico de la Nación."

    // Conversation / Visual / Subtitles
    static let convTapToSpeak    = "Toca para hablar"
    static let convTapMic        = "Toca el micrófono para hablar"
    static let visualLive        = "Apuntando… traducción automática"
    static let visualNoText      = "No se detectó texto. Acerca la cámara al texto."
    static let visualScanning    = "Escaneando…"
    static let subtitlesNoSpeech = "Reconocimiento de voz no disponible en este dispositivo."

    // Sensory Guide UI
    static let sensoryTitle          = "Guía Sensorial"
    static let sensorySubtitle       = "Pregúntame sobre ruido, iluminación, duración y accesibilidad de cada sala."
    static let sensorySimulatorBanner = "Modo simulador — respuestas de prueba"
    static let sensorySuggestions    = "Sugerencias"
    static let sensoryPlaceholder    = "Escribe tu pregunta..."
    static let sensoryClear          = "Limpiar"
    static let sensoryIntensity      = "Intensidad"
    static let sensoryTip            = "Consejo"
    static let sensoryErrorMsg       = "No pude obtener una respuesta en este momento. Por favor intenta de nuevo."

    // Sensory quick suggestions
    static let sensoryQ1 = "¿Cuál sala es la más tranquila?"
    static let sensoryQ2 = "¿Hay luces intermitentes en alguna sala?"
    static let sensoryQ3 = "¿Qué sala tiene más ruido?"
    static let sensoryQ4 = "¿Por dónde me conviene empezar?"

    // Sensory levels
    static let sensoryLevelTranquila = "tranquila"
    static let sensoryLevelModerada  = "moderada"
    static let sensoryLevelIntensa   = "intensa"

    // ── Wrapped ──────────────────────────────────────────────────
    // Navigation
    static let wrappedTitle                 = "Mi resumen"
    static let wrappedNext                  = "Siguiente"
    static let wrappedClose                 = "Cerrar"
    // Card: welcome
    static let wrappedWelcomeTitle          = "Tu visita al\nHorno 3"
    static let wrappedWelcomeValue          = "Resumen"
    static let wrappedWelcomeSubtitle       = "Esto es lo que viviste hoy"
    // Card: challenges
    static let wrappedChallengesTitle       = "Retos\ncompletados"
    static let wrappedChallengesAllDone     = "¡Completaste todos los retos!"
    static let wrappedChallengesRemaining   = "Aún quedan %lld por descubrir"
    // Card: accuracy
    static let wrappedAccuracyTitle         = "Tu\nprecisión"
    static let wrappedAccuracySub90         = "Precisión excepcional. ¡Eres un experto!"
    static let wrappedAccuracySub70         = "Muy buen desempeño. ¡Sigue así!"
    static let wrappedAccuracySub50         = "Buen intento. Hay espacio para mejorar."
    static let wrappedAccuracySubLow        = "Cada intento cuenta. ¡Vuelve a intentarlo!"
    static let wrappedAccuracySubZero       = "Completa retos para ver tu precisión."
    // Card: medals
    static let wrappedMedalsTitle           = "Medallas\nobtenidas"
    static let wrappedMedalsAllDone         = "¡Colección completa!"
    static let wrappedMedalsRemaining       = "Faltan %lld medallas por desbloquear"
    // Card: nickname
    static let wrappedNicknameTitle         = "Tu apodo\nde hoy"
    // Card: closing
    static let wrappedClosingTitle          = "¡Hasta\npronto!"
    static let wrappedClosingValue          = "Horno 3"
    static let wrappedClosingSubtitle       = "Gracias por ser parte de la historia del acero en México"
    // Nicknames
    static let nickMaestroName              = "El Maestro del Acero"
    static let nickMaestroDesc              = "Respondiste todo con una precisión excepcional."
    static let nickColeccionistaName        = "El Coleccionista"
    static let nickColeccionistaDesc        = "Completaste todos los retos y acumulaste medallas."
    static let nickExploradorName           = "El Explorador"
    static let nickExploradorDesc           = "Tu curiosidad te llevó lejos en el museo."
    static let nickPerspicazName            = "El Perspicaz"
    static let nickPerspicazDesc            = "Tus respuestas demuestran una mente aguda."
    static let nickAprendizName             = "El Aprendiz"
    static let nickAprendizDesc             = "Diste tus primeros pasos en el mundo del acero."
    static let nickCuriosoName              = "El Visitante Curioso"
    static let nickCuriosoDesc              = "El museo tiene mucho más por descubrirte."

    // ── Trivia History Questions ─────────────────────────────────────────────
    static let tHistSidermex1Text        = "¿Qué empresa administrada por el gobierno se creó en 1977 para coordinar la producción de acero?"
    static let tHistSidermex1Opt0         = "AHMSA"
    static let tHistSidermex1Opt1         = "SIDERMEX"
    static let tHistSidermex1Opt2         = "SICARTSA"
    static let tHistSidermex1Opt3         = "HYLSA"
    static let tHistSidermex1Explanation = "En 1977 se creó Siderurgia Mexicana (SIDERMEX) para agrupar a Fundidora, AHMSA y SICARTSA."
    static let tHistLema70sText        = "¿Cuál era el lema del Estado en los años setenta para fomentar el desarrollo?"
    static let tHistLema70sOpt0         = "Acero + Petróleo = Future"
    static let tHistLema70sOpt1         = "Industria + Trabajo = Progreso"
    static let tHistLema70sOpt2         = "Acero + Energía = Desarrollo"
    static let tHistLema70sOpt3         = "México unido por el acero"
    static let tHistLema70sExplanation = "El lema era 'Acero + Energía = Desarrollo', buscando fortalecer industrias estratégicas."
    static let tHistPrimerEdificioText        = "¿Cuál fue el primer edificio alto de la Ciudad de México construido con acero de Fundidora?"
    static let tHistPrimerEdificioOpt0         = "Torre Latinoamericana"
    static let tHistPrimerEdificioOpt1         = "La Nacional"
    static let tHistPrimerEdificioOpt2         = "Palacio de Hierro"
    static let tHistPrimerEdificioOpt3         = "Edificio Ermita"
    static let tHistPrimerEdificioExplanation = "Construido en 1932, 'La Nacional' fue el primer edificio de 12 pisos con esqueleto de acero de Fundidora."
    static let tHistPorfirioDiazText        = "¿Qué infraestructura consideraba Porfirio Díaz como la clave del progreso?"
    static let tHistPorfirioDiazOpt0         = "Puertos"
    static let tHistPorfirioDiazOpt1         = "Telégrafo"
    static let tHistPorfirioDiazOpt2         = "Ferrocarril"
    static let tHistPorfirioDiazOpt3         = "Caminos"
    static let tHistPorfirioDiazExplanation = "Para Díaz, el ferrocarril era esencial para modernizar México y conectar la industria."
    static let tHistHuelgas7080Text        = "¿Qué pedía principalmente el sindicato durante las huelgas de los años 70 y 80?"
    static let tHistHuelgas7080Opt0         = "Menos horas de trabajo"
    static let tHistHuelgas7080Opt1         = "Aumentos salariales y mejores servicios médicos"
    static let tHistHuelgas7080Opt2         = "Nuevas herramientas"
    static let tHistHuelgas7080Opt3         = "Cierre de plantas"
    static let tHistHuelgas7080Explanation = "El sindicato presionaba por mejoras en salarios, prestaciones y servicios médicos ante la inflación."
    static let tHistHylTecnologiaText        = "¿Qué proceso revolucionario inventaron los ingenieros de HYLSA en 1957?"
    static let tHistHylTecnologiaOpt0         = "Alto Horno"
    static let tHistHylTecnologiaOpt1         = "Laminación en frío"
    static let tHistHylTecnologiaOpt2         = "Reducción Directa (Tecnología HYL)"
    static let tHistHylTecnologiaOpt3         = "Vaciado continuo"
    static let tHistHylTecnologiaExplanation = "La Reducción Directa permitiría obtener hierro puro sin necesidad de carbón, usando fierro esponja."
    static let tHistFundidoraCierreText        = "¿En qué año ocurrió el impacto del cierre de la Fundidora Monterrey?"
    static let tHistFundidoraCierreOpt0         = "1976"
    static let tHistFundidoraCierreOpt1         = "1982"
    static let tHistFundidoraCierreOpt2         = "1986"
    static let tHistFundidoraCierreOpt3         = "1990"
    static let tHistFundidoraCierreExplanation = "Fundidora Monterrey cerró en mayo de 1986, afectando profundamente la economía de la región."
    static let tHistMonterreyUbicacionText        = "¿Por qué Monterrey fue elegida para la primera planta de acero moderna en 1900?"
    static let tHistMonterreyUbicacionOpt0         = "Por su clima"
    static let tHistMonterreyUbicacionOpt1         = "Cercanía a minas de hierro y carbón, y cruce de ferrocarriles"
    static let tHistMonterreyUbicacionOpt2         = "Por el acceso al mar"
    static let tHistMonterreyUbicacionOpt3         = "Por ser la capital del país"
    static let tHistMonterreyUbicacionExplanation = "Su ubicación estratégica cerca de Coahuila (carbón) y sus vías ferroviarias fueron determinantes."
    static let tHistSeguridadPepeGalloText        = "¿Qué nombre recibían las filminas de capacitación de seguridad en HYLSA?"
    static let tHistSeguridadPepeGalloOpt0         = "Juan Acero"
    static let tHistSeguridadPepeGalloOpt1         = "Pepe Gallo"
    static let tHistSeguridadPepeGalloOpt2         = "Luis Martillo"
    static let tHistSeguridadPepeGalloOpt3         = "Paco Casco"
    static let tHistSeguridadPepeGalloExplanation = "En los programas de capacitación se usaban filminas llamadas 'Pepe Gallo' para prevenir accidentes."
    static let tHistPapeAhmsaText        = "¿Quién fue el gerente general de Altos Hornos que supervisó la construcción del Horno Alto No. 1?"
    static let tHistPapeAhmsaOpt0         = "Vicente Ferrara"
    static let tHistPapeAhmsaOpt1         = "Harold R. Pape"
    static let tHistPapeAhmsaOpt2         = "Bernardo Reyes"
    static let tHistPapeAhmsaOpt3         = "Lázaro Cárdenas"
    static let tHistPapeAhmsaExplanation = "Harold R. Pape fue una figura clave en la planeación y éxito de AHMSA en Monclova."
    static let tHistCrisis7682Text        = "¿Qué factor dificultó que las empresas acereras pagaran sus deudas en 1976 y 1982?"
    static let tHistCrisis7682Opt0         = "Falta de demanda"
    static let tHistCrisis7682Opt1         = "Devaluación de la moneda"
    static let tHistCrisis7682Opt2         = "Exceso de personal"
    static let tHistCrisis7682Opt3         = "Huelgas"
    static let tHistCrisis7682Explanation = "La devaluación del peso frente al dólar hizo casi imposible pagar los créditos extranjeros."
    static let tHistFamiliaAceroText        = "¿Cómo se refería Fundidora a su mano de obra debido a la estrecha relación entre trabajadores?"
    static let tHistFamiliaAceroOpt0         = "El Gremio"
    static let tHistFamiliaAceroOpt1         = "La Gran Familia del Acero"
    static let tHistFamiliaAceroOpt2         = "Los Obreros Unidos"
    static let tHistFamiliaAceroOpt3         = "Sindicato Fuerte"
    static let tHistFamiliaAceroExplanation = "Se les llamaba 'La Gran Familia del Acero' porque generaciones enteras trabajaban en la planta."
    static let tHistConstitucion1917Text        = "¿Qué derecho laboral se legisló al término de la Revolución en la Constitución de 1917?"
    static let tHistConstitucion1917Opt0         = "Sueldos en dólares"
    static let tHistConstitucion1917Opt1         = "Jornada de ocho horas"
    static let tHistConstitucion1917Opt2         = "Vacaciones pagadas de un mes"
    static let tHistConstitucion1917Opt3         = "Seguro dental"
    static let tHistConstitucion1917Explanation = "La Constitución de 1917 reconoció la jornada de ocho horas y el derecho a huelga."
    static let tHistColonialProhibicionText        = "¿Por qué estaba prohibido explotar el hierro durante casi toda la época colonial?"
    static let tHistColonialProhibicionOpt0         = "No sabían cómo"
    static let tHistColonialProhibicionOpt1         = "Para obligar a comprar herramientas a España"
    static let tHistColonialProhibicionOpt2         = "Era considerado sagrado"
    static let tHistColonialProhibicionOpt3         = "Por falta de esclavos"
    static let tHistColonialProhibicionExplanation = "La Corona Española prohibía la explotación para asegurar que sus dominios compraran hierro de la 'madre patria'."
    static let tHistSegundaGuerraText        = "¿Qué efecto tuvo la Segunda Guerra Mundial en la industria del acero en México?"
    static let tHistSegundaGuerraOpt0         = "Bajó la producción"
    static let tHistSegundaGuerraOpt1         = "Aumentó la demanda interna porque EE.UU. no enviaba productos"
    static let tHistSegundaGuerraOpt2         = "Se cerraron las fábricas"
    static let tHistSegundaGuerraOpt3         = "Se prohibió exportar"
    static let tHistSegundaGuerraExplanation = "EE.UU. usaba su acero para armamento, lo que disparó la necesidad de producción nacional en México."
    static let tHistDurangoBlockadeText        = "¿Cuántos días duró el bloqueo en Durango que dejó a Fundidora sin mineral en 1970?"
    static let tHistDurangoBlockadeOpt0         = "50 días"
    static let tHistDurangoBlockadeOpt1         = "100 días"
    static let tHistDurangoBlockadeOpt2         = "171 días"
    static let tHistDurangoBlockadeOpt3         = "300 días"
    static let tHistDurangoBlockadeExplanation = "Estudiantes y campesinos bloquearon el transporte de mineral de Cerro de Mercado por 171 días."
    static let tHistObregonSchoolsText        = "¿Qué presidente construyó más escuelas rurales en 4 años que Porfirio Díaz en 30?"
    static let tHistObregonSchoolsOpt0         = "Plutarco Elías Calles"
    static let tHistObregonSchoolsOpt1         = "Álvaro Obregón"
    static let tHistObregonSchoolsOpt2         = "Lázaro Cárdenas"
    static let tHistObregonSchoolsOpt3         = "Venustiano Carranza"
    static let tHistObregonSchoolsExplanation = "Álvaro Obregón logró un avance educativo masivo en su corto periodo de 1920 a 1924."
    static let tHistDeaceroOriginsText        = "¿Qué producía originalmente DEACERO a mediados de los cincuenta?"
    static let tHistDeaceroOriginsOpt0         = "Vigas de acero"
    static let tHistDeaceroOriginsOpt1         = "Malla ciclónica"
    static let tHistDeaceroOriginsOpt2         = "Clavos"
    static let tHistDeaceroOriginsOpt3         = "Lámina galvanizada"
    static let tHistDeaceroOriginsExplanation = "DEACERO comenzó como un pequeño taller que producía malla ciclónica."
    static let tHistFirstMexicanBossText        = "¿Quién fue el primer jefe de departamento mexicano en Fundidora?"
    static let tHistFirstMexicanBossOpt0         = "Flavio Galindo"
    static let tHistFirstMexicanBossOpt1         = "Vicente Ferrara"
    static let tHistFirstMexicanBossOpt2         = "Manuel Carranza"
    static let tHistFirstMexicanBossOpt3         = "José Carrillo"
    static let tHistFirstMexicanBossExplanation = "Flavio Galindo fue el primer mexicano en ocupar una jefatura, liderando a los 'Elefantes del Acero'."
    static let tHistColoniaAceroText        = "¿Quiénes vivían principalmente en la 'Colonia Acero'?"
    static let tHistColoniaAceroOpt0         = "Solo obreros"
    static let tHistColoniaAceroOpt1         = "Ingenieros y empleados de confianza"
    static let tHistColoniaAceroOpt2         = "Inversionistas extranjeros"
    static let tHistColoniaAceroOpt3         = "Políticos locales"
    static let tHistColoniaAceroExplanation = "En la Colonia Acero vivían empleados de confianza y especialistas que la empresa necesitaba tener cerca para emergencias."
    static let tHistAguadorStoryText        = "En los relatos de los obreros, ¿qué labor desempeñaba Anatolio en la Maestranza?"
    static let tHistAguadorStoryOpt0         = "Soldador"
    static let tHistAguadorStoryOpt1         = "Aguador"
    static let tHistAguadorStoryOpt2         = "Maquinista"
    static let tHistAguadorStoryOpt3         = "Carpintero"
    static let tHistAguadorStoryExplanation = "Anatolio trabajaba como aguador y caminaba una hora desde el barrio de San Luisito."
    static let tHistTorpedoCarText        = "¿A dónde se transportaba el hierro líquido en los carros torpedo?"
    static let tHistTorpedoCarOpt0         = "A la mina"
    static let tHistTorpedoCarOpt1         = "A la planta de aceración"
    static let tHistTorpedoCarOpt2         = "Al muelle"
    static let tHistTorpedoCarOpt3         = "A la Colonia Acero"
    static let tHistTorpedoCarExplanation = "El hierro líquido se vertía en carros torpedo para ser convertido en acero en la planta de aceración."
    static let tHistFerrocarrilKmsText        = "¿Cuántos kilómetros de vía férrea había en México cuando Porfirio Díaz renunció en 1911?"
    static let tHistFerrocarrilKmsOpt0         = "600 km"
    static let tHistFerrocarrilKmsOpt1         = "5,000 km"
    static let tHistFerrocarrilKmsOpt2         = "12,000 km"
    static let tHistFerrocarrilKmsOpt3         = "24,000 km"
    static let tHistFerrocarrilKmsExplanation = "La red ferroviaria creció de 600 km en 1876 a unos 24,000 km en 1911."
    static let tHistPapeWifeText        = "¿Quién fue la presidenta del patronato del Hospital Infantil en Monclova?"
    static let tHistPapeWifeOpt0         = "Eva Sámano"
    static let tHistPapeWifeOpt1         = "Suzanne 'Lou' Pape"
    static let tHistPapeWifeOpt2         = "María del Roble"
    static let tHistPapeWifeOpt3         = "Isabel Morales"
    static let tHistPapeWifeExplanation = "Suzanne 'Lou' Pape, esposa del gerente de AHMSA, presidía el patronato del hospital."
    static let tHistHylsaPueblaText        = "¿En qué otra ciudad, además de Monterrey, se instaló una planta de HYLSA mencionada en los textos?"
    static let tHistHylsaPueblaOpt0         = "Saltillo"
    static let tHistHylsaPueblaOpt1         = "Puebla"
    static let tHistHylsaPueblaOpt2         = "Veracruz"
    static let tHistHylsaPueblaOpt3         = "Guadalajara"
    static let tHistHylsaPueblaExplanation = "Los textos mencionan personal en el cuarto de control de la planta de HYLSA en Puebla."
    static let tHistMonterreyIndustrialOutputText        = "¿Qué porcentaje de la producción industrial de México generaba Monterrey a principios del siglo XX?"
    static let tHistMonterreyIndustrialOutputOpt0         = "5%"
    static let tHistMonterreyIndustrialOutputOpt1         = "15%"
    static let tHistMonterreyIndustrialOutputOpt2         = "25%"
    static let tHistMonterreyIndustrialOutputOpt3         = "40%"
    static let tHistMonterreyIndustrialOutputExplanation = "A pesar de ser pequeña comparada con CDMX, Monterrey ya generaba casi el 15% de la producción industrial nacional."
    static let tHistCatalanForgeText        = "¿Qué tipo de horno fue reemplazado por el Alto Horno a finales del siglo XIX?"
    static let tHistCatalanForgeOpt0         = "Horno eléctrico"
    static let tHistCatalanForgeOpt1         = "Forja Catalana"
    static let tHistCatalanForgeOpt2         = "Horno Solar"
    static let tHistCatalanForgeOpt3         = "Crisol de barro"
    static let tHistCatalanForgeExplanation = "El Alto Horno revolucionó la industria al ser 5 veces más productivo que el antiguo horno catalán."
    static let tHistGoldenEraProductsText        = "¿Qué producto de la vida moderna NO se menciona como impulsor de la demanda de acero en los años 40?"
    static let tHistGoldenEraProductsOpt0         = "Automóviles"
    static let tHistGoldenEraProductsOpt1         = "Refrigeradores"
    static let tHistGoldenEraProductsOpt2         = "Estufas"
    static let tHistGoldenEraProductsOpt3         = "Computadoras"
    static let tHistGoldenEraProductsExplanation = "Se mencionan casas, autos, refrigeradores y estufas, pero no computadoras en esa época."
    static let tHistRevolucionImpactText        = "¿Qué tropas acamparon en la planta de Fundidora in 1915?"
    static let tHistRevolucionImpactOpt0         = "Zapatistas"
    static let tHistRevolucionImpactOpt1         = "Villistas"
    static let tHistRevolucionImpactOpt2         = "Carrancistas"
    static let tHistRevolucionImpactOpt3         = "Federales"
    static let tHistRevolucionImpactExplanation = "Las tropas de Francisco Villa acamparon en la planta durante uno de los episodios de la Revolución."
    static let tHistSafetyEquipmentText        = "¿En qué década se incorporó formalmente el departamento de Ingeniería Industrial para mejorar la seguridad?"
    static let tHistSafetyEquipmentOpt0         = "1920"
    static let tHistSafetyEquipmentOpt1         = "1940"
    static let tHistSafetyEquipmentOpt2         = "1965"
    static let tHistSafetyEquipmentOpt3         = "1986"
    static let tHistSafetyEquipmentExplanation = "El departamento de Ingeniería Industrial se creó alrededor de 1965 para implementar medidas de seguridad formales."
    static let tHistAltoHorno3TempText        = "¿A qué temperatura máxima funde el mineral de hierro en el Horno 3?"
    static let tHistAltoHorno3TempOpt0         = "500°C"
    static let tHistAltoHorno3TempOpt1         = "1000°C"
    static let tHistAltoHorno3TempOpt2         = "1500°C"
    static let tHistAltoHorno3TempOpt3         = "2000°C"
    static let tHistAltoHorno3TempExplanation = "El interior del Horno 3 alcanza temperaturas cercanas a los 1500°C para poder fundir el mineral de hierro."
    static let tHistAltoHorno3AlturaText        = "¿Cuál es la altura aproximada de la estructura del Horno 3?"
    static let tHistAltoHorno3AlturaOpt0         = "30 metros"
    static let tHistAltoHorno3AlturaOpt1         = "50 metros"
    static let tHistAltoHorno3AlturaOpt2         = "70 metros"
    static let tHistAltoHorno3AlturaOpt3         = "100 metros"
    static let tHistAltoHorno3AlturaExplanation = "La estructura completa alcanza alrededor de 70 metros de altura, dominando el paisaje del parque."
    static let tHistPatrimonioIndustrialText        = "¿En qué año el Horno 3 fue declarado Monumento Histórico y Patrimonio Industrial de México?"
    static let tHistPatrimonioIndustrialOpt0         = "1995"
    static let tHistPatrimonioIndustrialOpt1         = "2000"
    static let tHistPatrimonioIndustrialOpt2         = "2007"
    static let tHistPatrimonioIndustrialOpt3         = "2015"
    static let tHistPatrimonioIndustrialExplanation = "En 2007, tras su rescate y restauración como museo, fue reconocido como patrimonio por su valor histórico."
    static let tHistIngredienteAceroText        = "¿Qué elementos son clave para la producción del arrabio en el alto horno?"
    static let tHistIngredienteAceroOpt0         = "Cobre, Zinc y Oro"
    static let tHistIngredienteAceroOpt1         = "Mineral de Hierro, Coque y Piedra Caliza"
    static let tHistIngredienteAceroOpt2         = "Aluminio, Carbón y Azufre"
    static let tHistIngredienteAceroOpt3         = "Solo hierro puro"
    static let tHistIngredienteAceroExplanation = "La mezcla de mineral de hierro, carbón coque (combustible) y piedra caliza (fundente) es esencial para la fundición."
    static let tHistPicoProduccionText        = "¿Cuántas toneladas de arrabio producía el Horno 3 por día en su época de mayor capacidad?"
    static let tHistPicoProduccionOpt0         = "500 a 1000 toneladas"
    static let tHistPicoProduccionOpt1         = "1500 a 2000 toneladas"
    static let tHistPicoProduccionOpt2         = "3000 a 4000 toneladas"
    static let tHistPicoProduccionOpt3         = "Más de 5000 toneladas"
    static let tHistPicoProduccionExplanation = "El Horno 3 lograba producciones diarias de entre 1,500 y 2,000 toneladas de arrabio."

    // ── General Demo Questions ────────────────────────────────────────────────
    static let tGeneralDemo1Text        = "¿Cuál de estos es un color primario?"
    static let tGeneralDemo1Opt0         = "Verde"
    static let tGeneralDemo1Opt1         = "Morado"
    static let tGeneralDemo1Opt2         = "Rojo"
    static let tGeneralDemo1Opt3         = "Rosa"
    static let tGeneralDemo1Explanation = "Rojo, azul y amarillo suelen considerarse colores primarios en teoría básica del color."
    static let tGeneralDemo2Text        = "¿Qué planeta es conocido como el planeta rojo?"
    static let tGeneralDemo2Opt0         = "Venus"
    static let tGeneralDemo2Opt1         = "Marte"
    static let tGeneralDemo2Opt2         = "Saturno"
    static let tGeneralDemo2Opt3         = "Mercurio"
    static let tGeneralDemo2Explanation = "Marte recibe ese apodo por el color rojizo de su superficie."
    static let tGeneralDemo3Text        = "¿Cuántos minutos tiene una hora?"
    static let tGeneralDemo3Opt0         = "45"
    static let tGeneralDemo3Opt1         = "50"
    static let tGeneralDemo3Opt2         = "60"
    static let tGeneralDemo3Opt3         = "100"
    static let tGeneralDemo3Explanation = "Una hora siempre equivale a 60 minutos."
    static let tGeneralDemo4Text        = "¿Qué animal es el más grande del planeta?"
    static let tGeneralDemo4Opt0         = "Elefante"
    static let tGeneralDemo4Opt1         = "Ballena azul"
    static let tGeneralDemo4Opt2         = "Jirafa"
    static let tGeneralDemo4Opt3         = "Hipopótamo"
    static let tGeneralDemo4Explanation = "La ballena azul es el animal más grande conocido."
    static let tGeneralDemo5Text        = "¿Qué instrumento se usa para medir la temperatura?"
    static let tGeneralDemo5Opt0         = "Barómetro"
    static let tGeneralDemo5Opt1         = "Termómetro"
    static let tGeneralDemo5Opt2         = "Microscopio"
    static let tGeneralDemo5Opt3         = "Compás"
    static let tGeneralDemo5Explanation = "El termómetro sirve para medir la temperatura."

    // ── Camera Missions ───────────────────────────────────────────────────────
    static let camTorpedoTitle       = "El Carro Torpedo"
    static let camTorpedoDescription = "Busca el gran contenedor alargado que transportaba el hierro líquido a mil grados."
    static let camHornoTitle       = "El Alto Horno No. 3"
    static let camHornoDescription = "Encuentra la estructura monumental que es el corazón de este museo."
    static let camTelefonoTitle       = "Comunicación Antigua"
    static let camTelefonoDescription = "Localiza el teléfono antiguo que usaban los ingenieros para coordinar la fundición."
    static let camTelevisionTitle       = "La Tele del Ayer"
    static let camTelevisionDescription = "Busca la televisión vintage que muestra los videos históricos de la Fundidora."
    static let camEstrellaTitle       = "La Estrella del Horno"
    static let camEstrellaDescription = "Encuentra el símbolo de la estrella que marca el inicio de tu recorrido."
    static let camMaquetaHornoTitle       = "Maqueta del Horno 3"
    static let camMaquetaHornoDescription = "Encuentra la maqueta que muestra la estructura del Horno 3."
    static let camObservadorTitle       = "El Observador"
    static let camObservadorDescription = "Busca el observador de la zona general."
    static let camBochoTitle       = "Bocho de Acero"
    static let camBochoDescription = "Encuentra el bocho exhibido en la zona del acero."
    static let camDinamitaTitle       = "Dinamita"
    static let camDinamitaDescription = "Localiza la dinamita de la galería del acero."
    static let camGruaTitle       = "Grúa"
    static let camGruaDescription = "Encuentra la grúa usada para mover materiales pesados."
    static let camPlanchonesTitle       = "Planchones"
    static let camPlanchonesDescription = "Busca los planchones de acero de la exhibición."
    static let camCucharonTitle       = "Cucharón"
    static let camCucharonDescription = "Localiza el cucharón usado para transportar metal fundido."
    static let camExtintorTitle       = "Extintor"
    static let camExtintorDescription = "Encuentra el extintor histórico de seguridad industrial."
    static let camCamionetaTitle       = "Camioneta"
    static let camCamionetaDescription = "Busca la camioneta histórica dentro del recorrido."
    static let camMaquinaEscribirTitle       = "Máquina de Escribir"
    static let camMaquinaEscribirDescription = "Localiza la máquina de escribir de la galería histórica."

    // ── Camera Challenge Definitions ──────────────────────────────────────────
    static let chalDefEstrellaTitle    = "Encuentra la Estrella"
    static let chalDefEstrellaSubtitle = "Escanea la estrella de la zona general"
    static let chalDefTorpedoTitle    = "Carro Torpedo"
    static let chalDefTorpedoSubtitle = "Localiza el transporte de hierro líquido"
    static let chalDefHornoTitle    = "El Gigante: Alto Horno"
    static let chalDefHornoSubtitle = "Captura la estructura principal"
    static let chalDefTelefonoTitle    = "Comunicación Antigua"
    static let chalDefTelefonoSubtitle = "Localiza el teléfono de los ingenieros"
    static let chalDefTelevisionTitle    = "La Tele del Ayer"
    static let chalDefTelevisionSubtitle = "Busca la televisión vintage"

    // ── Attraction count ──────────────────────────────────────────────────────
    static let attractionsCount    = "%lld atracciones"

    // ── ChallengesView hardcoded strings ──────────────────────────────────────
    static let challengesDiscover        = "Descubre el museo de una mejor manera"
    static let challengesCompleted       = "Completados"
    static let challengesZones           = "Zonas"
    static let challengesProgress        = "Progreso"
    static let challengesTriviaNew       = "Nueva Trivia"
    static let challengesTriviaRandom    = "Preguntas aleatorias"
    static let challengesTrivia          = "Trivia"
    static let challengesTriviaStyle     = "Estilo juego"
    static let challengesCamera          = "Cámara"
    static let challengesCameraDesc      = "Misiones visuales"
    static let challengesCameraMissions  = "Misiones con cámara"
    static let challengesTriviaRemainingFmt = "%lld preguntas disponibles"
    static let challengesDynamic         = "Interacciones dinámicas"
    static let challengesXPPerChallenge  = "XP por reto"
    static let challengesRankProgress    = "Progreso de Rango"
    static let challengesBronzeLabel     = "Bronce"
    static let challengesGoldLabel       = "Oro"
    static let challengesClaimXP         = "Reclamar XP"
    static let challengesLoading         = "Cargando preguntas..."
    static let challengesLoadingDesc     = "Prepárate para demostrar lo que sabes sobre esta zona."
    static let challengesCameraLabel     = "Cámara"
    static let challengesMissionFound    = "Misión Detectada"
    static let challengesActivateCamera  = "Activa tu cámara"
    static let challengesCameraChoiceHint = "Activa tu cámara para tomar una foto o abre tu biblioteca para subir una imagen."
    static let challengesOpenCamera      = "Tomar foto"
    static let challengesOpenLibrary     = "Abrir biblioteca"
    static let challengesAnalyzing       = "Analizando imagen..."
    static let challengesSuccess         = "¡Excelente!"
    static let challengesNotTarget       = "No es el objetivo"
    static let challengesSuccessMsg      = "Has identificado correctamente el objeto."
    static let challengesFailMsg         = "El objeto detectado no coincide con tu misión. ¡Sigue buscando!"
    static let challengesRetryBtn        = "Reintentar"
    static let challengesClaimXPFmt      = "Reclamar %lld XP"
    static let challengesBack            = "Volver"
    // ── Map Floor & Node Names ──────────────────────────────────────────────
    static let mapNoRoutes              = "Sin rutas"
    static let mapNoDestinations        = "Sin destinos"
    static let mapUnknown               = "Desconocido"
    static let mapUserDummy             = "Usuario"
    static let mapFloorLevel            = "Nivel"
    static let mapNodeUsuarioDummy                           = "Usuario dummy"
    static let mapNodeEntradaPrincipal                       = "Entrada principal"
    static let mapNodeLobby                                  = "Lobby"
    static let mapNodeBanos                                  = "Banos"
    static let mapNodeTiendaDeSouvenirs                      = "Tienda de souvenirs"
    static let mapNodeTaquillaEInformacion                   = "Taquilla e informacion"
    static let mapNodeSnackH3                                = "Snack h3"
    static let mapNodeElevadorInclinado                      = "Elevador inclinado"
    static let mapNodePatioDeDemostraciones                  = "Patio de demostraciones"
    static let mapNodePaseoPorLasEstufas                     = "Paseo por las Estufas"
    static let mapNodeGaleriaDelAcero                        = "Galeria del Acero"
    static let mapNodeGaleriaDeLaHistoria                    = "Galeria de la Historia"
    static let mapNodeHornoAlto                              = "Horno Alto"
    static let mapNodeExplanadaEstufas                       = "Explanada Estufas"
    static let mapNodeBanosAccesibles                        = "Banos accesibles"
    static let mapNodeAccesoAccesibleLobby                   = "Acceso accesible lobby"
    static let mapNodeTerraza                                = "Terraza"
    static let mapNodeShowHorno                              = "Show Horno"
    static let mapNodeHornoAltoNivel2                        = "Horno Alto nivel 2"
    static let mapNodeH3PlanetaTierra                        = "h3 Planeta Tierra"
    static let mapNodePaseoPorLasEstufasNivel2               = "Paseo por las Estufas nivel 2"
    static let mapNodeRestauranteElLingote                   = "Restaurante El Lingote"
    static let mapNodeSalidaAccesoDerechoNivel2              = "Salida / acceso derecho nivel 2"
    static let mapNodeElevadorInclinadoNivel2                = "Elevador inclinado nivel 2"
    static let mapNodeBanosNivel2                            = "Baños nivel 2"
    static let mapNodeAccesoAccesibleDerechoNivel2           = "Acceso accesible derecho nivel 2"
    static let mapNodeBocaDelHornoAlto                       = "Boca del Horno Alto"
    static let mapNodeMiradorCentral                         = "Mirador central"
    static let mapNodeMiradorEste                            = "Mirador este"
    static let mapNodeMiradorSur                             = "Mirador sur"
    static let mapNodeSalidaExtremoNivel3                    = "Salida extremo nivel 3"
    static let mapNodeElevadorInclinadoNivel3                = "Elevador inclinado nivel 3"
    static let mapNodeAccesoAccesibleMirador                 = "Acceso accesible mirador"
    static let mapNodeEscalerasNivel1                        = "Escaleras nivel 1"
    static let mapNodeEscalerasNivel2                        = "Escaleras nivel 2"
    static let mapNodeEscalerasNivel3                        = "Escaleras nivel 3"
    static let mapNodeDesconocido                            = "Desconocido"

    // ── Assistance ────────────────────────────────────────────────────────────
    static let assistanceTitle              = "Asistencia"
    static let assistanceSubtitle           = "Reporta una situación y prepara la atención del personal."
    static let assistanceIncidentType       = "Tipo de incidencia"
    static let assistanceNeeds              = "Apoyos necesarios"
    static let assistanceAccessibility      = "Necesito apoyo de accesibilidad"
    static let assistanceTranslation        = "Necesito apoyo de traducción"
    static let assistanceLocationTitle      = "Ubicación actual"
    static let assistanceLocationHint       = "Usaremos la sección abierta como referencia inicial."
    static let assistanceDetails            = "Detalles"
    static let assistanceDetailsPlaceholder = "Describe lo que está pasando, cuántas personas necesitan apoyo y cualquier detalle importante."
    static let assistanceSubmit             = "Solicitar ayuda"
    static let assistanceSubmitEmergency    = "Enviar alerta urgente"
    static let assistanceSubmittedTitle     = "Solicitud preparada"
    static let assistanceSubmittedDescription = "El reporte quedó listo dentro de la app para conectarlo al backend de asistencia."
    static let assistanceFolio              = "Folio"
    static let assistanceDraftNote          = "Cuando conectemos el endpoint, este panel podrá enviar `assistance_reports` con ubicación, prioridad y tipo de incidente."
    static let assistanceEmergency          = "Urgente"
    static let assistanceStandard           = "Normal"

    // ── Assistance Incident Types & Descriptions ───────────────────────────────
    static let assistanceLostChild                           = "Niño perdido"
    static let assistanceMedicalEmergency                    = "Emergencia médica"
    static let assistanceSecurityIssue                       = "Incidente de seguridad"
    static let assistanceExhibitIssue                        = "Problema en exhibición"
    static let assistanceAccessibilityLabel                  = "Ayuda de accesibilidad"
    static let assistanceAccessibilityHelp                   = "Necesito apoyo de accesibilidad"
    static let assistanceTranslationHelp                     = "Necesito apoyo de traducción"
    static let assistanceGeneralHelp                         = "Ayuda general"
    static let assistanceDescLostChild                       = "Para localizar a un menor dentro del museo."
    static let assistanceDescMedical                         = "Accidente o situación médica que requiere atención inmediata."
    static let assistanceDescSecurity                        = "Riesgo, conducta sospechosa o situación insegura."
    static let assistanceDescExhibit                         = "Falla o daño detectado en una exhibición."
    static let assistanceDescAccessibility                   = "Apoyo de movilidad, elevador o acompañamiento accesible."
    static let assistanceDescGeneral                         = "Orientación o apoyo general durante la visita."
    static let assistanceLoadingScreen                       = "Pantalla de carga"
    static let assistanceAccess                              = "Acceso"
    // ── L.all — ÚNICO array, sin duplicados ──────────────────────
    static let all: [String] = [
        appSubtitle, loginTabSignin, loginTabRegister, loginFieldName, loginFieldEmail,
        loginFieldPassword, loginCtaSignin, loginCtaRegister, loginDemoHint,
        loginErrName, loginErrEmail, loginErrPassword, loginErrFields, loginErrWrongPwd,
        loginSubtitleRegister, loginSubtitleSignin, loginFieldLastName,
        loginAlreadyHaveAccount, loginNoAccount,
        tabHome, tabChallenges, tabMap, tabTranslation, tabProfile,
        homeVisitor, homeSuggestionsTitle, homeExploreTitle,
        homeExploreAssistant, homeExploreAssistantDesc,
        homeExploreChallenges, homeExploreChallengesDesc,
        homeExploreMap, homeExploreMapDesc,
        homeExploreSensory, homeExploreSensoryDesc,
        homeProgressTitle, homeProgressDone, homeProgressEmpty,
        homeProgressStart, homeProgressContinue,
        museumOpen, museumClosed, museumClosedTitle, museumSchedule,
        attractionSoon, attractionAllDay, attractionShowIn,
        statsAnswered, statsCorrect, statsIncorrect,
        challengesTitle, challengesSubtitle, challengesOf, challengesQuestions,
        challengesReset, challengesComplete, challengesScore, challengesRetry,
        challengeZoneGeneral, challengeZoneGeneralSubtitle,
        challengeZoneHistory, challengeZoneHistorySubtitle,
        challengeZoneSteelGallery, challengeZoneSteelGallerySubtitle,
        challengeGeneralTitle, challengeGeneralSubtitle,
        challengeHistoryTitle, challengeHistorySubtitle,
        challengeSteelGalleryTitle, challengeSteelGallerySubtitle,
        challengesCheck, challengesContinue, challengesSeeResults, challengesQuestionLabel,
        mapMuseumName, mapAddress, mapAttractions, mapDirections,
        mapScanTitle, mapQrDetected, mapCurrentPosition, mapAlignQr,
        mapPendingLocation, mapRoutes, mapQuickDestination,
        mapMuseumIndoor, mapEndpointFallback, mapLoadingDetails,
        mapSettings, mapWheelchairMode, mapGoHere,
        mapIntroTitle, mapIntroMessage, mapIntroButton,
        mapCameraUnavailable, mapCameraInputError, mapNodeDetailsError,
        mapRouteGeneral, mapRouteSculptures, mapRoutePaintings,
        mapNodeEntrance, mapNodeCentral, mapNodeBathrooms,
        mapNodeSnacks, mapNodeSouvenirs, mapNodeInfo,
        mapNodeRestArea, mapNodeEmergencyExitNorth, mapNodeEmergencyExitSouth,
        mapNodeRampNorth, mapNodeRampSouth, mapNodeElevator, mapAttrAllDay,
        translationTitle, translationSubtitle,
        translationSubtitlesTitle, translationSubtitlesSubtitle,
        translationVisualTitle, translationVisualSubtitle,
        translationConvTitle, translationConvSubtitle,
        translationBack, translationLive, translationPlaceholder,
        translationMicDenied, translationCameraActive, translationCameraHint,
        translationVisualResult, translationVisualNote, translationMicPress,
        translationMicListening, translationSpanish, translationDetecting,
        assistantTitle, assistantIdleHint, assistantEmptyHint, assistantError,
        assistantNetworkError, assistantStateIdle, assistantStateActive,
        assistantStateListening, assistantStateReady, assistantStateProcessing,
        assistantStateWaiting, assistantStateResponding,
        greetingMorning, greetingAfternoon, greetingEvening,
        attrHistoryName, attrShowName, attrPaseoName,
        attrSteelName, attrPlanetName, attrChainName,
        attrHistoryDesc, attrShowDesc, attrPaseoDesc,
        attrSteelDesc, attrPlanetDesc, attrChainDesc,
        scheduleAllDay, scheduleHourly, scheduleAsk, scheduleClimate, scheduleAvailability,
        groupGalleries, groupPaseo, groupShows,
        profileTitle, profileOptionalInfo, profileFirstName, profileLastName,
        profileEmail, profileCountry, profileCity, profileAgeRange, profileYears,
        profileMyInterests, profileChangePassword, profileCurrentPassword,
        profileNewPassword, profileUpdatePassword, profilePasswordUpdated,
        profilePasswordMinChars, profilePasswordWrong,
        profileLogout, profileLogoutConfirm, profileLogoutMessage,
        profileDeleteAccount, profileDeleteConfirm, profileDeleteMessage, profileDeleteCancel,
        profileLoginInfo, profileInterestsCount, profileSave, profileSaved,
        profileMedals, profileMetrics, profileSummaryTitle, profileSummaryDesc,
        badgeSectionTitle, badgeSectionHint, badgeLocked, badgeLockedHint,
        badgeLevelGold, badgeLevelSilver, badgeLevelBronze,
        badgeLabelPioneer, badgeLabelVoice, badgeLabelMaster, badgeLabelSpecial,
        badgeZoneGeneral, badgeZoneHistory, badgeZoneSteel,
        badgeNamePioneer, badgeNameVoice, badgeNameMaster,
        profileSummaryGenerate, profileSummaryChallenges, profileSummaryCorrect,
        profileSummaryAccuracy, profilePickAvatar, profileNoAvatars,
        medalFirstStep, medalFirstStepDesc, medalStreak, medalStreakDesc,
        medalComplete, medalCompleteDesc, medalPrecision, medalPrecisionDesc,
        medalPerfect, medalPerfectDesc, medalExplorer, medalExplorerDesc,
        q0, q1, q2, q3, q4, q5, q6, q7, q8, q9,
        q0a, q0b, q0c, q1a, q1b, q1c, q2a, q2b, q2c,
        q3a, q3b, q3c, q4a, q4b, q4c, q5a, q5b, q5c,
        q6a, q6b, q6c, q7a, q7b, q7c, q8a, q8b, q8c,
        q9a, q9b, q9c,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        convTapToSpeak, convTapMic, visualLive, visualNoText,
        visualScanning, subtitlesNoSpeech,
        sensoryTitle, sensorySubtitle, sensorySimulatorBanner,
        sensorySuggestions, sensoryPlaceholder, sensoryClear,
        sensoryIntensity, sensoryTip, sensoryErrorMsg,
        sensoryQ1, sensoryQ2, sensoryQ3, sensoryQ4,
        sensoryLevelTranquila, sensoryLevelModerada, sensoryLevelIntensa,
        wrappedTitle, wrappedNext, wrappedClose,
        wrappedWelcomeTitle, wrappedWelcomeValue, wrappedWelcomeSubtitle,
        wrappedChallengesTitle, wrappedChallengesAllDone, wrappedChallengesRemaining,
        wrappedAccuracyTitle, wrappedAccuracySub90, wrappedAccuracySub70,
        wrappedAccuracySub50, wrappedAccuracySubLow, wrappedAccuracySubZero,
        wrappedMedalsTitle, wrappedMedalsAllDone, wrappedMedalsRemaining,
        wrappedNicknameTitle,
        wrappedClosingTitle, wrappedClosingValue, wrappedClosingSubtitle,
        nickMaestroName, nickMaestroDesc,
        nickColeccionistaName, nickColeccionistaDesc,
        nickExploradorName, nickExploradorDesc,
        nickPerspicazName, nickPerspicazDesc,
        nickAprendizName, nickAprendizDesc,
        nickCuriosoName, nickCuriosoDesc,
        tHistSidermex1Text, tHistSidermex1Opt0, tHistSidermex1Opt1, tHistSidermex1Opt2, tHistSidermex1Opt3,
        tHistSidermex1Explanation,
        tHistLema70sText, tHistLema70sOpt0, tHistLema70sOpt1, tHistLema70sOpt2, tHistLema70sOpt3,
        tHistLema70sExplanation,
        tHistPrimerEdificioText, tHistPrimerEdificioOpt0, tHistPrimerEdificioOpt1, tHistPrimerEdificioOpt2, tHistPrimerEdificioOpt3,
        tHistPrimerEdificioExplanation,
        tHistPorfirioDiazText, tHistPorfirioDiazOpt0, tHistPorfirioDiazOpt1, tHistPorfirioDiazOpt2, tHistPorfirioDiazOpt3,
        tHistPorfirioDiazExplanation,
        tHistHuelgas7080Text, tHistHuelgas7080Opt0, tHistHuelgas7080Opt1, tHistHuelgas7080Opt2, tHistHuelgas7080Opt3,
        tHistHuelgas7080Explanation,
        tHistHylTecnologiaText, tHistHylTecnologiaOpt0, tHistHylTecnologiaOpt1, tHistHylTecnologiaOpt2, tHistHylTecnologiaOpt3,
        tHistHylTecnologiaExplanation,
        tHistFundidoraCierreText, tHistFundidoraCierreOpt0, tHistFundidoraCierreOpt1, tHistFundidoraCierreOpt2, tHistFundidoraCierreOpt3,
        tHistFundidoraCierreExplanation,
        tHistMonterreyUbicacionText, tHistMonterreyUbicacionOpt0, tHistMonterreyUbicacionOpt1, tHistMonterreyUbicacionOpt2, tHistMonterreyUbicacionOpt3,
        tHistMonterreyUbicacionExplanation,
        tHistSeguridadPepeGalloText, tHistSeguridadPepeGalloOpt0, tHistSeguridadPepeGalloOpt1, tHistSeguridadPepeGalloOpt2, tHistSeguridadPepeGalloOpt3,
        tHistSeguridadPepeGalloExplanation,
        tHistPapeAhmsaText, tHistPapeAhmsaOpt0, tHistPapeAhmsaOpt1, tHistPapeAhmsaOpt2, tHistPapeAhmsaOpt3,
        tHistPapeAhmsaExplanation,
        tHistCrisis7682Text, tHistCrisis7682Opt0, tHistCrisis7682Opt1, tHistCrisis7682Opt2, tHistCrisis7682Opt3,
        tHistCrisis7682Explanation,
        tHistFamiliaAceroText, tHistFamiliaAceroOpt0, tHistFamiliaAceroOpt1, tHistFamiliaAceroOpt2, tHistFamiliaAceroOpt3,
        tHistFamiliaAceroExplanation,
        tHistConstitucion1917Text, tHistConstitucion1917Opt0, tHistConstitucion1917Opt1, tHistConstitucion1917Opt2, tHistConstitucion1917Opt3,
        tHistConstitucion1917Explanation,
        tHistColonialProhibicionText, tHistColonialProhibicionOpt0, tHistColonialProhibicionOpt1, tHistColonialProhibicionOpt2, tHistColonialProhibicionOpt3,
        tHistColonialProhibicionExplanation,
        tHistSegundaGuerraText, tHistSegundaGuerraOpt0, tHistSegundaGuerraOpt1, tHistSegundaGuerraOpt2, tHistSegundaGuerraOpt3,
        tHistSegundaGuerraExplanation,
        tHistDurangoBlockadeText, tHistDurangoBlockadeOpt0, tHistDurangoBlockadeOpt1, tHistDurangoBlockadeOpt2, tHistDurangoBlockadeOpt3,
        tHistDurangoBlockadeExplanation,
        tHistObregonSchoolsText, tHistObregonSchoolsOpt0, tHistObregonSchoolsOpt1, tHistObregonSchoolsOpt2, tHistObregonSchoolsOpt3,
        tHistObregonSchoolsExplanation,
        tHistDeaceroOriginsText, tHistDeaceroOriginsOpt0, tHistDeaceroOriginsOpt1, tHistDeaceroOriginsOpt2, tHistDeaceroOriginsOpt3,
        tHistDeaceroOriginsExplanation,
        tHistFirstMexicanBossText, tHistFirstMexicanBossOpt0, tHistFirstMexicanBossOpt1, tHistFirstMexicanBossOpt2, tHistFirstMexicanBossOpt3,
        tHistFirstMexicanBossExplanation,
        tHistColoniaAceroText, tHistColoniaAceroOpt0, tHistColoniaAceroOpt1, tHistColoniaAceroOpt2, tHistColoniaAceroOpt3,
        tHistColoniaAceroExplanation,
        tHistAguadorStoryText, tHistAguadorStoryOpt0, tHistAguadorStoryOpt1, tHistAguadorStoryOpt2, tHistAguadorStoryOpt3,
        tHistAguadorStoryExplanation,
        tHistTorpedoCarText, tHistTorpedoCarOpt0, tHistTorpedoCarOpt1, tHistTorpedoCarOpt2, tHistTorpedoCarOpt3,
        tHistTorpedoCarExplanation,
        tHistFerrocarrilKmsText, tHistFerrocarrilKmsOpt0, tHistFerrocarrilKmsOpt1, tHistFerrocarrilKmsOpt2, tHistFerrocarrilKmsOpt3,
        tHistFerrocarrilKmsExplanation,
        tHistPapeWifeText, tHistPapeWifeOpt0, tHistPapeWifeOpt1, tHistPapeWifeOpt2, tHistPapeWifeOpt3,
        tHistPapeWifeExplanation,
        tHistHylsaPueblaText, tHistHylsaPueblaOpt0, tHistHylsaPueblaOpt1, tHistHylsaPueblaOpt2, tHistHylsaPueblaOpt3,
        tHistHylsaPueblaExplanation,
        tHistMonterreyIndustrialOutputText, tHistMonterreyIndustrialOutputOpt0, tHistMonterreyIndustrialOutputOpt1, tHistMonterreyIndustrialOutputOpt2, tHistMonterreyIndustrialOutputOpt3,
        tHistMonterreyIndustrialOutputExplanation,
        tHistCatalanForgeText, tHistCatalanForgeOpt0, tHistCatalanForgeOpt1, tHistCatalanForgeOpt2, tHistCatalanForgeOpt3,
        tHistCatalanForgeExplanation,
        tHistGoldenEraProductsText, tHistGoldenEraProductsOpt0, tHistGoldenEraProductsOpt1, tHistGoldenEraProductsOpt2, tHistGoldenEraProductsOpt3,
        tHistGoldenEraProductsExplanation,
        tHistRevolucionImpactText, tHistRevolucionImpactOpt0, tHistRevolucionImpactOpt1, tHistRevolucionImpactOpt2, tHistRevolucionImpactOpt3,
        tHistRevolucionImpactExplanation,
        tHistSafetyEquipmentText, tHistSafetyEquipmentOpt0, tHistSafetyEquipmentOpt1, tHistSafetyEquipmentOpt2, tHistSafetyEquipmentOpt3,
        tHistSafetyEquipmentExplanation,
        tHistAltoHorno3TempText, tHistAltoHorno3TempOpt0, tHistAltoHorno3TempOpt1, tHistAltoHorno3TempOpt2, tHistAltoHorno3TempOpt3,
        tHistAltoHorno3TempExplanation,
        tHistAltoHorno3AlturaText, tHistAltoHorno3AlturaOpt0, tHistAltoHorno3AlturaOpt1, tHistAltoHorno3AlturaOpt2, tHistAltoHorno3AlturaOpt3,
        tHistAltoHorno3AlturaExplanation,
        tHistPatrimonioIndustrialText, tHistPatrimonioIndustrialOpt0, tHistPatrimonioIndustrialOpt1, tHistPatrimonioIndustrialOpt2, tHistPatrimonioIndustrialOpt3,
        tHistPatrimonioIndustrialExplanation,
        tHistIngredienteAceroText, tHistIngredienteAceroOpt0, tHistIngredienteAceroOpt1, tHistIngredienteAceroOpt2, tHistIngredienteAceroOpt3,
        tHistIngredienteAceroExplanation,
        tHistPicoProduccionText, tHistPicoProduccionOpt0, tHistPicoProduccionOpt1, tHistPicoProduccionOpt2, tHistPicoProduccionOpt3,
        tHistPicoProduccionExplanation,
        tGeneralDemo1Text, tGeneralDemo1Opt0, tGeneralDemo1Opt1, tGeneralDemo1Opt2, tGeneralDemo1Opt3, tGeneralDemo1Explanation,
        tGeneralDemo2Text, tGeneralDemo2Opt0, tGeneralDemo2Opt1, tGeneralDemo2Opt2, tGeneralDemo2Opt3, tGeneralDemo2Explanation,
        tGeneralDemo3Text, tGeneralDemo3Opt0, tGeneralDemo3Opt1, tGeneralDemo3Opt2, tGeneralDemo3Opt3, tGeneralDemo3Explanation,
        tGeneralDemo4Text, tGeneralDemo4Opt0, tGeneralDemo4Opt1, tGeneralDemo4Opt2, tGeneralDemo4Opt3, tGeneralDemo4Explanation,
        tGeneralDemo5Text, tGeneralDemo5Opt0, tGeneralDemo5Opt1, tGeneralDemo5Opt2, tGeneralDemo5Opt3, tGeneralDemo5Explanation,
        camTorpedoTitle, camTorpedoDescription,
        camHornoTitle, camHornoDescription,
        camTelefonoTitle, camTelefonoDescription,
        camTelevisionTitle, camTelevisionDescription,
        camEstrellaTitle, camEstrellaDescription,
        camMaquetaHornoTitle, camMaquetaHornoDescription,
        camObservadorTitle, camObservadorDescription,
        camBochoTitle, camBochoDescription,
        camDinamitaTitle, camDinamitaDescription,
        camGruaTitle, camGruaDescription,
        camPlanchonesTitle, camPlanchonesDescription,
        camCucharonTitle, camCucharonDescription,
        camExtintorTitle, camExtintorDescription,
        camCamionetaTitle, camCamionetaDescription,
        camMaquinaEscribirTitle, camMaquinaEscribirDescription,
        chalDefEstrellaTitle, chalDefEstrellaSubtitle,
        chalDefTorpedoTitle, chalDefTorpedoSubtitle,
        chalDefHornoTitle, chalDefHornoSubtitle,
        chalDefTelefonoTitle, chalDefTelefonoSubtitle,
        chalDefTelevisionTitle, chalDefTelevisionSubtitle,
        attractionsCount,
        challengesDiscover, challengesCompleted, challengesZones, challengesProgress,
        challengesTriviaNew, challengesTriviaRandom, challengesTrivia, challengesTriviaStyle,
        challengesCamera, challengesCameraDesc, challengesCameraMissions, challengesTriviaRemainingFmt,
        challengesDynamic, challengesXPPerChallenge,
        challengesRankProgress, challengesBronzeLabel, challengesGoldLabel, challengesClaimXP,
        challengesLoading, challengesLoadingDesc, challengesCameraLabel, challengesMissionFound,
        challengesActivateCamera, challengesCameraChoiceHint, challengesOpenCamera, challengesOpenLibrary,
        challengesAnalyzing, challengesSuccess, challengesNotTarget,
        challengesSuccessMsg, challengesFailMsg, challengesRetryBtn, challengesClaimXPFmt, challengesBack,
        mapNoRoutes, mapNoDestinations, mapUnknown, mapUserDummy, mapFloorLevel,
        mapNodeUsuarioDummy, mapNodeEntradaPrincipal, mapNodeLobby, mapNodeBanos, mapNodeTiendaDeSouvenirs,
        mapNodeTaquillaEInformacion, mapNodeSnackH3, mapNodeElevadorInclinado, mapNodePatioDeDemostraciones, mapNodePaseoPorLasEstufas,
        mapNodeGaleriaDelAcero, mapNodeGaleriaDeLaHistoria, mapNodeHornoAlto, mapNodeExplanadaEstufas, mapNodeBanosAccesibles,
        mapNodeAccesoAccesibleLobby, mapNodeTerraza, mapNodeShowHorno, mapNodeHornoAltoNivel2, mapNodeH3PlanetaTierra,
        mapNodePaseoPorLasEstufasNivel2, mapNodeRestauranteElLingote, mapNodeSalidaAccesoDerechoNivel2, mapNodeElevadorInclinadoNivel2, mapNodeBanosNivel2,
        mapNodeAccesoAccesibleDerechoNivel2, mapNodeBocaDelHornoAlto, mapNodeMiradorCentral, mapNodeMiradorEste, mapNodeMiradorSur,
        mapNodeSalidaExtremoNivel3, mapNodeElevadorInclinadoNivel3, mapNodeAccesoAccesibleMirador, mapNodeEscalerasNivel1, mapNodeEscalerasNivel2,
        mapNodeEscalerasNivel3, mapNodeDesconocido, assistanceTitle, assistanceSubtitle, assistanceIncidentType,
        assistanceNeeds, assistanceAccessibility, assistanceTranslation, assistanceLocationTitle, assistanceLocationHint,
        assistanceDetails, assistanceDetailsPlaceholder, assistanceSubmit, assistanceSubmitEmergency, assistanceSubmittedTitle,
        assistanceSubmittedDescription, assistanceFolio, assistanceDraftNote, assistanceEmergency, assistanceStandard,
        assistanceLostChild, assistanceMedicalEmergency, assistanceSecurityIssue, assistanceExhibitIssue, assistanceAccessibilityLabel,
        assistanceAccessibilityHelp, assistanceTranslationHelp, assistanceGeneralHelp, assistanceDescLostChild, assistanceDescMedical,
        assistanceDescSecurity, assistanceDescExhibit, assistanceDescAccessibility, assistanceDescGeneral, assistanceLoadingScreen,
        assistanceAccess
    ]
}

// ─────────────────────────────────────────────
// MARK: - LocalizationManager
// ─────────────────────────────────────────────
@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    @Published var t: [String: String] = [:]
    @Published var isReady: Bool = false
    @Published var isTranslating: Bool = false

    let deviceLanguage: String = {
        let preferred = Locale.preferredLanguages.first ?? "es"
        let code = preferred.components(separatedBy: "-").first ?? preferred
        return code.lowercased()
    }()

    var deviceLanguageName: String {
        Locale.current.localizedString(forLanguageCode: deviceLanguage)
            ?? deviceLanguage.uppercased()
    }

    var needsTranslation: Bool { !deviceLanguage.hasPrefix("es") }

    // ← versión v3: invalida el cache anterior que tenía el array duplicado
    private let cacheKey     = "h3_translations_v4"
    private let cacheLangKey = "h3_translations_lang_v4"

    private init() {
        L.all.forEach { t[$0] = $0 }
        guard needsTranslation else { isReady = true; return }

        if let cached = loadCache() {
            t = cached
            isReady = true
            Task { await performTranslation(showOverlay: false) }
        } else {
            Task { await performTranslation(showOverlay: true) }
        }
    }

    func performTranslation(showOverlay: Bool) async {
        if showOverlay { isTranslating = true }
        let sourceLang = Locale.Language(identifier: "es")
        let targetLang = Locale.Language(identifier: deviceLanguage)
        NotificationCenter.default.post(name: .h3StartTranslation,
            object: TranslationConfig(source: sourceLang, target: targetLang))
        NotificationCenter.default.post(name: .h3NeedSession,
            object: H3SessionRequest(sourceLang: "es", targetLang: deviceLanguage))
        if deviceLanguage != "es" {
            NotificationCenter.default.post(name: .h3NeedSession,
                object: H3SessionRequest(sourceLang: deviceLanguage, targetLang: "es"))
        }
    }

    func applyTranslations(_ results: [TranslationSession.Response]) {
        var newT = t
        for response in results {
            guard let idx = Int(response.clientIdentifier ?? ""),
                  idx < L.all.count else { continue }
            newT[L.all[idx]] = response.targetText
        }
        t = newT; isReady = true; isTranslating = false
        saveCache(newT)
    }

    func applyTranslationError() { isReady = true; isTranslating = false }

    func s(_ key: String) -> String { t[key] ?? key }

    private func saveCache(_ dict: [String: String]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data,           forKey: cacheKey)
            UserDefaults.standard.set(deviceLanguage, forKey: cacheLangKey)
        }
    }

    private func loadCache() -> [String: String]? {
        guard UserDefaults.standard.string(forKey: cacheLangKey) == deviceLanguage,
              let data = UserDefaults.standard.data(forKey: cacheKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict
    }
}

// MARK: - Notification glue
extension Notification.Name {
    static let h3StartTranslation = Notification.Name("h3StartTranslation")
}
struct TranslationConfig {
    let source: Locale.Language
    let target: Locale.Language
}

// ─────────────────────────────────────────────
// MARK: - TranslationSessionManager
// ─────────────────────────────────────────────
actor TranslationSessionManager {
    static let shared = TranslationSessionManager()
    private var sessions: [String: TranslationSession] = [:]
    private var pendingSessionSetup: [String: [(TranslationSession) async throws -> Void]] = [:]

    func registerSession(_ session: TranslationSession, for key: String) async {
        sessions[key] = session
        if let pending = pendingSessionSetup[key] {
            pendingSessionSetup.removeValue(forKey: key)
            for work in pending { try? await work(session) }
        }
    }

    func translate(text: String, from sourceLang: String, to targetLang: String) async -> String {
        let key = "\(sourceLang)-\(targetLang)"
        if let session = sessions[key] {
            let req = [TranslationSession.Request(sourceText: text, clientIdentifier: "0")]
            if let r = try? await session.translations(from: req).first { return r.targetText }
        }
        await MainActor.run {
            NotificationCenter.default.post(name: .h3NeedSession,
                object: H3SessionRequest(sourceLang: sourceLang, targetLang: targetLang))
        }
        try? await Task.sleep(nanoseconds: 800_000_000)
        if let session = sessions[key] {
            let req = [TranslationSession.Request(sourceText: text, clientIdentifier: "0")]
            if let r = try? await session.translations(from: req).first { return r.targetText }
        }
        return text
    }
}

// ─────────────────────────────────────────────
// MARK: - TranslationBridgeView
// ─────────────────────────────────────────────
struct TranslationBridgeView: View {
    @EnvironmentObject var lm: LocalizationManager
    @State private var batchConfig: TranslationSession.Configuration? = nil
    @State private var pairConfigs: [String: TranslationSession.Configuration] = [:]

    var body: some View {
        ZStack {
            Color.clear.frame(width: 0, height: 0)
                .translationTask(batchConfig) { session in
                    do {
                        let requests = L.all.enumerated().map {
                            TranslationSession.Request(sourceText: $1, clientIdentifier: "\($0)")
                        }
                        let responses = try await session.translations(from: requests)
                        await MainActor.run { lm.applyTranslations(responses) }
                    } catch {
                        await MainActor.run { lm.applyTranslationError() }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .h3StartTranslation)) { note in
                    guard let cfg = note.object as? TranslationConfig else { return }
                    batchConfig = TranslationSession.Configuration(source: cfg.source, target: cfg.target)
                }
            ForEach(Array(pairConfigs.keys), id: \.self) { key in
                if let cfg = pairConfigs[key] {
                    Color.clear.frame(width: 0, height: 0)
                        .translationTask(cfg) { session in
                            await TranslationSessionManager.shared.registerSession(session, for: key)
                        }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .h3NeedSession)) { note in
            guard let req = note.object as? H3SessionRequest else { return }
            let key = "\(req.sourceLang)-\(req.targetLang)"
            guard pairConfigs[key] == nil else { return }
            pairConfigs[key] = TranslationSession.Configuration(
                source: Locale.Language(identifier: req.sourceLang),
                target: Locale.Language(identifier: req.targetLang))
        }
    }
}

// MARK: - Notification types
extension Notification.Name {
    static let h3NeedSession = Notification.Name("h3NeedSession")
}
class H3SessionRequest {
    let sourceLang: String
    let targetLang: String
    init(sourceLang: String, targetLang: String) {
        self.sourceLang = sourceLang
        self.targetLang = targetLang
    }
}
