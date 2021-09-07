//
//  ProductCell.swift
//  OpenMarket
//
//  Created by tae hoon park on 2021/09/04.
//

import UIKit

class ProductCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var discountedPriceLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!
    
    private let imageManager = ImageManager()
    private static let maximumStockAmount = 999
    static let listIdentifier = "ProductListCell"
    static let gridItentifier = "ProductGridCell"
    static let listNibName = "ProductListCell"
    static let gridNibName = "ProductGridCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.gray.cgColor
        titleLabel.adjustsFontSizeToFitWidth = true
        priceLabel.adjustsFontSizeToFitWidth = true
        discountedPriceLabel.adjustsFontSizeToFitWidth = true
        stockLabel.adjustsFontSizeToFitWidth = true
    }
    
    func imageConfigure(product: Product) {
        if let successImage = product.thumbnails.first {
            imageManager.loadedImage(url: successImage) { image in
                DispatchQueue.main.async {
                    switch image {
                    case .success(let image):
                        self.imageView.image = image
                    case .failure:
                        self.imageView.image = #imageLiteral(resourceName: "LoadedImageFailed")
                    }
                }
            }
        }
    }
    
    func textConfigure(product: Product) {
        self.titleLabel.text = product.title
        
        if let discountedPrice = product.discountedPrice {
            priceLabel.attributedText = "\(product.currency) \(product.price.withComma)".strikeThrough
            priceLabel.textColor = .red
            discountedPriceLabel.text = "\(product.currency) \(discountedPrice.withComma)"
        } else {
            priceLabel.text = "\(product.currency) \(product.price.withComma)"
            priceLabel.textColor = .gray
            discountedPriceLabel.text = nil
        }
        
        if product.stock == .zero {
            stockLabel.text = "품절"
            stockLabel.textColor = .orange
        } else if product.stock > Self.maximumStockAmount {
            stockLabel.text = "잔여수량 : \(Self.maximumStockAmount) +"
        } else {
            stockLabel.text = "잔여수량 : \(product.stock)"
        }
    }
    
    override func prepareForReuse() {
        priceLabel.attributedText = nil
        priceLabel.textColor = nil
        stockLabel.textColor = nil
        imageView.image = nil
    }
}
