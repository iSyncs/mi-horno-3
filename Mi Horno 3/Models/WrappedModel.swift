//
//  WrappedModel.swift
//  Mi Horno 3
//

import SwiftUI

// MARK: - Tarjeta del wrapped

enum WrappedCardType {
    case welcome, challenges, accuracy, medals, nickname, closing
}

struct WrappedCard: Identifiable {
    let id = UUID()
    let type: WrappedCardType
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let accentColor: Color
}

// MARK: - Apodo del visitante

struct VisitorNickname {
    let name: String
    let icon: String
    let description: String

    static func generate(
        answersCount: Int,
        correctCount: Int,
        unlockedMedals: Int,
        lm: LocalizationManager
    ) -> VisitorNickname {
        let accuracy = answersCount > 0 ? Double(correctCount) / Double(answersCount) : 0

        switch (answersCount, accuracy, unlockedMedals) {
        case (114, let a, _) where a >= 0.9:
            return VisitorNickname(
                name: lm.s(L.nickMaestroName),
                icon: "crown.fill",
                description: lm.s(L.nickMaestroDesc)
            )
        case (114, _, let m) where m >= 5:
            return VisitorNickname(
                name: lm.s(L.nickColeccionistaName),
                icon: "medal.fill",
                description: lm.s(L.nickColeccionistaDesc)
            )
        case (let a, _, _) where a >= 7:
            return VisitorNickname(
                name: lm.s(L.nickExploradorName),
                icon: "flame.fill",
                description: lm.s(L.nickExploradorDesc)
            )
        case (_, let acc, _) where acc >= 0.7:
            return VisitorNickname(
                name: lm.s(L.nickPerspicazName),
                icon: "bolt.fill",
                description: lm.s(L.nickPerspicazDesc)
            )
        case (let a, _, _) where a >= 3:
            return VisitorNickname(
                name: lm.s(L.nickAprendizName),
                icon: "star.fill",
                description: lm.s(L.nickAprendizDesc)
            )
        default:
            return VisitorNickname(
                name: lm.s(L.nickCuriosoName),
                icon: "eyes",
                description: lm.s(L.nickCuriosoDesc)
            )
        }
    }
}

// MARK: - Datos del wrapped

struct WrappedData {
    let answersCount: Int
    let correctCount: Int
    let unlockedMedals: Int
    let totalMedals: Int
    let nickname: VisitorNickname

    var accuracy: Int {
        answersCount > 0 ? Int(Double(correctCount) / Double(answersCount) * 100) : 0
    }
    var progressText: String { "\(answersCount)/114" }
}
