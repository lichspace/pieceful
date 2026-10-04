import SpriteKit

final class EffectsManager {
    func pickup(on scene: SKScene, at point: CGPoint, enabled: Bool) {
        guard enabled else { return }
        for index in 0..<2 {
            let ring = SKShapeNode(circleOfRadius: 13)
            ring.position = point
            ring.strokeColor = index == 0
                ? SKColor(red: 0.96, green: 0.76, blue: 0.36, alpha: 0.78)
                : SKColor(red: 0.73, green: 0.86, blue: 0.60, alpha: 0.52)
            ring.lineWidth = index == 0 ? 2.2 : 1.2
            ring.fillColor = .clear
            ring.zPosition = 245
            ring.setScale(0.5)
            scene.addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(index) * 0.045),
                .group([.scale(to: 2.35 + CGFloat(index) * 0.35, duration: 0.25), .fadeOut(withDuration: 0.25)]),
                .removeFromParent()
            ]))
        }
    }

    func targetPreview(on scene: SKScene, at point: CGPoint, size: CGSize, enabled: Bool) {
        guard enabled else { return }
        let span = max(18, min(size.width, size.height))
        let halo = SKShapeNode(circleOfRadius: span * 0.22)
        halo.position = point
        halo.fillColor = SKColor(red: 0.98, green: 0.78, blue: 0.40, alpha: 0.07)
        halo.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.58, alpha: 0.58)
        halo.lineWidth = max(1.2, min(2.2, span * 0.035))
        halo.zPosition = 248
        halo.setScale(0.72)
        scene.addChild(halo)
        halo.run(.sequence([
            .group([.scale(to: 1.45, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent()
        ]))
    }

    func snap(on scene: SKScene, at point: CGPoint, size: CGSize, enabled: Bool) {
        guard enabled else { return }
        let span = max(18, min(size.width, size.height))

        let bloom = SKShapeNode(circleOfRadius: span * 0.22)
        bloom.position = point
        bloom.fillColor = SKColor(red: 1.0, green: 0.82, blue: 0.48, alpha: 0.19)
        bloom.strokeColor = .clear
        bloom.blendMode = .add
        bloom.zPosition = 249
        bloom.setScale(0.16)
        scene.addChild(bloom)
        bloom.run(.sequence([
            .group([.scale(to: 1.0, duration: 0.12), .fadeOut(withDuration: 0.29)]),
            .removeFromParent()
        ]))

        for index in 0..<2 {
            let radius = span * (index == 0 ? 0.18 : 0.27)
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = point
            ring.strokeColor = index == 0
                ? SKColor(red: 1.0, green: 0.83, blue: 0.48, alpha: 0.94)
                : SKColor(red: 0.98, green: 0.94, blue: 0.78, alpha: 0.58)
            ring.lineWidth = index == 0 ? max(1.7, span * 0.045) : max(1.1, span * 0.028)
            ring.fillColor = .clear
            ring.zPosition = 250
            ring.setScale(index == 0 ? 0.68 : 0.52)
            scene.addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(index) * 0.075),
                .group([
                    .scale(to: index == 0 ? 1.95 : 1.52, duration: 0.34),
                    .fadeOut(withDuration: 0.34)
                ]),
                .removeFromParent()
            ]))
        }

        for index in 0..<6 {
            let angle = CGFloat(index) * (.pi / 3) + .pi / 6
            let starRadius = max(1.5, min(3.4, span * 0.045))
            let spark = SKShapeNode(path: starPath(outerRadius: starRadius, innerRadius: starRadius * 0.42))
            spark.position = point
            spark.fillColor = index.isMultiple(of: 2)
                ? .white
                : SKColor(red: 1.0, green: 0.80, blue: 0.43, alpha: 1)
            spark.strokeColor = .clear
            spark.blendMode = .add
            spark.zPosition = 251
            scene.addChild(spark)
            let distance = span * (0.30 + CGFloat(index % 2) * 0.06)
            let destination = CGPoint(x: point.x + cos(angle) * distance, y: point.y + sin(angle) * distance)
            let travel = SKAction.move(to: destination, duration: 0.29)
            travel.timingMode = .easeOut
            spark.run(.sequence([
                .group([travel, .scale(to: 0.18, duration: 0.29), .fadeOut(withDuration: 0.29)]),
                .removeFromParent()
            ]))
        }
    }

    func settle(on scene: SKScene, at point: CGPoint, enabled: Bool) {
        guard enabled else { return }
        let ring = SKShapeNode(ellipseOf: CGSize(width: 23, height: 11))
        ring.position = CGPoint(x: point.x, y: point.y - 5)
        ring.strokeColor = SKColor(red: 0.83, green: 0.75, blue: 0.54, alpha: 0.65)
        ring.lineWidth = 1.5
        ring.fillColor = .clear
        ring.zPosition = 240
        ring.setScale(0.55)
        scene.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.8, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))
    }

    func celebrate(on scene: SKScene, enabled: Bool) {
        guard enabled else { return }
        let colors: [SKColor] = [
            SKColor(red: 1.00, green: 0.82, blue: 0.27, alpha: 1),
            SKColor(red: 1.00, green: 0.40, blue: 0.46, alpha: 1),
            SKColor(red: 0.28, green: 0.84, blue: 0.80, alpha: 1),
            SKColor(red: 1.00, green: 0.59, blue: 0.26, alpha: 1),
            SKColor(red: 0.55, green: 0.83, blue: 0.38, alpha: 1),
            SKColor(red: 0.76, green: 0.54, blue: 1.00, alpha: 1)
        ]

        let center = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.52)
        let flash = SKShapeNode(rectOf: scene.size)
        flash.position = center
        flash.fillColor = SKColor(red: 1, green: 0.88, blue: 0.52, alpha: 0.22)
        flash.strokeColor = .clear
        flash.zPosition = 900
        scene.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.48), .removeFromParent()]))

        for index in 0..<4 {
            let ring = SKShapeNode(circleOfRadius: 36)
            ring.position = center
            ring.strokeColor = colors[index % colors.count].withAlphaComponent(0.9)
            ring.lineWidth = 5 - CGFloat(index) * 0.65
            ring.fillColor = .clear
            ring.alpha = 0
            ring.zPosition = 920
            ring.setScale(0.12)
            scene.addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(index) * 0.16),
                .group([
                    .fadeAlpha(to: 0.9, duration: 0.08),
                    .scale(to: 4.8 + CGFloat(index) * 0.35, duration: 0.9)
                ]),
                .fadeOut(withDuration: 0.48),
                .removeFromParent()
            ]))
        }

        let spread = min(scene.size.width, scene.size.height)
        for cannon in 0..<2 {
            let origin = CGPoint(x: cannon == 0 ? scene.size.width * 0.035 : scene.size.width * 0.965, y: scene.size.height * 0.10)
            for index in 0..<38 {
                let fraction = CGFloat((index * 37 + cannon * 19) % 101) / 100
                let angle = cannon == 0
                    ? CGFloat.pi * (0.12 + fraction * 0.31)
                    : CGFloat.pi * (0.57 - fraction * 0.31)
                let distance = spread * (0.66 + fraction * 0.34)
                let peak = CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance)
                let landing = CGPoint(x: peak.x + (cannon == 0 ? 1 : -1) * spread * (0.08 + fraction * 0.08), y: peak.y - spread * (0.15 + fraction * 0.08))
                let confetti = celebrationParticle(index: index + cannon * 11, color: colors[(index + cannon * 2) % colors.count])
                confetti.position = origin
                confetti.zPosition = 940
                confetti.zRotation = CGFloat(index) * 0.37
                scene.addChild(confetti)

                let rise = SKAction.move(to: peak, duration: 0.78 + Double(fraction) * 0.28)
                rise.timingMode = .easeOut
                let fall = SKAction.group([
                    .move(to: landing, duration: 1.45 + Double(fraction) * 0.45),
                    .rotate(byAngle: CGFloat.pi * (2 + fraction * 2), duration: 1.75),
                    .fadeOut(withDuration: 1.9)
                ])
                confetti.run(.sequence([
                    .wait(forDuration: Double(index % 7) * 0.018),
                    rise,
                    fall,
                    .removeFromParent()
                ]))
            }
        }

        let bursts: [(CGPoint, SKColor, TimeInterval)] = [
            (CGPoint(x: scene.size.width * 0.27, y: scene.size.height * 0.72), colors[0], 0.18),
            (CGPoint(x: scene.size.width * 0.73, y: scene.size.height * 0.76), colors[2], 0.42),
            (CGPoint(x: scene.size.width * 0.51, y: scene.size.height * 0.82), colors[1], 0.68)
        ]
        for (origin, color, delay) in bursts {
            fireworkBurst(on: scene, at: origin, color: color, delay: delay, radius: spread * 0.13)
        }
    }

    private func celebrationParticle(index: Int, color: SKColor) -> SKShapeNode {
        let size = CGSize(width: 6 + CGFloat(index % 4) * 1.5, height: 10 + CGFloat(index % 5) * 1.4)
        let particle: SKShapeNode
        switch index % 4 {
        case 0:
            particle = SKShapeNode(ellipseOf: size)
        case 1:
            particle = SKShapeNode(path: starPath(outerRadius: size.height * 0.56, innerRadius: size.height * 0.25))
        case 2:
            particle = SKShapeNode(rectOf: size, cornerRadius: 2)
        default:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size.height * 0.5))
            path.addLine(to: CGPoint(x: size.width * 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -size.height * 0.5))
            path.addLine(to: CGPoint(x: -size.width * 0.5, y: 0))
            path.closeSubpath()
            particle = SKShapeNode(path: path)
        }
        particle.fillColor = color
        particle.strokeColor = color.withAlphaComponent(0.72)
        particle.lineWidth = 0.7
        return particle
    }

    private func fireworkBurst(on scene: SKScene, at origin: CGPoint, color: SKColor, delay: TimeInterval, radius: CGFloat) {
        let core = SKShapeNode(circleOfRadius: 12)
        core.position = origin
        core.fillColor = color
        core.strokeColor = .white
        core.lineWidth = 2
        core.alpha = 0
        core.zPosition = 960
        core.setScale(0.1)
        scene.addChild(core)
        core.run(.sequence([
            .wait(forDuration: delay),
            .group([.fadeAlpha(to: 1, duration: 0.08), .scale(to: 2.2, duration: 0.16)]),
            .fadeOut(withDuration: 0.24),
            .removeFromParent()
        ]))

        for index in 0..<20 {
            let angle = CGFloat(index) * (.pi * 2 / 20)
            let reach = radius * (0.72 + CGFloat((index * 13) % 7) * 0.07)
            let destination = CGPoint(x: origin.x + cos(angle) * reach, y: origin.y + sin(angle) * reach)
            let spark = SKShapeNode(ellipseOf: CGSize(width: index.isMultiple(of: 3) ? 7 : 4, height: index.isMultiple(of: 3) ? 7 : 4))
            spark.position = origin
            spark.fillColor = index.isMultiple(of: 4) ? .white : color
            spark.strokeColor = .clear
            spark.zPosition = 955
            scene.addChild(spark)
            let travel = SKAction.move(to: destination, duration: 0.68 + Double(index % 5) * 0.035)
            travel.timingMode = .easeOut
            spark.run(.sequence([
                .wait(forDuration: delay),
                .group([travel, .scale(to: 0.15, duration: 0.8), .fadeOut(withDuration: 0.8)]),
                .removeFromParent()
            ]))
        }
    }

    private func starPath(outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for point in 0..<10 {
            let angle = CGFloat(point) * (.pi / 5) - .pi / 2
            let radius = point.isMultiple(of: 2) ? outerRadius : innerRadius
            let position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if point == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        path.closeSubpath()
        return path
    }
}
