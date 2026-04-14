import Foundation

struct RecommendationsStreamResponse<T: RecommendationUserData>: Codable {
    let data: [Recommendation<T>]?
    let errors: String
    let success: Bool
}
