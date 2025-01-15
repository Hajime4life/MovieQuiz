import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
        
    // MARK: - outlet's
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - private vars
    private var questionFactory: QuestionFactoryProtocol?
    private var statisticService: StatisticService?
    private var presenter: MovieQuizPresenterProtocol?
    
    // MARK: - public vars
    var alertPresenter: AlertPresenterProtocol?
    
    // MARK: - overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        // Инициализация необходимых вьюшек
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.contentMode = .scaleToFill
        
        // Подключаем алерты
        alertPresenter = ResultAlertPresenter()
        
        // Подключаем статистику
        statisticService = StatisticService()
        
        // Инициализируем первый вопрос
        showLoadingIndicator()
        questionFactory?.loadData()
        
        // Инициализация презентора
        presenter = MovieQuizPresenter(viewController: self)
    }
    
    // MARK: - actions
    @IBAction private func onNoClicked() {
        switchButtonVisability(wantToHide: true)
        presenter?.noButtonClicked()
    }
    
    @IBAction private func onYesClicked() {
        switchButtonVisability(wantToHide: true)
        presenter?.yesButtonClicked()
    }
    
    // MARK: - public methods
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        alertPresenter?.show(parentController: self, alertData: setNetworkErrorAlertModel(errorMessage: message))
        self.presenter?.restartGame()
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func show(quiz result: QuizResultsViewModel) {
        guard let message = presenter?.makeResultsMessage() else { return }
        
        let alert = UIAlertController(
            title: result.title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.view.accessibilityIdentifier = "Game results"
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.presenter?.restartGame()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    func clearImageBorder() {
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func switchButtonVisability(wantToHide: Bool) {
        noButton.isEnabled = !wantToHide
        yesButton.isEnabled = !wantToHide
        noButton.layer.opacity = wantToHide ? 0.5 : 1
        yesButton.layer.opacity = wantToHide ? 0.5 : 1
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        switchButtonVisability(wantToHide: true)
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        switchButtonVisability(wantToHide: false)
    }
    
    func reloadView() {
        self.viewDidLoad()
    }
    
    // MARK: - private methods
    private func setNetworkErrorAlertModel(errorMessage: String) -> AlertModel {
        let model = AlertModel(title: "Ошибка", message: errorMessage, buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            presenter?.restartGame()
        }
        return model
    }
}
