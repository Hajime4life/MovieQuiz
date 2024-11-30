import UIKit

final class ResultAlertPresenter: AlertPresenterProtocol {
    
    weak var delegate: QuestionFactoryDelegate?
    
    func show(parentController: UIViewController, alertData: AlertModel) {
        let alert = UIAlertController (
            title: alertData.title,
            message: alertData.message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(title: alertData.buttonText, style: .default) { [weak self] _ in
            guard self != nil else { return }
            
            alertData.completion()
        }
        alert.addAction(action)
        parentController.present(alert, animated: true, completion: nil)
    }
}
