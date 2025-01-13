import Foundation

protocol MovieQuizPresenterProtocol {
    var questionsAmount: Int { get }
    var correctAnswers: Int { get }
    func yesButtonClicked()
    func noButtonClicked()
    func isLastQuestion() -> Bool
    func restartGame()
    func didAnswer(isCorrectAnswer: Bool)
    func proceedToNextQuestionOrResults()
    func makeResultsMessage() -> String
}
