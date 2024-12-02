import Foundation

struct GameResultModel {
    
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThen(_ prevRecord: GameResultModel) -> Bool {
        correct > prevRecord.correct
    }
}
