import Foundation

struct MOAResponse: Decodable {
    let RS: String
    let Data: [MOARow]?
}

struct MOARow: Decodable {
    let TransDate: String
    let CropCode: String
    let CropName: String
    let MarketCode: String?
    let MarketName: String
    let Upper_Price: Double?
    let Middle_Price: Double?
    let Lower_Price: Double?
    let Avg_Price: Double?
    let Trans_Quantity: Double?
}
