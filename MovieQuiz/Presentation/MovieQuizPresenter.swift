import UIKit

final class MovieQuizPresenter {
    
    // MARK: - PRIVATE PROPERTIES
    private var currentQuestionIndex: Int = 0
    
    // MARK: - PUBLIC PROPERTIES
    let questionsAmount: Int = 10
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    var correctAnswers: Int = 0
    var questionFactory: QuestionFactoryProtocol?

    
    // MARK: - PRIVATE METHODS
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = isYes
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func convertMessageToAlert() -> AlertModel {
        let text = "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"

        let resultAlertMessage = AlertModel(title: "Этот раунд окончен!", message: text, buttonText: "Сыграть ещё раз") {
            self.viewController?.viewDidLoad()
        }
//        guard let statisticService else {
//            return AlertModel(
//                title: "Что-то пошло не так(",
//                message: "Не удалось сформировать результат",
//                buttonText: "Попробовать еще раз") { [weak self] in
//                    guard let self = self else { return }
//                    resetCurrentRoundVars()
//                    questionFactory?.requestNextQuestion()
//                }
//        }
//        
//        // Конвертируем в сообщение и отдаем алерт модель, сбрасываем раунд и запускаем следующий вопрос ( если есть, но его нет :) )
//        let resultAlertMessage = AlertModel(
//            title: "Этот раунд окончен!",
//            message: """
//            Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)
//            Количество сыгранных квизов: \(statisticService.gamesCount)
//            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
//            Средняя точность: \(String(format: "%.2f", (statisticService.totalAccuracy)))%
//            """,
//            buttonText: "Сыграть ещё раз") { [weak self] in
//                guard let self = self else { return }
//                
//                resetCurrentRoundVars()
//                questionFactory?.requestNextQuestion()
//            }
        
        return resultAlertMessage
    }
    
    // MARK: - PULBIC METHODS
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = self.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
        
    }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
//            if let statisticService {
//                statisticService.store(correct: correctAnswers, total: self.questionsAmount)
//            }
            guard let viewController = viewController else { return }
            viewController.alertPresenter?.show(parentController: viewController, alertData: self.convertMessageToAlert())
            
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
            
        }
    }
}
