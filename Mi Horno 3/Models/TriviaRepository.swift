import Foundation

struct TriviaRepository {
    static func historyQuestions(lm: LocalizationManager) -> [ChallengeQuestion] {
        let s = lm.s
        return [
            ChallengeQuestion(
                id: "hist_sidermex_1",
                text: s(L.tHistSidermex1Text),
                options: [s(L.tHistSidermex1Opt0), s(L.tHistSidermex1Opt1), s(L.tHistSidermex1Opt2), s(L.tHistSidermex1Opt3)],
                correctIndex: 1,
                explanation: s(L.tHistSidermex1Explanation)
            ),
            ChallengeQuestion(
                id: "hist_lema_70s",
                text: s(L.tHistLema70sText),
                options: [s(L.tHistLema70sOpt0), s(L.tHistLema70sOpt1), s(L.tHistLema70sOpt2), s(L.tHistLema70sOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistLema70sExplanation)
            ),
            ChallengeQuestion(
                id: "hist_primer_edificio",
                text: s(L.tHistPrimerEdificioText),
                options: [s(L.tHistPrimerEdificioOpt0), s(L.tHistPrimerEdificioOpt1), s(L.tHistPrimerEdificioOpt2), s(L.tHistPrimerEdificioOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistPrimerEdificioExplanation)
            ),
            ChallengeQuestion(
                id: "hist_porfirio_diaz",
                text: s(L.tHistPorfirioDiazText),
                options: [s(L.tHistPorfirioDiazOpt0), s(L.tHistPorfirioDiazOpt1), s(L.tHistPorfirioDiazOpt2), s(L.tHistPorfirioDiazOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistPorfirioDiazExplanation)
            ),
            ChallengeQuestion(
                id: "hist_huelgas_70_80",
                text: s(L.tHistHuelgas7080Text),
                options: [s(L.tHistHuelgas7080Opt0), s(L.tHistHuelgas7080Opt1), s(L.tHistHuelgas7080Opt2), s(L.tHistHuelgas7080Opt3)],
                correctIndex: 1,
                explanation: s(L.tHistHuelgas7080Explanation)
            ),
            ChallengeQuestion(
                id: "hist_hyl_tecnologia",
                text: s(L.tHistHylTecnologiaText),
                options: [s(L.tHistHylTecnologiaOpt0), s(L.tHistHylTecnologiaOpt1), s(L.tHistHylTecnologiaOpt2), s(L.tHistHylTecnologiaOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistHylTecnologiaExplanation)
            ),
            ChallengeQuestion(
                id: "hist_fundidora_cierre",
                text: s(L.tHistFundidoraCierreText),
                options: [s(L.tHistFundidoraCierreOpt0), s(L.tHistFundidoraCierreOpt1), s(L.tHistFundidoraCierreOpt2), s(L.tHistFundidoraCierreOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistFundidoraCierreExplanation)
            ),
            ChallengeQuestion(
                id: "hist_monterrey_ubicacion",
                text: s(L.tHistMonterreyUbicacionText),
                options: [s(L.tHistMonterreyUbicacionOpt0), s(L.tHistMonterreyUbicacionOpt1), s(L.tHistMonterreyUbicacionOpt2), s(L.tHistMonterreyUbicacionOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistMonterreyUbicacionExplanation)
            ),
            ChallengeQuestion(
                id: "hist_seguridad_pepe_gallo",
                text: s(L.tHistSeguridadPepeGalloText),
                options: [s(L.tHistSeguridadPepeGalloOpt0), s(L.tHistSeguridadPepeGalloOpt1), s(L.tHistSeguridadPepeGalloOpt2), s(L.tHistSeguridadPepeGalloOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistSeguridadPepeGalloExplanation)
            ),
            ChallengeQuestion(
                id: "hist_pape_ahmsa",
                text: s(L.tHistPapeAhmsaText),
                options: [s(L.tHistPapeAhmsaOpt0), s(L.tHistPapeAhmsaOpt1), s(L.tHistPapeAhmsaOpt2), s(L.tHistPapeAhmsaOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistPapeAhmsaExplanation)
            ),
            ChallengeQuestion(
                id: "hist_crisis_76_82",
                text: s(L.tHistCrisis7682Text),
                options: [s(L.tHistCrisis7682Opt0), s(L.tHistCrisis7682Opt1), s(L.tHistCrisis7682Opt2), s(L.tHistCrisis7682Opt3)],
                correctIndex: 1,
                explanation: s(L.tHistCrisis7682Explanation)
            ),
            ChallengeQuestion(
                id: "hist_familia_acero",
                text: s(L.tHistFamiliaAceroText),
                options: [s(L.tHistFamiliaAceroOpt0), s(L.tHistFamiliaAceroOpt1), s(L.tHistFamiliaAceroOpt2), s(L.tHistFamiliaAceroOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistFamiliaAceroExplanation)
            ),
            ChallengeQuestion(
                id: "hist_constitucion_1917",
                text: s(L.tHistConstitucion1917Text),
                options: [s(L.tHistConstitucion1917Opt0), s(L.tHistConstitucion1917Opt1), s(L.tHistConstitucion1917Opt2), s(L.tHistConstitucion1917Opt3)],
                correctIndex: 1,
                explanation: s(L.tHistConstitucion1917Explanation)
            ),
            ChallengeQuestion(
                id: "hist_colonial_prohibicion",
                text: s(L.tHistColonialProhibicionText),
                options: [s(L.tHistColonialProhibicionOpt0), s(L.tHistColonialProhibicionOpt1), s(L.tHistColonialProhibicionOpt2), s(L.tHistColonialProhibicionOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistColonialProhibicionExplanation)
            ),
            ChallengeQuestion(
                id: "hist_segunda_guerra",
                text: s(L.tHistSegundaGuerraText),
                options: [s(L.tHistSegundaGuerraOpt0), s(L.tHistSegundaGuerraOpt1), s(L.tHistSegundaGuerraOpt2), s(L.tHistSegundaGuerraOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistSegundaGuerraExplanation)
            ),
            ChallengeQuestion(
                id: "hist_durango_blockade",
                text: s(L.tHistDurangoBlockadeText),
                options: [s(L.tHistDurangoBlockadeOpt0), s(L.tHistDurangoBlockadeOpt1), s(L.tHistDurangoBlockadeOpt2), s(L.tHistDurangoBlockadeOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistDurangoBlockadeExplanation)
            ),
            ChallengeQuestion(
                id: "hist_obregon_schools",
                text: s(L.tHistObregonSchoolsText),
                options: [s(L.tHistObregonSchoolsOpt0), s(L.tHistObregonSchoolsOpt1), s(L.tHistObregonSchoolsOpt2), s(L.tHistObregonSchoolsOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistObregonSchoolsExplanation)
            ),
            ChallengeQuestion(
                id: "hist_deacero_origins",
                text: s(L.tHistDeaceroOriginsText),
                options: [s(L.tHistDeaceroOriginsOpt0), s(L.tHistDeaceroOriginsOpt1), s(L.tHistDeaceroOriginsOpt2), s(L.tHistDeaceroOriginsOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistDeaceroOriginsExplanation)
            ),
            ChallengeQuestion(
                id: "hist_first_mexican_boss",
                text: s(L.tHistFirstMexicanBossText),
                options: [s(L.tHistFirstMexicanBossOpt0), s(L.tHistFirstMexicanBossOpt1), s(L.tHistFirstMexicanBossOpt2), s(L.tHistFirstMexicanBossOpt3)],
                correctIndex: 0,
                explanation: s(L.tHistFirstMexicanBossExplanation)
            ),
            ChallengeQuestion(
                id: "hist_colonia_acero",
                text: s(L.tHistColoniaAceroText),
                options: [s(L.tHistColoniaAceroOpt0), s(L.tHistColoniaAceroOpt1), s(L.tHistColoniaAceroOpt2), s(L.tHistColoniaAceroOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistColoniaAceroExplanation)
            ),
            ChallengeQuestion(
                id: "hist_aguador_story",
                text: s(L.tHistAguadorStoryText),
                options: [s(L.tHistAguadorStoryOpt0), s(L.tHistAguadorStoryOpt1), s(L.tHistAguadorStoryOpt2), s(L.tHistAguadorStoryOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistAguadorStoryExplanation)
            ),
            ChallengeQuestion(
                id: "hist_torpedo_car",
                text: s(L.tHistTorpedoCarText),
                options: [s(L.tHistTorpedoCarOpt0), s(L.tHistTorpedoCarOpt1), s(L.tHistTorpedoCarOpt2), s(L.tHistTorpedoCarOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistTorpedoCarExplanation)
            ),
            ChallengeQuestion(
                id: "hist_ferrocarril_kms",
                text: s(L.tHistFerrocarrilKmsText),
                options: [s(L.tHistFerrocarrilKmsOpt0), s(L.tHistFerrocarrilKmsOpt1), s(L.tHistFerrocarrilKmsOpt2), s(L.tHistFerrocarrilKmsOpt3)],
                correctIndex: 3,
                explanation: s(L.tHistFerrocarrilKmsExplanation)
            ),
            ChallengeQuestion(
                id: "hist_pape_wife",
                text: s(L.tHistPapeWifeText),
                options: [s(L.tHistPapeWifeOpt0), s(L.tHistPapeWifeOpt1), s(L.tHistPapeWifeOpt2), s(L.tHistPapeWifeOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistPapeWifeExplanation)
            ),
            ChallengeQuestion(
                id: "hist_hylsa_puebla",
                text: s(L.tHistHylsaPueblaText),
                options: [s(L.tHistHylsaPueblaOpt0), s(L.tHistHylsaPueblaOpt1), s(L.tHistHylsaPueblaOpt2), s(L.tHistHylsaPueblaOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistHylsaPueblaExplanation)
            ),
            ChallengeQuestion(
                id: "hist_monterrey_industrial_output",
                text: s(L.tHistMonterreyIndustrialOutputText),
                options: [s(L.tHistMonterreyIndustrialOutputOpt0), s(L.tHistMonterreyIndustrialOutputOpt1), s(L.tHistMonterreyIndustrialOutputOpt2), s(L.tHistMonterreyIndustrialOutputOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistMonterreyIndustrialOutputExplanation)
            ),
            ChallengeQuestion(
                id: "hist_catalan_forge",
                text: s(L.tHistCatalanForgeText),
                options: [s(L.tHistCatalanForgeOpt0), s(L.tHistCatalanForgeOpt1), s(L.tHistCatalanForgeOpt2), s(L.tHistCatalanForgeOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistCatalanForgeExplanation)
            ),
            ChallengeQuestion(
                id: "hist_golden_era_products",
                text: s(L.tHistGoldenEraProductsText),
                options: [s(L.tHistGoldenEraProductsOpt0), s(L.tHistGoldenEraProductsOpt1), s(L.tHistGoldenEraProductsOpt2), s(L.tHistGoldenEraProductsOpt3)],
                correctIndex: 3,
                explanation: s(L.tHistGoldenEraProductsExplanation)
            ),
            ChallengeQuestion(
                id: "hist_revolucion_impact",
                text: s(L.tHistRevolucionImpactText),
                options: [s(L.tHistRevolucionImpactOpt0), s(L.tHistRevolucionImpactOpt1), s(L.tHistRevolucionImpactOpt2), s(L.tHistRevolucionImpactOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistRevolucionImpactExplanation)
            ),
            ChallengeQuestion(
                id: "hist_safety_equipment",
                text: s(L.tHistSafetyEquipmentText),
                options: [s(L.tHistSafetyEquipmentOpt0), s(L.tHistSafetyEquipmentOpt1), s(L.tHistSafetyEquipmentOpt2), s(L.tHistSafetyEquipmentOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistSafetyEquipmentExplanation)
            ),
            ChallengeQuestion(
                id: "hist_alto_horno_3_temp",
                text: s(L.tHistAltoHorno3TempText),
                options: [s(L.tHistAltoHorno3TempOpt0), s(L.tHistAltoHorno3TempOpt1), s(L.tHistAltoHorno3TempOpt2), s(L.tHistAltoHorno3TempOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistAltoHorno3TempExplanation)
            ),
            ChallengeQuestion(
                id: "hist_alto_horno_3_altura",
                text: s(L.tHistAltoHorno3AlturaText),
                options: [s(L.tHistAltoHorno3AlturaOpt0), s(L.tHistAltoHorno3AlturaOpt1), s(L.tHistAltoHorno3AlturaOpt2), s(L.tHistAltoHorno3AlturaOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistAltoHorno3AlturaExplanation)
            ),
            ChallengeQuestion(
                id: "hist_patrimonio_industrial",
                text: s(L.tHistPatrimonioIndustrialText),
                options: [s(L.tHistPatrimonioIndustrialOpt0), s(L.tHistPatrimonioIndustrialOpt1), s(L.tHistPatrimonioIndustrialOpt2), s(L.tHistPatrimonioIndustrialOpt3)],
                correctIndex: 2,
                explanation: s(L.tHistPatrimonioIndustrialExplanation)
            ),
            ChallengeQuestion(
                id: "hist_ingrediente_acero",
                text: s(L.tHistIngredienteAceroText),
                options: [s(L.tHistIngredienteAceroOpt0), s(L.tHistIngredienteAceroOpt1), s(L.tHistIngredienteAceroOpt2), s(L.tHistIngredienteAceroOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistIngredienteAceroExplanation)
            ),
            ChallengeQuestion(
                id: "hist_pico_produccion",
                text: s(L.tHistPicoProduccionText),
                options: [s(L.tHistPicoProduccionOpt0), s(L.tHistPicoProduccionOpt1), s(L.tHistPicoProduccionOpt2), s(L.tHistPicoProduccionOpt3)],
                correctIndex: 1,
                explanation: s(L.tHistPicoProduccionExplanation)
            ),
        ]
    }
}
