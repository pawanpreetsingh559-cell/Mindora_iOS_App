import UIKit

@IBDesignable
class CircularProgressView: UIView {
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    @IBInspectable var progressColor: UIColor = .systemBlue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    @IBInspectable var trackColor: UIColor = .secondarySystemFill {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 8.0 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        
        transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        
        layer.addSublayer(progressLayer)
    }
    
    // MARK: - Interface Builder Support
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        // Show a default 50% progress for IB preview
        setProgress(0.5, animated: false)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        let clampedProgress = max(0, min(progress, 1.0))
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = clampedProgress
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.strokeEnd = CGFloat(clampedProgress)
            progressLayer.add(animation, forKey: "animateProgress")
        } else {
            progressLayer.strokeEnd = CGFloat(clampedProgress)
        }
    }
}
