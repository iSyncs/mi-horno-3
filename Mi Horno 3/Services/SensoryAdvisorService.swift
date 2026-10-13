// SensoryAdvisorService.swift


import Foundation
import FoundationModels

final class SensoryAdvisorService {

    // MARK: - Availability check

    static func checkAvailability() throws {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw SensoryError.deviceNotEligible
        case .unavailable(.modelNotReady):
            throw SensoryError.modelNotReady
        case .unavailable(_):
            throw SensoryError.modelUnavailable
        @unknown default:
            return
        }
    }

    static var isModelAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    // MARK: - Ask

    func ask(_ question: String) async throws -> SensoryResponse {
        // Si el modelo no está disponible, usar respuestas simuladas
        if !SensoryAdvisorService.isModelAvailable {
            return try await simulatedResponse(for: question)
        }

        let session = LanguageModelSession(
            instructions: SensoryRoomData.systemPrompt
        )

        let response = try await session.respond(
            to: question,
            generating: SensoryResponse.self
        )

        return response.content
    }

    // MARK: - Respuestas simuladas (simulador / dispositivo no compatible)

    private func simulatedResponse(for question: String) async throws -> SensoryResponse {
        // Simular latencia de red para que se vea realista
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let q = question.lowercased()

        if q.contains("tranquil") || q.contains("calm") || q.contains("quiet") {
            return SensoryResponse(
                answer: "La Galería de la Historia del Acero es la sala más tranquila. Tiene iluminación normal, poco ruido y no hay maquinaria.",
                tip: "Es ideal para empezar la visita o para tomar un descanso.",
                overallLevel: "tranquila"
            )
        } else if q.contains("ruido") || q.contains("noise") || q.contains("loud") {
            return SensoryResponse(
                answer: "La Sala del Alto Horno tiene el nivel de ruido más alto, con grabaciones de maquinaria pesada en loop continuo.",
                tip: "Considera usar audífonos de reducción de ruido antes de entrar.",
                overallLevel: "intensa"
            )
        } else if q.contains("luz") || q.contains("light") || q.contains("oscur") {
            return SensoryResponse(
                answer: "La Sala de Proyección y el Alto Horno tienen iluminación tenue y dramática. La Galería y el Área de Descanso tienen luz normal.",
                tip: "Si eres sensible a la oscuridad, puedes salir en cualquier momento.",
                overallLevel: "moderada"
            )
        } else if q.contains("empe") || q.contains("start") || q.contains("primero") {
            return SensoryResponse(
                answer: "Te recomiendo empezar por la Galería de la Historia del Acero. Es amplia, silenciosa y con buena iluminación.",
                tip: "Guarda las salas más intensas como el Alto Horno para cuando estés más ambientado.",
                overallLevel: "tranquila"
            )
        } else if q.contains("destello") || q.contains("intermiten") || q.contains("flash") {
            return SensoryResponse(
                answer: "Solo la Sala de Proyección tiene luces intermitentes durante el documental audiovisual.",
                tip: "Puedes salir de la Sala de Proyección en cualquier momento si te incomoda.",
                overallLevel: "intensa"
            )
        } else {
            return SensoryResponse(
                answer: "El museo tiene 5 zonas principales. Las más tranquilas son la Galería de Historia y el Área de Descanso. Las más intensas son el Alto Horno y la Sala de Proyección.",
                tip: "Puedes preguntarme por cualquier sala específica para más detalles.",
                overallLevel: "moderada"
            )
        }
    }

    // MARK: - Errors

    enum SensoryError: LocalizedError {
        case deviceNotEligible
        case modelNotReady
        case modelUnavailable

        var errorDescription: String? {
            switch self {
            case .deviceNotEligible:
                return "Este dispositivo no es compatible con el asistente sensorial."
            case .modelNotReady:
                return "El modelo está cargando. Intenta de nuevo en un momento."
            case .modelUnavailable:
                return "El asistente sensorial no está disponible en este momento."
            }
        }
    }
}