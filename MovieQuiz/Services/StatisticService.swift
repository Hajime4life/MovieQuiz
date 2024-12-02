import Foundation

protocol StatisticService { // ПОЧЕМУ так а не StatisticServiceProtocol
    var gamesCount: Int { get }
    var bestGame: GameResultModel { get }
    var totalAccuracy: Double { get }
    func store(correct count: Int, total amount: Int)
}
