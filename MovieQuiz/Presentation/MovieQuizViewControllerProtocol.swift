import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    func highlightImageBorder(isCorrectAnswer: Bool)
    func clearImageBorder()
    func showLoadingIndicator()
    func reloadView()
    func hideLoadingIndicator()
    func showNetworkError(message: String)
    func switchButtonVisability(wantToHide: Bool)
    
}
