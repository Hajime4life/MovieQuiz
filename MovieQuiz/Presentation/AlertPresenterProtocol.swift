import UIKit

protocol AlertPresenterProtocol {
    func show(parentController: UIViewController, alertData: AlertModel)
}
