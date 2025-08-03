//
//  ImageGalleryCell.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 4/27/25.
//

import UIKit

class ImageGalleryCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: ImageGalleryCell.self)

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.updateShimmerFrame()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        showShimmerPlaceholder()
    }

    func configure(with media: Media) {
        if let data = media.data {
            hideShimmer()
            imageView.image = UIImage(data: data)
        } else {
            showShimmerPlaceholder()
        }
    }
    
    // MARK: - Loading State Methods
    
    private func showShimmerPlaceholder() {
        imageView.backgroundColor = .systemGray6
        imageView.image = nil
        imageView.startShimmer()
    }
    
    private func hideShimmer() {
        imageView.stopShimmer()
        imageView.backgroundColor = .clear
    }
}
