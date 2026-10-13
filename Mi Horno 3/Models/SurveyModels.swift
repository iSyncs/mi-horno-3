// SurveyModels.swift
import Foundation

struct SurveyQuestion: Identifiable {
    let id: Int
    let text: String
    let options: [String]
    let hasFollowUp: Bool
}

// MARK: - API Models

struct SurveySubmissionPayload: Codable {
    let responses: [SurveyResponseItem]
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case responses
        case appVersion = "app_version"
    }
}

struct SurveyResponseItem: Codable {
    let questionId: Int
    let questionText: String
    let selectedOption: String
    let followUpText: String?

    enum CodingKeys: String, CodingKey {
        case questionId     = "question_id"
        case questionText   = "question_text"
        case selectedOption = "selected_option"
        case followUpText   = "follow_up_text"
    }
}

struct SurveyStatusResponse: Codable {
    let completed: Bool
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case completed
        case completedAt = "completed_at"
    }
}
