import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - IBOutlet's
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    // MARK: - private varuables
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var allRoundsResults: [QuizResultsModel] = [] // TODO: возможно нужно рефакторить, подумать над этим.
    private var lastRoundResult: QuizResultsModel? = nil // TODO: возможно нужно рефакторить, подумать над этим.
    
    // MARK: - overrids
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        
        let questionFactory = QuestionFactory()
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - actions:
    @IBAction private func onNoClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: true == currentQuestion.correctAnswer)
    }
    
    @IBAction private func onYesClicked() {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: false == currentQuestion.correctAnswer)
    }
    
    // MARK: - private functions
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        textLabel.text = step.question
        imageView.image = step.image
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect { correctAnswers += 1 }
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
            lastRoundResult = QuizResultsModel(roundResult: correctAnswers, roundDate: Date())
            allRoundsResults.append(lastRoundResult!)
            
            var text = ""
            
            if allRoundsResults.count <= 1 {
                text = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
            } else {
                let bestRound = findRecordedResult()
                text = """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Количество сыгранных квизов: \(allRoundsResults.count)
                Рекорд: \(bestRound.roundResult)/\(questionsAmount) (\(bestRound.roundDate?.dateTimeString ?? ""))
                Средняя точность: \(countMiddleResult())%
                """
            }
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз"
            )
            
            showResultAlert(quiz: viewModel) /// тут уже произайдут обнуления
            
        } else { /// идем дальше к след. вопросу
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func countMiddleResult() -> Int {
        guard questionsAmount != 0 else { return 0 }
        var totalAccuracy: Float = 0.0
        for result in allRoundsResults {
            let accuracy = (Float(result.roundResult) / Float(questionsAmount)) * 100
            totalAccuracy += accuracy
        }
        
        let persent = totalAccuracy / Float(allRoundsResults.count)
        return  Int(round(persent)) /// округляем от лишних знаков после запятой | пришлось помучаться в гугле ради этого решения :)
    }
    
    private func findRecordedResult() -> QuizResultsModel {
        var bestRound = allRoundsResults[0]
        
        for round in allRoundsResults {
            if round.roundResult > bestRound.roundResult {
                bestRound = round
            }
        }
        
        return bestRound
    }
    
    private func showResultAlert(quiz result: QuizResultsViewModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            questionFactory?.requestNextQuestion()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func switchButtonVisability(wantToHide: Bool) {
        noButton.isEnabled = !wantToHide
        yesButton.isEnabled = !wantToHide
        noButton.layer.opacity = wantToHide ? 0.5 : 1
        yesButton.layer.opacity = wantToHide ? 0.5 : 1
    }
}

// MARK: - Свой класс (возможно надо удалить)
// TODO: Обязательно перенести этот класс в отдельный файл, пока не знаю нужен ли он вообще, может удалить придется...
// класс для хранения результатов теста
final class QuizResultsModel {
    var roundResult: Int
    var roundDate: Date?
    
    init() {
        self.roundResult = 0
        self.roundDate = nil
    }
    
    init(roundResult: Int, roundDate: Date) {
        self.roundResult = roundResult
        self.roundDate = roundDate
    }
}
