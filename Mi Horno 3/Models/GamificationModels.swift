import Foundation

struct Challenge: Codable, Identifiable {
    var id: String { challenge_id }
    let challenge_id: String
    let zone_id: Int
    let question: String
    let options: [String]
    let correct_answer: String
    let type: String
}

final class ChallengeStore {
    static let shared = ChallengeStore()
    var challenges: [Challenge] = []
    
    private init() {
        loadLocalData()
    }
    
    private func loadLocalData() {
        guard let url = Bundle.main.url(forResource: "trivia_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Error: No se encontró trivia_data.json en el bundle")
            return
        }
        
        do {
            self.challenges = try JSONDecoder().decode([Challenge].self, from: data)
            print("✅ ChallengeStore: \(challenges.count) retos cargados.")
        } catch {
            print("❌ Error decodificando retos: \(error)")
        }
    }
}
