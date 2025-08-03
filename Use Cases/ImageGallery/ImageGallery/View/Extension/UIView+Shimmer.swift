//
//  UIView+Shimmer.swift
//  ImageGallery
//
//  Created by Leonardo Maldonado on 4/27/25.
//

import UIKit

extension UIView {
    private static var shimmerLayerKey: UInt8 = 0
    
    private var shimmerLayer: CAGradientLayer? {
        get {
            return objc_getAssociatedObject(self, &UIView.shimmerLayerKey) as? CAGradientLayer
        }
        set {
            objc_setAssociatedObject(self, &UIView.shimmerLayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func startShimmer() {
        stopShimmer()
        
        guard bounds.width > 0 && bounds.height > 0 else {
            // Retry after next layout cycle if bounds aren't ready
            DispatchQueue.main.async { [weak self] in
                self?.startShimmer()
            }
            return
        }
        
        let shimmer = CAGradientLayer()
        
        shimmer.colors = [
            UIColor.systemGray6.withAlphaComponent(0.3).cgColor,
            UIColor.systemGray4.withAlphaComponent(0.8).cgColor,
            UIColor.systemGray6.withAlphaComponent(0.3).cgColor
        ]
        
        shimmer.locations = [0.0, 0.5, 1.0]
        
        let baseSize = max(bounds.width, bounds.height)
        let expandedSize = baseSize * 2.5  // Expand by 2.5x
        
        shimmer.frame = CGRect(
            x: -expandedSize / 2 + bounds.width / 2,
            y: -expandedSize / 2 + bounds.height / 2,
            width: expandedSize,
            height: expandedSize
        )
        
        shimmer.startPoint = CGPoint(x: 0, y: 0)
        shimmer.endPoint = CGPoint(x: 1, y: 1)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        shimmer.add(animation, forKey: "shimmer")
        layer.addSublayer(shimmer)
        
        self.shimmerLayer = shimmer
    }
    
    func stopShimmer() {
        shimmerLayer?.removeFromSuperlayer()
        shimmerLayer = nil
    }
    
    func updateShimmerFrame() {
        guard let shimmer = shimmerLayer else { return }
        
        let baseSize = max(bounds.width, bounds.height)
        let expandedSize = baseSize * 2.5
        
        shimmer.frame = CGRect(
            x: -expandedSize / 2 + bounds.width / 2,
            y: -expandedSize / 2 + bounds.height / 2,
            width: expandedSize,
            height: expandedSize
        )
    }
} 
