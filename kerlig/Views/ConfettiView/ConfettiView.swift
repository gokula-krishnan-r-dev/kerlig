import SwiftUI
import AppKit
import AVFoundation

// MARK: - Confetti Direction Enum
enum ConfettiDirection {
    case left, right, top, bothSides
}

// MARK: - Confetti View
struct ConfettiView: NSViewRepresentable {
    var isActive: Bool
    var direction: ConfettiDirection
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isActive {
            addConfettiAnimation(to: nsView)
        } else {
            removeConfettiAnimation(from: nsView)
        }
    }
    
    private func addConfettiAnimation(to view: NSView) {
        removeConfettiAnimation(from: view)
        
        // Entry animation (bounce in)
        let bounce = CABasicAnimation(keyPath: "transform.scale")
        bounce.fromValue = 0.7
        bounce.toValue = 1.0
        bounce.duration = 0.25
        bounce.timingFunction = CAMediaTimingFunction(name: .easeOut)
        view.layer?.add(bounce, forKey: "bounceIn")
        
        switch direction {
        case .top:
            addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width / 2, y: view.bounds.height + 10), isTopEmitter: true)
        case .left:
            addEmitterLayer(to: view, position: CGPoint(x: 0, y: view.bounds.height * 0.7), isTopEmitter: false, isLeftSide: true)
        case .right:
            addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width, y: view.bounds.height * 0.7), isTopEmitter: false, isLeftSide: false)
        case .bothSides:
            // Top emitters
            addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width / 2, y: view.bounds.height + 10), isTopEmitter: true)
        }

        // Optional: Play confetti sound
        playConfettiSound()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            removeConfettiAnimation(from: view)
        }
    }
    
    private func addEmitterLayer(to view: NSView, position: CGPoint, isTopEmitter: Bool = true, isLeftSide: Bool = false) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = position
        
        emitter.emitterShape = isTopEmitter ? .line : .point
        emitter.emitterSize = isTopEmitter ?
            CGSize(width: view.bounds.width / 3, height: 1) :
            CGSize(width: 1, height: 100)
        
        emitter.renderMode = .additive
        emitter.name = "confettiLayer"
        
        // Create colorful cells
        let colors: [NSColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange, .systemTeal, .systemPink]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 15
            cell.lifetime = 10
            cell.lifetimeRange = 3
            cell.velocity = CGFloat.random(in: 180...250)
            cell.velocityRange = 50
            cell.spin = CGFloat.random(in: 2...5)
            cell.spinRange = 2
            cell.scaleRange = 0.25
            cell.scaleSpeed = -0.1
            cell.yAcceleration = CGFloat.random(in: 50...100)
            cell.xAcceleration = CGFloat.random(in: -20...20)
            
            if isTopEmitter {
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi / 3
            } else {
                cell.emissionRange = .pi / 2
                cell.emissionLongitude = isLeftSide ? 0 : .pi
            }
            
            cell.contents = createConfettiShape(with: color)
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        view.wantsLayer = true
        view.layer?.addSublayer(emitter)
    }
    
    private func createConfettiShape(with color: NSColor) -> CGImage? {
        let size = CGSize(width: CGFloat.random(in: 8...15), height: CGFloat.random(in: 8...15))
        let image = NSImage(size: size)
        image.lockFocus()
        
        color.set()
        let shapeType = Int.random(in: 0...4)
        switch shapeType {
        case 0:
            NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        case 1:
            NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        case 2:
            let path = NSBezierPath()
            path.move(to: NSPoint(x: size.width/2, y: 0))
            path.line(to: NSPoint(x: size.width, y: size.height))
            path.line(to: NSPoint(x: 0, y: size.height))
            path.close()
            path.fill()
        case 3:
            drawStar(in: NSRect(origin: .zero, size: size))
        case 4:
            drawHeart(in: NSRect(origin: .zero, size: size))
        default:
            break
        }
        
        image.unlockFocus()
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    private func drawStar(in rect: NSRect) {
        let path = NSBezierPath()
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        let points = 5
        var angle = -CGFloat.pi / 2
        let increment = .pi * 2 / CGFloat(points)
        
        path.move(to: NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        
        for _ in 0..<points {
            angle += increment / 2
            path.line(to: NSPoint(x: center.x + innerRadius * cos(angle), y: center.y + innerRadius * sin(angle)))
            angle += increment / 2
            path.line(to: NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        }
        
        path.close()
        path.fill()
    }
    
    private func drawHeart(in rect: NSRect) {
        let path = NSBezierPath()
        let width = rect.width
        let height = rect.height
        
        path.move(to: NSPoint(x: width/2, y: 0))
        
        path.curve(to: NSPoint(x: 0, y: height/3),
                   controlPoint1: NSPoint(x: width/4, y: 0),
                   controlPoint2: NSPoint(x: 0, y: height/6))
        
        path.curve(to: NSPoint(x: width/2, y: height),
                   controlPoint1: NSPoint(x: 0, y: height*2/3),
                   controlPoint2: NSPoint(x: width/4, y: height))
        
        path.curve(to: NSPoint(x: width, y: height/3),
                   controlPoint1: NSPoint(x: width*3/4, y: height),
                   controlPoint2: NSPoint(x: width, y: height*2/3))
        
        path.curve(to: NSPoint(x: width/2, y: 0),
                   controlPoint1: NSPoint(x: width, y: height/6),
                   controlPoint2: NSPoint(x: width*3/4, y: 0))
        
        path.close()
        path.fill()
    }
    
    private func removeConfettiAnimation(from view: NSView) {
        view.layer?.sublayers?.removeAll(where: { $0.name == "confettiLayer" })
    }

    private func playConfettiSound() {
        guard let soundURL = Bundle.main.url(forResource: "confetti", withExtension: "mp3") else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}
