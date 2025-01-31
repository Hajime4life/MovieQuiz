import UIKit

final class ResultAlertPresenter: AlertPresenterProtocol {
    
    func show(parentController: UIViewController, alertData: AlertModel) {
        let alert = UIAlertController (
            title: alertData.title,
            message: alertData.message,
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = "Game results"
        let action = UIAlertAction(title: alertData.buttonText, style: .default) { [weak self] _ in
            guard self != nil else { return }
            alertData.completion()
        }
        alert.addAction(action)
        parentController.present(alert, animated: true, completion: nil)
    }
}
