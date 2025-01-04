import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - outlet's
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - private vars
    private let questionsAmount: Int = 10
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService? // не знаю почему вы решили по ТЗ что так надо назвать протокол но ладно
    
    // TODO: Самодельные свойства, они теперь не нужны, пока закомментирую, после review - удалю.
    //private var allRoundsResults: [QuizResultsModel] = [] // TODO: возможно нужно рефакторить, подумать над этим.
    //private var lastRoundResult: QuizResultsModel? = nil // TODO: возможно нужно рефакторить, подумать над этим.
    
    // MARK: - init's
    
    // MARK: - overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Инициализация необходимых вьюшек
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.contentMode = .scaleToFill
        
        // Подключаем фабрику вопросов
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        
        // Подключаем алерты
        alertPresenter = ResultAlertPresenter()
        
        // Подключаем статистику
        statisticService = StatisticService()
        
        // Инициализируем первый вопрос
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - actions
    @IBAction private func onNoClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction private func onYesClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    // MARK: - public methods
    // QuestionFactoryDelegate (получен ли новый вопрос)
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    func didLoadDataFromServer(moviesCount: Int) {
        if moviesCount > 0 {
            hideLoadingIndicator()
            questionFactory?.requestNextQuestion()
        } else {
            showNetworkError(title: "Что-то пошло не так(",  message: "Невозможно загрузить данные")
        }
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    // MARK: - private methods
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        switchButtonVisability(wantToHide: true)
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        switchButtonVisability(wantToHide: false)
    }
    
    private func showNetworkError(title: String = "Ошибка", message: String) {
        hideLoadingIndicator()
        
        let alert = AlertModel(title: title, message: message, buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.viewDidLoad()
            //self.questionFactory?.requestNextQuestion()
        }
        
        alertPresenter?.show(parentController: self, alertData: alert)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        
    }
    
    private func convertMessageToAlert() -> AlertModel {
        
        guard let statisticService else {
            return AlertModel(
                title: "Что-то пошло не так(",
                message: "Не удалось сформировать результат",
                buttonText: "Попробовать еще раз") { [weak self] in
                    guard let self = self else { return }
                    resetCurrentRoundVars()
                    questionFactory?.requestNextQuestion()
                }
        }
        
        // Конвертируем в сообщение и отдаем алерт модель, сбрасываем раунд и запускаем следующий вопрос ( если есть, но его нет :) )
        let resultAlertMessage = AlertModel(
            title: "Этот раунд окончен!",
            message: """
            Ваш результат: \(correctAnswers)/\(questionsAmount)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", (statisticService.totalAccuracy)))%
            """,
            buttonText: "Сыграть ещё раз") { [weak self] in
                guard let self = self else { return }
                
                resetCurrentRoundVars()
                questionFactory?.requestNextQuestion()
            }
        
        return resultAlertMessage
    }
    
    private func show(quiz step: QuizStepViewModel) {
        textLabel.text = step.question
        imageView.image = step.image
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect { correctAnswers += 1 } /// в случае если ответ правильно добавляем +1
        switchButtonVisability(wantToHide: true)
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            showNextQuestionOrResults()
            imageView.layer.borderWidth = 0
            switchButtonVisability(wantToHide: false)
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 { /// раунд завершен
            if let statisticService {
                // сохраням текущие данные в UserDefaults
                statisticService.store(correct: correctAnswers, total: questionsAmount)
            }
            // показываем алерт подсчитав данные из функции convertMessageToAlert
            alertPresenter?.show(parentController: self, alertData: convertMessageToAlert())
           
            
        } else { /// идем дальше к след. вопросу
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func resetCurrentRoundVars() {
        // Чтобы избежать дубликации в дальнейшем
        self.currentQuestionIndex = 0
        self.correctAnswers = 0
    }
    
    private func switchButtonVisability(wantToHide: Bool) {
        noButton.isEnabled = !wantToHide
        yesButton.isEnabled = !wantToHide
        noButton.layer.opacity = wantToHide ? 0.5 : 1
        yesButton.layer.opacity = wantToHide ? 0.5 : 1
    }
}
