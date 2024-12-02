import Foundation

typealias VoidClosure = () -> () // для добавление клоужеров в методы

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: VoidClosure
}
