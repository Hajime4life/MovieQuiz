import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate, AlertPresenterDelegate {
    
    // MARK: - outlet's
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    // MARK: - private vars
    
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
        
        // Подключаем фабрику вопросов
        let questionFactory = QuestionFactory()
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        
        // Подключаем алерты
        let alert = ResultAlertPresenter()
        alert.delegate = self
        self.alertPresenter = alert
        
        // Подключаем статистику
        statisticService = StatisticServiceImplementation()
        
        // Инициализируем первый вопрос
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - actions
    @IBAction private func onNoClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    @IBAction private func onYesClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
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
    
    // MARK: - private methods
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
        return questionStep
    }
    // TODO: Возможно нерпавильно назвал метод, если что поправьте пожалуйста
    
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
        
//        var finalText = ""
//        Если до этого были сыграны игры то отображать общую статистику иначе просто количество правильных ответов
//        if statisticService.gamesCount == 0 {
//            finalText = """
//            Ваш результат: \(correctAnswers)/\(questionsAmount)
//            Количество сыгранных квизов: \(statisticService.gamesCount)
//            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
//            Средняя точность: \(String(format: "%.2f", (statisticService.totalAccuracy)))%
//            """
//        } else {
//            finalText = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
//        }
                
        // Конвертируем в сообщение и отдаем алерт модель, сбрасываем раунд и запускаем следующий вопрос ( если есть, но его нет :) )
        let resultAlertMessage = AlertModel(
            title: /*statisticService.gamesCount == 0 ?  "Раунд окончен!" :*/ "Этот раунд окончен!"  ,
            message: """
            Ваш результат: \(correctAnswers)/\(questionsAmount)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", (statisticService.totalAccuracy)))%
            """,
            buttonText: "Сыграть еще раз") { [weak self] in
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


// TODO: УДАЛИТЬ ВСË НИЖЕ ПОСЛЕ РЕВЬЮ!!!!!!!!!!! -
// TODO: Возможно надо будет удалить / переместить
//    private func countMiddleResult() -> Int {
//        guard questionsAmount != 0 else { return 0 }
//        var totalAccuracy: Float = 0.0
//        for result in allRoundsResults {
//            let accuracy = (Float(result.roundResult) / Float(questionsAmount)) * 100
//            totalAccuracy += accuracy
//        }
//        
//        let persent = totalAccuracy / Float(allRoundsResults.count)
//        return  Int(round(persent)) /// округляем от лишних знаков после запятой | пришлось помучаться в гугле ради этого решения :)
//    }
    // TODO: Возможно надо будет удалить / переместить
//    private func findRecordedResult() -> QuizResultsModel {
//        var bestRound = allRoundsResults[0]
//        
//        for round in allRoundsResults {
//            if round.roundResult > bestRound.roundResult {
//                bestRound = round
//            }
//        }
//        
//        return bestRound
//    }
    
    // TODO: тут закомментировал функцию алерта, возможно понадобится, переношу в AlertPresenter
//    private func showAlert(quiz result: QuizResultsViewModel) {
//        let alert = UIAlertController(
//            title: result.title,
//            message: result.text,
//            preferredStyle: .alert)
//        
//        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
//            guard let self = self else { return }
//            self.currentQuestionIndex = 0
//            self.correctAnswers = 0
//            questionFactory?.requestNextQuestion()
//        }
//        
//        alert.addAction(action)
//        self.present(alert, animated: true, completion: nil)
//    }

}

// TODO: Обязательно перенести этот класс в отдельный файл, пока не знаю нужен ли он вообще, может удалить придется...
// Свой класс (возможно надо удалить/перенести)
// класс для хранения результатов теста (самодельный)
//final class QuizResultsModel {
//    var roundResult: Int
//    var roundDate: Date?
//    
//    init() {
//        self.roundResult = 0
//        self.roundDate = nil
//    }
//    
//    init(roundResult: Int, roundDate: Date) {
//        self.roundResult = roundResult
//        self.roundDate = roundDate
//    }
//}
