import Foundation

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameResultModel { get }
    var totalAccuracy: Double { get }
    func store(correct count: Int, total amount: Int)
}
