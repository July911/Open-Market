import UIKit

class RegisterImageView: UIView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutCollectionViewCell()
    }
    
    lazy var addIndicaterButton: UIButton = {
        var button = UIButton(type: .contactAdd)
        return button
    }()
    
    lazy var productEnrollImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = .systemGray
        return imageView
    }()
    
    private func layoutCollectionViewCell() {
        self.addSubview(productEnrollImageView)
        self.addSubview(addIndicaterButton)
        
        addIndicaterButton.translatesAutoresizingMaskIntoConstraints = false
        productEnrollImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            productEnrollImageView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor),
            productEnrollImageView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor),
            productEnrollImageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            productEnrollImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            addIndicaterButton.centerXAnchor.constraint(equalTo: productEnrollImageView.centerXAnchor),
            addIndicaterButton.centerYAnchor.constraint(equalTo: productEnrollImageView.centerYAnchor)
        ])
    }
}
