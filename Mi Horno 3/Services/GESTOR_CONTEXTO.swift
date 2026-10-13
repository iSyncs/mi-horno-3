import Foundation

struct GESTOR_CONTEXTO {
    static func LEER_ARCHIVO_MD(NOMBRE_ARCHIVO: String) -> String {
        let NOMBRE_LIMPIO = NOMBRE_ARCHIVO.replacingOccurrences(of: ".md", with: "")
        let SUBDIRECTORIOS: [String?] = [nil, "ContextoIA", "Resources/ContextoIA"]

        for SUBDIRECTORIO in SUBDIRECTORIOS {
            let URL_ARCHIVO = Bundle.main.url(
                forResource: NOMBRE_LIMPIO,
                withExtension: "md",
                subdirectory: SUBDIRECTORIO
            )

            if let URL_ARCHIVO,
               let CONTENIDO = try? String(contentsOf: URL_ARCHIVO, encoding: .utf8) {
                return CONTENIDO
            }
        }

        return ""
    }

    static func OBTENER_CONTEXTO_ZONA(ZONA: String) -> String {
        switch ZONA.lowercased() {
        case "history", "historia":
            return LEER_ARCHIVO_MD(NOMBRE_ARCHIVO: "CONTEXTO_HISTORIA_FACTS")
        case "steelgallery", "steel_gallery", "acero", "galeria_acero", "galeria_acero":
            return LEER_ARCHIVO_MD(NOMBRE_ARCHIVO: "GUIA_INTERACTIVA_ACERO_FACTS")
        default:
            return LEER_ARCHIVO_MD(NOMBRE_ARCHIVO: "CONTEXTO_GENERAL_FACTS")
        }
    }
}
