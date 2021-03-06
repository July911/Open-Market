import Foundation

enum ProductPost {
    struct Request: Encodable {
        struct Params: Encodable {
            let name: String
            let descriptions: String
            let price: Decimal
            let currency: Currency
            let discountedPrice: Decimal?
            let stock: Int?
            let secret: String
            
            enum CodingKeys: String, CodingKey {
                case name, descriptions, price, currency, stock, secret
                case discountedPrice = "discounted_price"
            }
        }
    }
    
    struct Response: Decodable {
        let id: Int
        let vendorId: Int
        let name: String
        let thumbnail: String
        let currency: Currency
        let price: Decimal
        let bargainPrice: Decimal
        let discountedPrice: Decimal
        let stock: Int
        let images: [Image]
        let vendors: Vendor
        let createdAt: String
        let issuedAt: String

        enum CodingKeys: String, CodingKey {
            case id, name, thumbnail, currency, price, stock, images, vendors
            case vendorId = "vendor_id"
            case bargainPrice = "bargain_price"
            case discountedPrice = "discounted_price"
            case createdAt = "created_at"
            case issuedAt = "issued_at"
        }
        
        struct Image: Decodable {
            let id: Int
            let url: String
            let thumbnailUrl: String
            let succeed: Bool
            let issuedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id, url, succeed
                case thumbnailUrl = "thumbnail_url"
                case issuedAt = "issued_at"
            }
        }
        
        struct Vendor: Decodable {
            let name: String
            let id: Int
            let createdAt: String
            let issuedAt: String
            
            enum CodingKeys: String, CodingKey {
                case name, id
                case createdAt = "created_at"
                case issuedAt = "issued_at"
            }
        }
    }
}


