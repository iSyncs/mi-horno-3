import Foundation

struct CameraMission: Identifiable, Hashable {
    let id: String
    let challengeID: String
    let zone: ChallengeZone
    let title: String
    let description: String
    let icon: String
    let classifierLabel: String
}

struct CameraMissionRepository {
    static func missions(lm: LocalizationManager) -> [CameraMission] {
        let s = lm.s
        return [
            CameraMission(
                id: "torpedo_historia",
                challengeID: "CAM-TORPEDO-HISTORIA",
                zone: .history,
                title: s(L.camTorpedoTitle),
                description: s(L.camTorpedoDescription),
                icon: "train.side.front.car",
                classifierLabel: "Torpedo_HISTORIA"
            ),
            CameraMission(
                id: "maquetahorno3_historia",
                challengeID: "CAM-MAQUETAHORNO3-HISTORIA",
                zone: .history,
                title: s(L.camMaquetaHornoTitle),
                description: s(L.camMaquetaHornoDescription),
                icon: "building.2.fill",
                classifierLabel: "MaquetaHorno3_HISTORIA"
            ),
            CameraMission(
                id: "telefonovintage_historia",
                challengeID: "CAM-TELEFONOVINTAGE-HISTORIA",
                zone: .history,
                title: s(L.camTelefonoTitle),
                description: s(L.camTelefonoDescription),
                icon: "phone.fill",
                classifierLabel: "TelefonoVintage_HISTORIA"
            ),
            CameraMission(
                id: "tele_historia",
                challengeID: "CAM-TELE-HISTORIA",
                zone: .history,
                title: s(L.camTelevisionTitle),
                description: s(L.camTelevisionDescription),
                icon: "tv",
                classifierLabel: "Tele_HISTORIA"
            ),
            CameraMission(
                id: "estrella_general",
                challengeID: "CAM-ESTRELLA-GENERAL",
                zone: .general,
                title: s(L.camEstrellaTitle),
                description: s(L.camEstrellaDescription),
                icon: "star.fill",
                classifierLabel: "Estrella_GENERAL"
            ),
            CameraMission(
                id: "observador_general",
                challengeID: "CAM-OBSERVADOR-GENERAL",
                zone: .general,
                title: s(L.camObservadorTitle),
                description: s(L.camObservadorDescription),
                icon: "binoculars.fill",
                classifierLabel: "Observador_GENERAL"
            ),
            CameraMission(
                id: "bocho_acero",
                challengeID: "CAM-BOCHO-ACERO",
                zone: .steelGallery,
                title: s(L.camBochoTitle),
                description: s(L.camBochoDescription),
                icon: "car.fill",
                classifierLabel: "Bocho_ACERO"
            ),
            CameraMission(
                id: "dinamita_acero",
                challengeID: "CAM-DINAMITA-ACERO",
                zone: .steelGallery,
                title: s(L.camDinamitaTitle),
                description: s(L.camDinamitaDescription),
                icon: "bolt.fill",
                classifierLabel: "Dinamita_ACERO"
            ),
            CameraMission(
                id: "grua_acero",
                challengeID: "CAM-GRUA-ACERO",
                zone: .steelGallery,
                title: s(L.camGruaTitle),
                description: s(L.camGruaDescription),
                icon: "wrench.and.screwdriver.fill",
                classifierLabel: "Grua_ACERO"
            ),
            CameraMission(
                id: "planchones_acero",
                challengeID: "CAM-PLANCHONES-ACERO",
                zone: .steelGallery,
                title: s(L.camPlanchonesTitle),
                description: s(L.camPlanchonesDescription),
                icon: "square.stack.3d.up.fill",
                classifierLabel: "Planchones_ACERO"
            ),
            CameraMission(
                id: "cucharon_historia",
                challengeID: "CAM-CUCHARON-HISTORIA",
                zone: .history,
                title: s(L.camCucharonTitle),
                description: s(L.camCucharonDescription),
                icon: "drop.fill",
                classifierLabel: "Cucharon_HISTORIA"
            ),
            CameraMission(
                id: "extintor_historia",
                challengeID: "CAM-EXTINTOR-HISTORIA",
                zone: .history,
                title: s(L.camExtintorTitle),
                description: s(L.camExtintorDescription),
                icon: "exclamationmark.shield.fill",
                classifierLabel: "Extintor_HISTORIA"
            ),
            CameraMission(
                id: "camioneta_historia",
                challengeID: "CAM-CAMIONETA-HISTORIA",
                zone: .history,
                title: s(L.camCamionetaTitle),
                description: s(L.camCamionetaDescription),
                icon: "truck.box.fill",
                classifierLabel: "Camioneta_HISTORIA"
            ),
            CameraMission(
                id: "maquinaescribir_historia",
                challengeID: "CAM-MAQUINAESCRIBIR-HISTORIA",
                zone: .history,
                title: s(L.camMaquinaEscribirTitle),
                description: s(L.camMaquinaEscribirDescription),
                icon: "keyboard.fill",
                classifierLabel: "Maquinaescribir_HISTORIA"
            ),
        ]
    }

    static func randomMission(for zone: ChallengeZone, lm: LocalizationManager) -> CameraMission? {
        missions(lm: lm).filter { $0.zone == zone }.shuffled().first
    }
}
