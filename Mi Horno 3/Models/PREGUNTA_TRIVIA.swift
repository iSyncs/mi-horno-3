import Foundation

#if canImport(FoundationModels)
import FoundationModels

@Generable
struct PREGUNTA_TRIVIA {
    var PREGUNTA: String
    var OPCIONES: [String]
    var RESPUESTA_CORRECTA: String
}

@Generable
struct PREGUNTAS_TRIVIA {
    var PREGUNTAS: [PREGUNTA_TRIVIA]
}
#endif
