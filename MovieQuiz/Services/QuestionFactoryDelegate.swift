import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer(moviesCount: Int)
    func didFailToLoadData(with error: Error)
}
