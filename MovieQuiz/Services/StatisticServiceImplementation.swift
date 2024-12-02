import Foundation

final class StatisticServiceImplementation : StatisticService {

    private let storage: UserDefaults = .standard
    
    private enum Keys: String {
        case correct
        case gamesCount
        case totalAccuracy
        case bestGame
        case bestGameCorrect
        case bestGameTotal
        case bestGameDate
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResultModel {
        get {
            GameResultModel(
                correct: storage.integer(forKey: Keys.bestGameCorrect.rawValue),
                total: storage.integer(forKey: Keys.bestGameTotal.rawValue),
                date: storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date() // TODO: Я понимаю  что некорректно возвращать текущую дату если не удалось получить дату но не понимаю как это исправить и на что заменить, разве так правильно оставлять?
            )
        }
        set {
            // TODO: Самостоятельно у меня не получилось записать напрямую модель GameResultModel в UserDefaults поэтому делаю как описал автор.
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
            storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
            storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
        }
    }
    
    var totalAccuracy: Double {
        get {
            storage.double(forKey: Keys.totalAccuracy.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.totalAccuracy.rawValue)
        }
    }
    
    var correct: Int {
        get {
            storage.integer(forKey: Keys.correct.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.correct.rawValue)
        }
     }
     
    func store(correct count: Int, total amount: Int) {
        correct += count
        gamesCount += 1
        totalAccuracy = (Double(correct)/Double(10*gamesCount))*100

        
        // тут проверяем является ли последняя игра лучше чем рекордная если да то она становится рекордной
        let lastGame = GameResultModel(correct: count, total: amount, date: Date())
        if lastGame.isBetterThen(bestGame) {
            self.bestGame = lastGame
        }
    }
}
