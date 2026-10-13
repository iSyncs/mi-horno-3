

import Foundation
import FoundationModels

// MARK: - Nivel sensorial 

enum SensoryLevel: String, CaseIterable {
    case low    = "bajo"
    case medium = "medio"
    case high   = "alto"
}

// MARK: - Sala con información sensorial

struct SensoryRoomInfo {

    let name: String
    let shortDescription: String    

    // Niveles sensoriales
    let noiseLevel: SensoryLevel        
    let lightLevel: SensoryLevel        
    let crowdLevel: SensoryLevel        
    let movementLevel: SensoryLevel    

    // Información práctica
    let estimatedMinutes: Int           
    let hasStrongSmells: Bool           
    let hasLoudMachinery: Bool          
    let hasDimLighting: Bool            
    let hasFlashingLights: Bool      

    let preparationTips: String

    let firstImpression: String
}

// MARK: - Respuesta estructurada del modelo 

@Generable(description: "Respuesta del asistente sensorial del museo")
struct SensoryResponse {

    @Guide(description: "Respuesta directa y clara a la pregunta del visitante. Máximo 60 palabras. Sin tecnicismos. Tono amable y tranquilizador.")
    var answer: String

    @Guide(description: "Un consejo práctico de preparación específico para esta sala. Máximo 20 palabras.")
    var tip: String

    @Guide(description: "Nivel de intensidad sensorial general de la sala: 'tranquila', 'moderada' o 'intensa'.")
    var overallLevel: String
}