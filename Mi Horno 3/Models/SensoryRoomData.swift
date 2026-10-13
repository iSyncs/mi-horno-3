import Foundation

enum SensoryRoomData {

    static let rooms: [SensoryRoomInfo] = [

        SensoryRoomInfo(
            name: "Sala del Alto Horno",
            shortDescription: "Muestra el proceso histórico de fundición del acero",
            noiseLevel: .high,
            lightLevel: .low,
            crowdLevel: .medium,
            movementLevel: .low,
            estimatedMinutes: 15,
            hasStrongSmells: false,
            hasLoudMachinery: true,
            hasDimLighting: true,
            hasFlashingLights: false,
            preparationTips: "Hay grabaciones de maquinaria pesada. Considera usar audífonos de reducción de ruido.",
            firstImpression: "Entras a un espacio oscuro con iluminación dramática y sonidos de fábrica en loop."
        ),

        SensoryRoomInfo(
            name: "Galería de la Historia del Acero",
            shortDescription: "Exposición de paneles y objetos sobre la industria siderúrgica",
            noiseLevel: .low,
            lightLevel: .medium,
            crowdLevel: .low,
            movementLevel: .low,
            estimatedMinutes: 20,
            hasStrongSmells: false,
            hasLoudMachinery: false,
            hasDimLighting: false,
            hasFlashingLights: false,
            preparationTips: "Es una sala poco concurrida. Por lo general es un paseo tranquilo sin aglomeraciones. Ideal para empezar o descansar.",
            firstImpression: "Espacio tranquilo con poca gente y buena iluminación. Puedes recorrerla a tu propio ritmo."
        ),

        SensoryRoomInfo(
            name: "Zona del Recorrido Exterior",
            shortDescription: "Paseo guiado alrededor del horno industrial original con vistas desde altura",
            noiseLevel: .medium,
            lightLevel: .high,
            crowdLevel: .high,
            movementLevel: .medium,
            estimatedMinutes: 30,
            hasStrongSmells: false,
            hasLoudMachinery: false,
            hasDimLighting: false,
            hasFlashingLights: false,
            preparationTips: "Es el punto más visitado del museo. Hay alturas considerables, prepárate para eso. Puede haber grupos grandes de visitantes.",
            firstImpression: "Zona con mucha gente y vistas desde altura. Puede generar sensación de vértigo si eres sensible a las alturas."
        ),

        SensoryRoomInfo(
            name: "Sala de Proyección",
            shortDescription: "Documental audiovisual sobre la historia del museo",
            noiseLevel: .high,
            lightLevel: .low,
            crowdLevel: .medium,
            movementLevel: .low,
            estimatedMinutes: 12,
            hasStrongSmells: false,
            hasLoudMachinery: false,
            hasDimLighting: true,
            hasFlashingLights: true,
            preparationTips: "El video tiene volumen alto y momentos de oscuridad total. Puedes salir en cualquier momento.",
            firstImpression: "Sala completamente oscura al inicio. El sonido es envolvente y el video comienza de inmediato."
        ),

        SensoryRoomInfo(
            name: "Área de Descanso y Snacks",
            shortDescription: "Zona para pausar la visita con alimentos y bebidas",
            noiseLevel: .medium,
            lightLevel: .high,
            crowdLevel: .medium,
            movementLevel: .medium,
            estimatedMinutes: 10,
            hasStrongSmells: true,
            hasLoudMachinery: false,
            hasDimLighting: false,
            hasFlashingLights: false,
            preparationTips: "Hay olores a comida y conversaciones. Es un buen lugar para recargar energía entre salas.",
            firstImpression: "Espacio abierto con mesas, gente moviéndose y olores de café y comida caliente."
        ),

        SensoryRoomInfo(
            name: "El Mirador",
            shortDescription: "Punto de observación panorámica desde lo alto del horno",
            noiseLevel: .medium,
            lightLevel: .high,
            crowdLevel: .high,
            movementLevel: .medium,
            estimatedMinutes: 15,
            hasStrongSmells: false,
            hasLoudMachinery: false,
            hasDimLighting: false,
            hasFlashingLights: false,
            preparationTips: "Es el punto más visitado del museo. Hay alturas significativas. Si eres sensible al vértigo considera omitirlo o subir despacio.",
            firstImpression: "Vista panorámica desde altura con mucha gente alrededor. Puede sentirse exposición al vacío y viento."
        ),

        SensoryRoomInfo(
            name: "Galería del Acero",
            shortDescription: "Zona interactiva con actividades y exhibiciones sobre el proceso del acero",
            noiseLevel: .high,
            lightLevel: .high,
            crowdLevel: .high,
            movementLevel: .high,
            estimatedMinutes: 25,
            hasStrongSmells: false,
            hasLoudMachinery: true,
            hasDimLighting: false,
            hasFlashingLights: false,
            preparationTips: "Hay actividades interactivas que generan ruido y aglomeración. Considera visitar en horario de poca afluencia.",
            firstImpression: "Sala animada y ruidosa con visitantes participando en actividades. Ambiente activo, dinámico y concurrido."
        )
    ]

    // MARK: -

    static var systemPrompt: String {
        let roomDescriptions = rooms.map { room in
            """
            Sala: \(room.name)
            Descripción: \(room.shortDescription)
            Ruido: \(room.noiseLevel.rawValue) | Luz: \(room.lightLevel.rawValue) | Aglomeración: \(room.crowdLevel.rawValue)
            Duración estimada: \(room.estimatedMinutes) minutos
            Olores fuertes: \(room.hasStrongSmells ? "sí" : "no")
            Maquinaria o ruidos bruscos: \(room.hasLoudMachinery ? "sí" : "no")
            Iluminación tenue o dramática: \(room.hasDimLighting ? "sí" : "no")
            Luces intermitentes: \(room.hasFlashingLights ? "sí" : "no")
            Primera impresión al entrar: \(room.firstImpression)
            Consejos de preparación: \(room.preparationTips)
            """
        }.joined(separator: "\n\n")

        return """
        Eres un asistente de accesibilidad sensorial del Museo del Acero Horno 3 en Monterrey, México.
        Tu misión es ayudar a visitantes con autismo, hipersensibilidad sensorial o ansiedad a saber
        exactamente qué esperar de cada sala antes de entrar.

        Reglas:
        1. Responde siempre en el idioma en que te hablen.
        2. Sé claro, directo y tranquilizador. Nunca uses lenguaje que genere ansiedad.
        3. Si preguntan por una sala específica, usa solo la información de esa sala.
        4. Si preguntan en general, puedes comparar salas o sugerir por dónde empezar.
        5. Nunca inventes información que no esté en los datos de las salas.
        6. Mantén las respuestas cortas: máximo 3 oraciones para la respuesta principal.

        Información de las salas del museo:

        \(roomDescriptions)
        """
    }
}
