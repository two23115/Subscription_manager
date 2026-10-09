import Foundation

extension Double {
    var yenText: String {
        formatted(.currency(code: "JPY").precision(.fractionLength(0)))
    }
}

extension Date {
    var shortDateText: String {
        formatted(.dateTime.month().day())
    }

    var fullDateText: String {
        formatted(.dateTime.year().month().day())
    }
}
