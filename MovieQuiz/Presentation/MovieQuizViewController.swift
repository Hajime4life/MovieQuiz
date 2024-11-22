import UIKit

final class MovieQuizViewController: UIViewController {
    private let questions: [QuizQuestion] = [
        QuizQuestion(
            image: "The Godfather",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Dark Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Kill Bill",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Avengers",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Deadpool",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Green Knight",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Old",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "The Ice Age Adventures of Buck Wild",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Tesla",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Vivarium",
            text: "Рейтинг этого фильма больше чем 6?",
            correctAnswer: false)
    ]
    private var allRoundsResults: [QuizResultsModel] = []

    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var lastRoundResult: QuizResultsModel? = nil
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        show(quiz: convert(model: questions[currentQuestionIndex]))
        
        // Скругляем края при инициализации View
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
    }
    
    @IBAction private func onNoClicked() {
        showAnswerResult(isCorrect: true == questions[currentQuestionIndex].correctAnswer)
    }
    
    @IBAction private func onYesClicked() {
        showAnswerResult(isCorrect: false == questions[currentQuestionIndex].correctAnswer)
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questions.count)"
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
            self.switchButtonVisability(wantToHide: false)
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 { /// раунд завершен
            lastRoundResult = QuizResultsModel(roundResult: correctAnswers, roundDate: Date())
            allRoundsResults.append(lastRoundResult!)
            
            var text = ""
            
            if allRoundsResults.count <= 1 {
                text = "Ваш результат: \(correctAnswers)/\(questions.count)"
            } else {
                let bestRound = findRecordedResult()
                text = """
                Ваш результат: \(correctAnswers)/\(questions.count)
                Количество сыгранных квизов: \(allRoundsResults.count)
                Рекорд: \(bestRound.roundResult)/\(questions.count) (\(bestRound.roundDate?.dateTimeString ?? ""))
                Средняя точность:\(countMiddleResult())%
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
            show(quiz: convert(model: questions[currentQuestionIndex]))
        }
    }
    
    private func countMiddleResult() -> Int {
        guard questions.count != 0 else { return 0 }
        var totalAccuracy: Float = 0.0
        for result in allRoundsResults {
            let accuracy = (Float(result.roundResult) / Float(questions.count)) * 100
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
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { _ in
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            let firstQuestion = self.questions[self.currentQuestionIndex]
            let viewModel = self.convert(model: firstQuestion)
            self.show(quiz: viewModel)
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

struct QuizQuestion {
    let image: String
    let text: String // строка с вопросом о рейтинге фильма
    let correctAnswer: Bool // булевое значение (true, false), правильный ответ на вопрос
}

// вью модель для состояния "Вопрос показан"
struct QuizStepViewModel {
    let image: UIImage // картинка с афишей фильма с типом UIImage
    let question: String // вопрос о рейтинге квиза
    let questionNumber: String
}

struct QuizResultsViewModel {
    let title: String // строка с заголовком алерта
    let text: String  // строка с текстом о количестве набранных очков
    let buttonText: String  // текст для кнопки алерта
}

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
