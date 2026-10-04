import CoreGraphics
import Foundation
import SpriteKit

#if os(iOS) || os(tvOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum PuzzleCanvasMode {
    case vertical
    case horizontal
}

private enum TrayScrollArrow: Equatable {
    case up
    case down
}

struct PuzzleCanvasLayout {
    let boardRect: CGRect
    let trayRect: CGRect
    let mode: PuzzleCanvasMode
}

private func makeCanvasLayout(size: CGSize) -> PuzzleCanvasLayout {
    let width = max(1, size.width)
    let height = max(1, size.height)
    if width > 720 && width > height * 1.12 {
        let boardSide = min(width * 0.61, height - 44)
        let board = CGRect(
            x: 28,
            y: (height - boardSide) * 0.5,
            width: boardSide,
            height: boardSide
        )
        let tray = CGRect(x: board.maxX + 34, y: 20, width: max(1, width - board.maxX - 58), height: height - 40)
        return PuzzleCanvasLayout(boardRect: board, trayRect: tray, mode: .horizontal)
    }

    let trayHeight = max(172, height * 0.34)
    let boardHeight = max(80, height - trayHeight - 44)
    let boardSide = min(width - 32, boardHeight)
    let board = CGRect(
        x: (width - boardSide) * 0.5,
        y: trayHeight + 28,
        width: boardSide,
        height: boardSide
    )
    let tray = CGRect(x: 14, y: 12, width: width - 28, height: trayHeight - 14)
    return PuzzleCanvasLayout(boardRect: board, trayRect: tray, mode: .vertical)
}

private struct JigsawEdge {
    let start: CGPoint
    let end: CGPoint
    let outward: Int
    let seed: UInt64
    let reversed: Bool

    var normal: CGPoint {
        let length = hypot(end.x - start.x, end.y - start.y)
        guard length > 0 else { return .zero }
        return CGPoint(x: (end.y - start.y) / length, y: (start.x - end.x) / length)
    }
}

private struct JigsawCurve {
    let start: CGPoint
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint
}

private func appendJigsawEdge(_ path: CGMutablePath, edge: JigsawEdge, shortSide: CGFloat) {
    let dx = edge.end.x - edge.start.x
    let dy = edge.end.y - edge.start.y
    let length = hypot(dx, dy)
    guard edge.outward != 0, length > 0 else {
        path.addLine(to: edge.end)
        return
    }

    // Define each seam in one canonical direction, then reverse its actual
    // Bézier segments for the neighbor. Asymmetric tabs still fit exactly.
    func point(_ t: CGFloat, _ depth: CGFloat) -> CGPoint {
        let along = edge.reversed ? 1 - t : t
        return CGPoint(
            x: edge.start.x + dx * along + edge.normal.x * depth * CGFloat(edge.outward),
            y: edge.start.y + dy * along + edge.normal.y * depth * CGFloat(edge.outward)
        )
    }
    func variation(_ shift: Int) -> CGFloat {
        CGFloat((edge.seed >> shift) & 0xFF) / 255
    }

    let center = 0.44 + variation(1) * 0.12
    let radius = shortSide / length * (0.125 + variation(9) * 0.025)
    let neck = radius * (0.48 + variation(17) * 0.12)
    let lean = (variation(25) - 0.5) * 0.045
    let depth = shortSide * (0.24 + variation(33) * 0.055)
    let leftShoulder = shortSide * (variation(41) - 0.5) * 0.055
    let rightShoulder = shortSide * (variation(49) - 0.5) * 0.055
    let leftHead = center + lean - radius
    let rightHead = center + lean + radius
    let crown = center + lean

    // Curved shoulders flow into a soft neck and an oval head. Every join has
    // matching tangent directions, including the two sides of the crown.
    let anchors = [
        point(0, 0),
        point(center - neck, leftShoulder + depth * 0.10),
        point(leftHead, depth * 0.57),
        point(crown, depth),
        point(rightHead, depth * 0.59),
        point(center + neck, rightShoulder + depth * 0.10),
        point(1, 0)
    ]
    let controls: [(CGPoint, CGPoint)] = [
        (point(0.16, -leftShoulder * 1.6), point(center - neck - 0.03, leftShoulder - depth * 0.10)),
        (point(center - neck + 0.03, leftShoulder + depth * 0.30), point(leftHead, depth * 0.22)),
        (point(leftHead, depth * 0.88), point(crown - radius * 0.62, depth)),
        (point(crown + radius * 0.64, depth), point(rightHead, depth * 0.90)),
        (point(rightHead, depth * 0.24), point(center + neck - 0.03, rightShoulder + depth * 0.30)),
        (point(center + neck + 0.03, rightShoulder - depth * 0.10), point(0.84, -rightShoulder * 1.6))
    ]
    let curves = controls.enumerated().map { index, controls in
        JigsawCurve(start: anchors[index], control1: controls.0, control2: controls.1, end: anchors[index + 1])
    }
    if edge.reversed {
        for curve in curves.reversed() {
            path.addCurve(to: curve.start, control1: curve.control2, control2: curve.control1)
        }
    } else {
        for curve in curves {
            path.addCurve(to: curve.end, control1: curve.control1, control2: curve.control2)
        }
    }
}

private func jigsawEdges(size: CGSize, grid: (rows: Int, columns: Int), row: Int, column: Int) -> [JigsawEdge] {
    func seamSeed(_ row: Int, _ column: Int, salt: UInt64) -> UInt64 {
        var value = UInt64(row &* 73856093 ^ column &* 19349663) &+ salt
        value ^= value >> 30
        value &*= 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        value &*= 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
    func edge(_ start: CGPoint, _ end: CGPoint, row: Int, column: Int, salt: UInt64, border: Bool, reversed: Bool = false) -> JigsawEdge {
        let seed = seamSeed(row, column, salt: salt)
        let sign = seed & 1 == 0 ? 1 : -1
        return JigsawEdge(start: start, end: end, outward: border ? 0 : sign * (reversed ? -1 : 1), seed: seed, reversed: reversed)
    }

    let leftBottom = CGPoint(x: -size.width * 0.5, y: -size.height * 0.5)
    let rightBottom = CGPoint(x: size.width * 0.5, y: -size.height * 0.5)
    let rightTop = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    let leftTop = CGPoint(x: -size.width * 0.5, y: size.height * 0.5)
    return [
        edge(leftBottom, rightBottom, row: row + 1, column: column, salt: 0x1A2B, border: row == grid.rows - 1),
        edge(rightBottom, rightTop, row: row, column: column + 1, salt: 0x3C4D, border: column == grid.columns - 1),
        edge(rightTop, leftTop, row: row, column: column, salt: 0x1A2B, border: row == 0, reversed: true),
        edge(leftTop, leftBottom, row: row, column: column, salt: 0x3C4D, border: column == 0, reversed: true)
    ]
}

func piecePath(size: CGSize, grid: (rows: Int, columns: Int), row: Int, column: Int) -> CGPath {
    let edges = jigsawEdges(size: size, grid: grid, row: row, column: column)
    let path = CGMutablePath()
    path.move(to: edges[0].start)
    for edge in edges {
        appendJigsawEdge(path, edge: edge, shortSide: min(size.width, size.height))
    }
    path.closeSubpath()
    return path
}

struct JigsawSeam {
    let path: CGPath
    let outward: Int
    let normal: CGPoint
}

func jigsawSeamPaths(size: CGSize, grid: (rows: Int, columns: Int), row: Int, column: Int) -> [JigsawSeam] {
    jigsawEdges(size: size, grid: grid, row: row, column: column).map { edge in
        let path = CGMutablePath()
        path.move(to: edge.start)
        appendJigsawEdge(path, edge: edge, shortSide: min(size.width, size.height))
        return JigsawSeam(path: path, outward: edge.outward, normal: edge.normal)
    }
}

private func offsetPath(_ path: CGPath, dx: CGFloat, dy: CGFloat) -> CGPath {
    var transform = CGAffineTransform(translationX: dx, y: dy)
    return path.copy(using: &transform) ?? path
}

struct JigsawAssemblyPaths {
    let silhouette: CGPath
    let seams: CGPath
}

func jigsawAssemblyPaths(session: PuzzleSession, boardRect: CGRect, excluding pieceID: String? = nil) -> JigsawAssemblyPaths {
    let grid = session.difficulty.grid
    let cellSize = CGSize(width: boardRect.width / CGFloat(grid.columns), height: boardRect.height / CGFloat(grid.rows))
    let placed = session.pieces.filter { $0.isPlaced && $0.id != pieceID }
    let occupied = Set(placed.map { $0.targetRow * grid.columns + $0.targetColumn })
    let coverage = CGMutablePath()
    let seams = CGMutablePath()
    for piece in placed {
        let row = piece.targetRow
        let column = piece.targetColumn
        let target = PuzzleLayoutGenerator.targetPosition(row: row, column: column, difficulty: session.difficulty, boardRect: boardRect)
        let transform = CGAffineTransform(translationX: target.x, y: target.y)
        coverage.addPath(piecePath(size: cellSize, grid: grid, row: row, column: column), transform: transform)
        let edges = jigsawSeamPaths(size: cellSize, grid: grid, row: row, column: column)
        // Only the upper/left piece owns a joined seam. Empty cells have no lines.
        if row + 1 < grid.rows, occupied.contains((row + 1) * grid.columns + column) {
            seams.addPath(edges[0].path, transform: transform)
        }
        if column + 1 < grid.columns, occupied.contains(row * grid.columns + column + 1) {
            seams.addPath(edges[1].path, transform: transform)
        }
    }
    // Remove internal mask boundaries so the artwork is sampled once across
    // joins, without separate antialiased cutouts exposing the dark backing.
    return JigsawAssemblyPaths(silhouette: coverage.normalized(), seams: seams)
}

private func artworkSprite(texture: SKTexture, boardSize: CGSize) -> SKSpriteNode {
    let image = SKSpriteNode(texture: texture)
    let sourceSize = texture.size()
    let scale = max(boardSize.width / max(sourceSize.width, 1), boardSize.height / max(sourceSize.height, 1))
    image.size = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    return image
}

final class JigsawPieceNode: SKNode {
    let pieceID: String
    private(set) var isLocked = false
    private let crop = SKCropNode()
    private let edge = SKShapeNode()
    private let surface = SKNode()
    private let glow = SKShapeNode()
    private let highlight = SKShapeNode()
    private(set) var isAssembled = false

    var silhouetteBounds: CGRect { edge.path?.boundingBoxOfPath ?? .zero }

    init(pieceID: String, texture: SKTexture, boardSize: CGSize, pieceSize: CGSize, imageOffset: CGPoint, grid: (rows: Int, columns: Int), row: Int, column: Int) {
        self.pieceID = pieceID
        super.init()
        addChild(surface)

        let path = piecePath(size: pieceSize, grid: grid, row: row, column: column)
        let seams = jigsawSeamPaths(size: pieceSize, grid: grid, row: row, column: column)
        let mask = SKShapeNode(path: path)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask

        let image = artworkSprite(texture: texture, boardSize: boardSize)
        image.position = imageOffset
        crop.addChild(image)
        surface.addChild(crop)

        let shadow = SKShapeNode(path: path)
        shadow.position = CGPoint(x: 0, y: -1.5)
        shadow.fillColor = SKColor(white: 0.015, alpha: 0.22)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        surface.addChild(shadow)

        let contactShadowPath = CGMutablePath()
        let bevelHighlightPath = CGMutablePath()
        for seam in seams where seam.outward != 0 {
            let shadowOffset: CGFloat = seam.outward < 0 ? -0.55 : 0.55
            let highlightOffset: CGFloat = seam.outward < 0 ? 0.25 : -0.25
            contactShadowPath.addPath(offsetPath(seam.path, dx: seam.normal.x * shadowOffset, dy: seam.normal.y * shadowOffset))
            bevelHighlightPath.addPath(offsetPath(seam.path, dx: seam.normal.x * highlightOffset, dy: seam.normal.y * highlightOffset))
        }

        let softGroove = SKShapeNode(path: contactShadowPath)
        softGroove.strokeColor = SKColor(red: 0.015, green: 0.035, blue: 0.026, alpha: 0.18)
        softGroove.lineWidth = 1.25
        softGroove.lineCap = .round
        softGroove.lineJoin = .round
        softGroove.fillColor = .clear
        softGroove.zPosition = 1
        surface.addChild(softGroove)

        edge.path = path
        edge.lineWidth = 0.7
        edge.lineJoin = .round
        edge.strokeColor = SKColor(red: 0.045, green: 0.083, blue: 0.064, alpha: 0.48)
        edge.fillColor = .clear
        edge.zPosition = 2
        surface.addChild(edge)

        let bevelHighlight = SKShapeNode(path: bevelHighlightPath)
        bevelHighlight.strokeColor = SKColor(red: 1, green: 0.97, blue: 0.87, alpha: 0.30)
        bevelHighlight.lineWidth = 0.6
        bevelHighlight.lineCap = .round
        bevelHighlight.lineJoin = .round
        bevelHighlight.fillColor = .clear
        bevelHighlight.zPosition = 3
        surface.addChild(bevelHighlight)

        glow.path = path
        glow.strokeColor = SKColor(red: 1.0, green: 0.80, blue: 0.43, alpha: 0.78)
        glow.fillColor = .clear
        glow.lineWidth = 5.5
        glow.lineJoin = .round
        glow.blendMode = .add
        glow.zPosition = 4
        glow.isHidden = true
        addChild(glow)

        highlight.path = path
        highlight.strokeColor = SKColor(red: 0.96, green: 0.76, blue: 0.36, alpha: 1)
        highlight.fillColor = .clear
        highlight.lineWidth = 1.9
        highlight.lineJoin = .round
        highlight.zPosition = 5
        highlight.isHidden = true
        addChild(highlight)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setAssembled(_ assembled: Bool) {
        isAssembled = assembled
        surface.isHidden = assembled
        if assembled {
            removeAction(forKey: "piece-pickup")
            removeAction(forKey: "piece-settle")
            setScale(1)
            zRotation = 0
            zPosition = 2
        }
    }

    func setPlacement(_ placed: Bool) {
        isLocked = placed
        if placed {
            zPosition = 2
            setScale(1)
        } else {
            zPosition = 20
        }
    }

    func setHighlighted(_ highlighted: Bool) {
        highlight.removeAllActions()
        highlight.alpha = 1
        highlight.isHidden = !highlighted
    }

    func highlightPulse() {
        glow.removeAllActions()
        highlight.removeAllActions()
        setHighlighted(true)
        glow.isHidden = false
        glow.alpha = 0
        glow.run(.sequence([
            .fadeAlpha(to: 0.76, duration: 0.075),
            .fadeAlpha(to: 0.42, duration: 0.12),
            .fadeAlpha(to: 0.70, duration: 0.09),
            .fadeOut(withDuration: 0.24),
            .run { [weak self] in self?.glow.isHidden = true }
        ]))
        highlight.run(.sequence([
            .fadeAlpha(to: 0.18, duration: 0.07),
            .fadeAlpha(to: 1, duration: 0.13),
            .wait(forDuration: 0.06),
            .fadeAlpha(to: 0.42, duration: 0.11),
            .fadeAlpha(to: 1, duration: 0.17),
            .run { [weak self] in self?.highlight.isHidden = true }
        ]))
    }

    func pickupPulse(enabled: Bool) {
        guard enabled else { return }
        removeAction(forKey: "piece-settle")
        let restingScale = xScale
        run(.sequence([
            .scale(to: restingScale * 1.08, duration: 0.08),
            .scale(to: restingScale * 1.04, duration: 0.12)
        ]), withKey: "piece-pickup")
    }

    func settlePulse(enabled: Bool) {
        guard enabled else { return }
        removeAction(forKey: "piece-pickup")
        let restingScale = xScale
        setScale(restingScale * 0.91)
        run(.sequence([
            .scale(to: restingScale * 1.045, duration: 0.085),
            .scale(to: restingScale, duration: 0.17)
        ]), withKey: "piece-settle")
    }

    func tiltWhileDragging(horizontalDelta: CGFloat, enabled: Bool) {
        zRotation = enabled ? min(0.075, max(-0.075, horizontalDelta * 0.006)) : 0
    }

    func contains(worldPoint: CGPoint) -> Bool {
        guard let scene, let path = edge.path else { return false }
        return path.contains(convert(worldPoint, from: scene))
    }
}

final class PuzzleBoardScene: SKScene {
    var onDrop: ((String, CGPoint, CGPoint) -> Void)?
    var onPickup: (() -> Void)?
    var onTrayPageChanged: ((Int, Int, Bool) -> Void)?

    private(set) var currentLayout: PuzzleCanvasLayout?
    private(set) var currentTrayPage = 0
    private(set) var trayPageCount = 1
    private var session: PuzzleSession?
    private var definition: PuzzleDefinition?
    private var effectsEnabled = true
    private var pieceNodes: [String: JigsawPieceNode] = [:]
    private var draggedPieceID: String?
    private var inputEnabled = true
    private var dragOffset = CGPoint.zero
    private var nearTarget = false
    private var boardZoom: CGFloat = 1
    private let boardRoot = SKNode()
    private let assembledArtwork = SKNode()
    private let boardClip = SKCropNode()
    private let trayClip = SKCropNode()
    private let trayContent = SKNode()
    private var trayScrollOffset: CGFloat = 0
    private var trayScrollUpButton: SKShapeNode?
    private var trayScrollDownButton: SKShapeNode?
    private var pressedTrayScrollArrow: TrayScrollArrow?
    private let effects = EffectsManager()
    private let hintLayer = SKNode()
    private var lastPanPoint: CGPoint?
    private var lastTrayScrollPoint: CGPoint?
    private var pendingTrayPieceID: String?
    private var pendingTrayTouchStart: CGPoint?
    private var pendingTrayMaxMovement: CGFloat = 0
    private var pendingTrayDragWorkItem: DispatchWorkItem?
    #if os(iOS) || os(tvOS)
    private var twoFingerPanRecognizer: UIPanGestureRecognizer?
    private var pinchRecognizer: UIPinchGestureRecognizer?
    private var isTwoFingerTrayScrolling = false
    private var isTwoFingerBoardPanning = false
    #endif
    #if os(macOS)
    private var macScrollEventMonitor: Any?
    #endif

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        #if os(macOS)
        if let macScrollEventMonitor {
            NSEvent.removeMonitor(macScrollEventMonitor)
        }
        #endif
    }

    func render(session: PuzzleSession, definition: PuzzleDefinition, effectsEnabled: Bool, trayPage: Int) {
        self.session = session
        self.definition = definition
        self.effectsEnabled = effectsEnabled
        self.currentTrayPage = trayPage
        rebuild()
    }

    func resize(to size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        self.size = size
        if session != nil, definition != nil { rebuild() }
    }

    func setInputEnabled(_ enabled: Bool) {
        inputEnabled = enabled
        guard !enabled else { return }
        lastPanPoint = nil
        guard draggedPieceID != nil, let session, let definition else { return }
        draggedPieceID = nil
        render(session: session, definition: definition, effectsEnabled: effectsEnabled, trayPage: currentTrayPage)
    }

    func pulseHint(for pieceID: String) {
        guard let node = pieceNodes[pieceID],
              let piece = session?.pieces.first(where: { $0.id == pieceID }) else { return }
        node.highlightPulse()
        let target = boardRoot.convert(targetLocalPosition(for: piece), to: self)
        effects.snap(on: self, at: target, size: effectSize(for: node), enabled: effectsEnabled)
    }

    func dropFeedback(for pieceID: String, snapped: Bool) {
        guard let node = pieceNodes[pieceID] else { return }
        if snapped {
            node.highlightPulse()
            effects.snap(on: self, at: node.convert(.zero, to: self), size: effectSize(for: node), enabled: effectsEnabled)
        } else {
            node.settlePulse(enabled: effectsEnabled)
            if node.parent === boardRoot {
                effects.settle(on: self, at: node.convert(.zero, to: self), enabled: effectsEnabled)
            }
        }
    }

    private func effectSize(for piece: JigsawPieceNode) -> CGSize {
        CGSize(width: piece.silhouetteBounds.width * boardZoom, height: piece.silhouetteBounds.height * boardZoom)
    }

    func celebrate() { effects.celebrate(on: self, enabled: effectsEnabled) }

    func zoom(by factor: CGFloat) {
        boardZoom = min(2.4, max(1, boardZoom * factor))
        boardRoot.setScale(boardZoom)
    }

    func resetZoom() {
        boardZoom = 1
        boardRoot.setScale(1)
        boardRoot.position = .zero
    }

    func showPieceInTray(_ pieceID: String) {
        guard let session, let definition,
              let index = session.pieces.filter(\.isInTray).firstIndex(where: { $0.id == pieceID }) else { return }
        if currentLayout?.mode == .horizontal {
            let row = index / horizontalTrayColumnCount
            let viewport = horizontalTrayViewport()
            trayScrollOffset = max(0, CGFloat(row) * horizontalTrayRowHeight() - (viewport.height - horizontalTrayRowHeight()) * 0.5)
            render(session: session, definition: definition, effectsEnabled: effectsEnabled, trayPage: currentTrayPage)
            return
        }
        let pageSize = 6
        currentTrayPage = index / pageSize
        render(session: session, definition: definition, effectsEnabled: effectsEnabled, trayPage: currentTrayPage)
    }

    func resetTrayScroll() {
        trayScrollOffset = 0
    }

    private var localBoardRect: CGRect {
        guard let layout = currentLayout else { return .zero }
        return CGRect(x: -layout.boardRect.width * 0.5, y: -layout.boardRect.height * 0.5, width: layout.boardRect.width, height: layout.boardRect.height)
    }

    private func horizontalTrayViewport() -> CGRect {
        guard let tray = currentLayout?.trayRect else { return .zero }
        // Reserve a slim, always-visible rail so tray controls never cover pieces.
        return CGRect(x: tray.minX + 12, y: tray.minY + 12, width: max(1, tray.width - 64), height: max(1, tray.height - 54))
    }

    private func horizontalTrayRowHeight() -> CGFloat {
        let viewport = horizontalTrayViewport()
        return max(112, min(170, viewport.height * 0.24))
    }

    private var horizontalTrayColumnCount: Int {
        let viewport = horizontalTrayViewport()
        let gap: CGFloat = 12
        let preferredSlotWidth: CGFloat = 190
        return max(1, min(6, Int((viewport.width + gap) / (preferredSlotWidth + gap))))
    }

    private func horizontalTrayContentHeight(pieceCount: Int) -> CGFloat {
        guard pieceCount > 0 else { return 0 }
        let rows = Int(ceil(Double(pieceCount) / Double(horizontalTrayColumnCount)))
        return CGFloat(rows) * horizontalTrayRowHeight()
    }

    private func scrollTray(by delta: CGFloat) {
        guard let session, let layout = currentLayout, layout.mode == .horizontal else { return }
        let viewport = horizontalTrayViewport()
        let contentHeight = horizontalTrayContentHeight(pieceCount: session.pieces.filter(\.isInTray).count)
        let maximum = max(0, contentHeight - viewport.height)
        trayScrollOffset = min(maximum, max(0, trayScrollOffset + delta))
        trayContent.position.y = trayScrollOffset
        refreshTrayScrollButtons()
    }

    private func addTrayScrollButtons(in tray: CGRect) {
        trayScrollUpButton = makeTrayScrollButton(direction: .up, at: CGPoint(x: tray.maxX - 28, y: tray.maxY - 30))
        trayScrollDownButton = makeTrayScrollButton(direction: .down, at: CGPoint(x: tray.maxX - 28, y: tray.minY + 30))
        if let trayScrollUpButton { addChild(trayScrollUpButton) }
        if let trayScrollDownButton { addChild(trayScrollDownButton) }
        refreshTrayScrollButtons()
    }

    private func makeTrayScrollButton(direction: TrayScrollArrow, at point: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(ellipseOf: CGSize(width: 36, height: 36))
        button.position = point
        button.fillColor = AppPalette.Board.button
        button.strokeColor = AppPalette.Board.border
        button.lineWidth = 1.5
        button.zPosition = 340

        let arrow = SKLabelNode(text: direction == .up ? "↑" : "↓")
        arrow.fontName = "AvenirNext-DemiBold"
        arrow.fontSize = 21
        arrow.fontColor = AppPalette.Board.accent
        arrow.verticalAlignmentMode = .center
        arrow.horizontalAlignmentMode = .center
        arrow.position = CGPoint(x: 0, y: -1)
        arrow.zPosition = 1
        button.addChild(arrow)
        return button
    }

    private func refreshTrayScrollButtons() {
        guard let session else { return }
        let contentHeight = horizontalTrayContentHeight(pieceCount: session.pieces.filter(\.isInTray).count)
        let maximum = max(0, contentHeight - horizontalTrayViewport().height)
        let canScrollUp = trayScrollOffset > 1
        let canScrollDown = trayScrollOffset < maximum - 1
        updateTrayScrollButton(trayScrollUpButton, enabled: canScrollUp)
        updateTrayScrollButton(trayScrollDownButton, enabled: canScrollDown)
    }

    private func updateTrayScrollButton(_ button: SKShapeNode?, enabled: Bool) {
        button?.alpha = enabled ? 1 : 0.44
        button?.fillColor = enabled
            ? AppPalette.Board.button
            : AppPalette.Board.slot
        button?.strokeColor = AppPalette.Board.border.withAlphaComponent(enabled ? 1 : 0.5)
    }

    private func trayScrollArrow(at point: CGPoint) -> TrayScrollArrow? {
        if let trayScrollUpButton, hypot(point.x - trayScrollUpButton.position.x, point.y - trayScrollUpButton.position.y) <= 22 {
            return .up
        }
        if let trayScrollDownButton, hypot(point.x - trayScrollDownButton.position.x, point.y - trayScrollDownButton.position.y) <= 22 {
            return .down
        }
        return nil
    }

    private func activateTrayScrollArrow(_ arrow: TrayScrollArrow) {
        let step = max(horizontalTrayRowHeight() * 2, horizontalTrayViewport().height * 0.62)
        scrollTray(by: arrow == .up ? -step : step)
    }

    private func hasDraggablePiece(at point: CGPoint) -> Bool {
        !selectablePieces(at: point).isEmpty
    }

    private func selectablePieces(at point: CGPoint) -> [JigsawPieceNode] {
        guard let layout = currentLayout else { return [] }
        return pieceNodes.values.filter { node in
            guard !node.isLocked else { return false }
            let visibleRect = node.parent === boardRoot
                ? layout.boardRect
                : (layout.mode == .horizontal ? horizontalTrayViewport() : layout.trayRect)
            return visibleRect.contains(point) && node.contains(worldPoint: point)
        }.sorted {
            $0.zPosition == $1.zPosition ? $0.pieceID < $1.pieceID : $0.zPosition > $1.zPosition
        }
    }

    private func clearPendingTrayTouch() {
        pendingTrayDragWorkItem?.cancel()
        pendingTrayDragWorkItem = nil
        pendingTrayPieceID = nil
        pendingTrayTouchStart = nil
        pendingTrayMaxMovement = 0
    }

    private func rebuild() {
        guard let session, let definition else { return }
        clearPendingTrayTouch()
        removeAllChildren()
        pieceNodes.removeAll()
        trayScrollUpButton = nil
        trayScrollDownButton = nil
        pressedTrayScrollArrow = nil
        draggedPieceID = nil
        trayClip.removeAllChildren()
        trayClip.removeFromParent()
        trayContent.removeAllChildren()
        trayContent.removeFromParent()

        let layout = makeCanvasLayout(size: size)
        currentLayout = layout
        boardRoot.removeAllChildren()
        boardClip.position = CGPoint(x: layout.boardRect.midX, y: layout.boardRect.midY)
        boardRoot.position = .zero
        boardRoot.setScale(boardZoom)
        let mask = SKSpriteNode(color: .white, size: localBoardRect.size)
        boardClip.maskNode = mask
        // Rebuild can run more than once during SpriteView startup (for example,
        // attach followed by the first size update). Detach the persistent root
        // from its previous parent before adding it again; SpriteKit raises an
        // Objective-C exception when a node is added while it already has a parent.
        boardRoot.removeFromParent()
        boardClip.addChild(boardRoot)
        addChild(boardClip)
        drawBoard(layout: layout)
        addChild(hintLayer)

        let grid = session.difficulty.grid
        let boardRect = localBoardRect
        let cellSize = CGSize(width: boardRect.width / CGFloat(grid.columns), height: boardRect.height / CGFloat(grid.rows))
        let unplaced = session.pieces.filter { $0.isInTray }
        let pageSize = 6
        let isScrollableTray = layout.mode == .horizontal
        trayPageCount = isScrollableTray ? 1 : max(1, Int(ceil(Double(unplaced.count) / Double(pageSize))))
        currentTrayPage = min(max(0, currentTrayPage), trayPageCount - 1)
        onTrayPageChanged?(currentTrayPage, trayPageCount, isScrollableTray)
        let visible = isScrollableTray ? unplaced : Array(unplaced.dropFirst(currentTrayPage * pageSize).prefix(pageSize))
        let texture = SKTexture(imageNamed: definition.imageName)

        if isScrollableTray {
            let viewport = horizontalTrayViewport()
            trayClip.position = CGPoint(x: viewport.midX, y: viewport.midY)
            trayClip.maskNode = SKSpriteNode(color: .white, size: viewport.size)
            trayContent.position = .zero
            trayClip.addChild(trayContent)
            addChild(trayClip)
            let contentHeight = horizontalTrayContentHeight(pieceCount: visible.count)
            trayScrollOffset = min(max(0, trayScrollOffset), max(0, contentHeight - viewport.height))
            trayContent.position.y = trayScrollOffset
        }

        for (visibleIndex, piece) in visible.enumerated() {
            let target = PuzzleLayoutGenerator.targetPosition(row: piece.targetRow, column: piece.targetColumn, difficulty: session.difficulty, boardRect: boardRect)
            let piece = JigsawPieceNode(
                pieceID: piece.id,
                texture: texture,
                boardSize: boardRect.size,
                pieceSize: cellSize,
                imageOffset: CGPoint(x: -target.x, y: -target.y),
                grid: grid,
                row: piece.targetRow,
                column: piece.targetColumn
            )

            let slot: CGRect
            if isScrollableTray {
                let viewport = horizontalTrayViewport()
                let rowHeight = horizontalTrayRowHeight()
                let columns = horizontalTrayColumnCount
                let gap: CGFloat = 12
                let slotWidth = max(1, (viewport.width - gap * CGFloat(columns - 1)) / CGFloat(columns))
                let column = visibleIndex % columns
                let row = visibleIndex / columns
                let localX = -viewport.width * 0.5 + slotWidth * 0.5 + CGFloat(column) * (slotWidth + gap)
                let localY = viewport.height * 0.5 - rowHeight * (CGFloat(row) + 0.5)
                slot = CGRect(x: localX - slotWidth * 0.5, y: localY - rowHeight * 0.5 + 3, width: slotWidth, height: rowHeight - 6)
            } else {
                slot = traySlot(index: visibleIndex, in: layout.trayRect)
            }
            let container: SKNode = isScrollableTray ? trayContent : self
            let traySlotNode = makeTraySlot(slot)
            container.addChild(traySlotNode)
            let silhouette = piece.silhouetteBounds
            let scale = isScrollableTray
                ? min(1, (slot.width * 0.86) / silhouette.width, (slot.height * 0.90) / silhouette.height)
                : min(1, (slot.width * 0.82) / silhouette.width, (slot.height * 0.74) / silhouette.height)
            let restingScale = max(0.18, scale)
            piece.position = CGPoint(
                x: slot.midX - silhouette.midX * restingScale,
                y: slot.midY - silhouette.midY * restingScale
            )
            piece.setScale(restingScale)
            piece.setPlacement(false)
            container.addChild(piece)
            pieceNodes[piece.pieceID] = piece
        }

        if isScrollableTray {
            addTrayScrollButtons(in: layout.trayRect)
        }

        let looseBoardPieces = session.looseBoardPieces
        for (index, piece) in looseBoardPieces.enumerated() {
            let target = PuzzleLayoutGenerator.targetPosition(row: piece.targetRow, column: piece.targetColumn, difficulty: session.difficulty, boardRect: boardRect)
            let node = JigsawPieceNode(
                pieceID: piece.id,
                texture: texture,
                boardSize: boardRect.size,
                pieceSize: cellSize,
                imageOffset: CGPoint(x: -target.x, y: -target.y),
                grid: grid,
                row: piece.targetRow,
                column: piece.targetColumn
            )
            node.position = CGPoint(
                x: boardRect.minX + boardRect.width * piece.positionX,
                y: boardRect.minY + boardRect.height * piece.positionY
            )
            node.setPlacement(false)
            node.zPosition = 10 + CGFloat(index)
            boardRoot.addChild(node)
            pieceNodes[piece.id] = node
        }

        for piece in session.pieces where piece.isPlaced {
            let target = PuzzleLayoutGenerator.targetPosition(row: piece.targetRow, column: piece.targetColumn, difficulty: session.difficulty, boardRect: boardRect)
            let node = JigsawPieceNode(
                pieceID: piece.id,
                texture: texture,
                boardSize: boardRect.size,
                pieceSize: cellSize,
                imageOffset: CGPoint(x: -target.x, y: -target.y),
                grid: grid,
                row: piece.targetRow,
                column: piece.targetColumn
            )
            node.position = target
            // A correctly snapped piece may still be picked up and repositioned
            // until the session is complete.
            node.setPlacement(false)
            node.setAssembled(true)
            boardRoot.addChild(node)
            pieceNodes[piece.id] = node
        }
        updateAssembledArtwork()
    }

    private func updateAssembledArtwork() {
        assembledArtwork.removeAllChildren()
        if assembledArtwork.parent == nil {
            assembledArtwork.zPosition = 1
            boardRoot.addChild(assembledArtwork)
        }
        guard let session, let definition else { return }
        let paths = jigsawAssemblyPaths(session: session, boardRect: localBoardRect, excluding: draggedPieceID)
        guard !paths.silhouette.isEmpty else { return }

        let mask = SKShapeNode(path: paths.silhouette)
        mask.fillColor = .white
        mask.strokeColor = .clear
        let artwork = SKCropNode()
        artwork.maskNode = mask
        artwork.addChild(artworkSprite(texture: SKTexture(imageNamed: definition.imageName), boardSize: localBoardRect.size))
        assembledArtwork.addChild(artwork)

        let cutEdges = SKShapeNode(path: paths.silhouette)
        cutEdges.fillColor = .clear
        cutEdges.strokeColor = SKColor(white: 0.04, alpha: 0.32)
        cutEdges.lineWidth = 0.65
        cutEdges.lineJoin = .round
        cutEdges.zPosition = 1
        assembledArtwork.addChild(cutEdges)

        let seams = SKShapeNode(path: paths.seams)
        seams.fillColor = .clear
        seams.strokeColor = SKColor(white: 0.035, alpha: 0.30)
        seams.lineWidth = 0.55
        seams.lineCap = .round
        seams.lineJoin = .round
        seams.zPosition = 2
        assembledArtwork.addChild(seams)
    }

    private func drawBoard(layout: PuzzleCanvasLayout) {
        let rect = localBoardRect
        let backdrop = SKShapeNode(path: CGPath(rect: rect, transform: nil))
        backdrop.fillColor = AppPalette.Board.background
        backdrop.strokeColor = .clear
        boardRoot.addChild(backdrop)

        let framePath = CGMutablePath()
        framePath.move(to: CGPoint(x: layout.boardRect.minX, y: layout.boardRect.minY))
        framePath.addLine(to: CGPoint(x: layout.boardRect.minX, y: layout.boardRect.maxY))
        framePath.addLine(to: CGPoint(x: layout.boardRect.maxX, y: layout.boardRect.maxY))
        framePath.addLine(to: CGPoint(x: layout.boardRect.maxX, y: layout.boardRect.minY))
        framePath.closeSubpath()
        let boardFrame = SKShapeNode(path: framePath)
        boardFrame.fillColor = .clear
        boardFrame.strokeColor = AppPalette.Board.border
        boardFrame.lineWidth = 2.5
        boardFrame.zPosition = 50
        addChild(boardFrame)

        let trayPanel = SKShapeNode(path: CGPath(roundedRect: layout.trayRect, cornerWidth: 24, cornerHeight: 24, transform: nil))
        trayPanel.fillColor = AppPalette.Board.tray
        trayPanel.strokeColor = AppPalette.Board.border
        trayPanel.lineWidth = 1.5
        trayPanel.zPosition = -10
        addChild(trayPanel)

        let title = SKLabelNode(text: "待拼碎片")
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = min(18, layout.trayRect.width * 0.045)
        title.fontColor = AppPalette.Board.text
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .top
        title.position = CGPoint(x: layout.trayRect.minX + 18, y: layout.trayRect.maxY - 14)
        addChild(title)
    }

    private func traySlot(index: Int, in rect: CGRect) -> CGRect {
        let columns = 3
        let rows = 2
        let gap: CGFloat = 7
        let topInset: CGFloat = 36
        let usableHeight = max(1, rect.height - topInset - 12)
        let slotWidth = (rect.width - gap * CGFloat(columns + 1)) / CGFloat(columns)
        let slotHeight = (usableHeight - gap * CGFloat(rows - 1)) / CGFloat(rows)
        let column = index % columns
        let row = index / columns
        return CGRect(
            x: rect.minX + gap + CGFloat(column) * (slotWidth + gap),
            y: rect.maxY - topInset - CGFloat(row + 1) * slotHeight - CGFloat(row) * gap,
            width: slotWidth,
            height: slotHeight
        )
    }

    private func makeTraySlot(_ rect: CGRect) -> SKShapeNode {
        let slot = SKShapeNode(path: CGPath(roundedRect: rect, cornerWidth: 14, cornerHeight: 14, transform: nil))
        slot.fillColor = AppPalette.Board.slot
        slot.strokeColor = AppPalette.Board.border.withAlphaComponent(0.65)
        slot.lineWidth = 1
        slot.zPosition = -2
        return slot
    }

    private func targetLocalPosition(for piece: PuzzlePieceState) -> CGPoint {
        PuzzleLayoutGenerator.targetPosition(row: piece.targetRow, column: piece.targetColumn, difficulty: pieceDifficulty, boardRect: localBoardRect)
    }

    private var pieceDifficulty: Difficulty { session?.difficulty ?? .pieces12 }

    private func boardPoint(from scenePoint: CGPoint) -> CGPoint {
        boardRoot.convert(scenePoint, from: self)
    }

    private func normalizedBoardPoint(_ localPoint: CGPoint) -> CGPoint {
        let rect = localBoardRect
        return CGPoint(x: (localPoint.x - rect.minX) / max(rect.width, 1), y: (localPoint.y - rect.minY) / max(rect.height, 1))
    }

    private func beginDragging(at point: CGPoint) {
        guard inputEnabled, draggedPieceID == nil else { return }
        if let arrow = trayScrollArrow(at: point) {
            pressedTrayScrollArrow = arrow
            return
        }
        guard let candidate = selectablePieces(at: point).first else {
            if currentLayout?.mode == .horizontal, horizontalTrayViewport().contains(point) {
                lastTrayScrollPoint = point
            } else if boardZoom > 1 && currentLayout?.boardRect.contains(point) == true {
                lastPanPoint = point
            }
            return
        }
        lastTrayScrollPoint = nil
        clearPendingTrayTouch()
        draggedPieceID = candidate.pieceID
        if candidate.isAssembled {
            candidate.setAssembled(false)
            updateAssembledArtwork()
        }
        candidate.setHighlighted(false)
        let scenePosition = candidate.convert(CGPoint.zero, to: self)
        dragOffset = CGPoint(x: scenePosition.x - point.x, y: scenePosition.y - point.y)
        candidate.removeFromParent()
        candidate.position = scenePosition
        addChild(candidate)
        candidate.setScale(boardZoom)
        // Stay above the entire loose stack, including a 96-piece board.
        candidate.zPosition = 200
        candidate.pickupPulse(enabled: effectsEnabled)
        effects.pickup(on: self, at: point, enabled: effectsEnabled)
        onPickup?()
    }

    private func drag(to point: CGPoint) {
        if let draggedPieceID, let node = pieceNodes[draggedPieceID] {
            let previousPosition = node.position
            node.position = CGPoint(x: point.x + dragOffset.x, y: point.y + dragOffset.y)
            node.tiltWhileDragging(horizontalDelta: node.position.x - previousPosition.x, enabled: effectsEnabled)
            guard let session, let piece = session.pieces.first(where: { $0.id == draggedPieceID }),
                  currentLayout?.boardRect.contains(point) == true else {
                node.setHighlighted(false)
                nearTarget = false
                return
            }
            let target = boardRoot.convert(targetLocalPosition(for: piece), to: self)
            let cellSize = localBoardRect.width / CGFloat(session.difficulty.grid.columns)
            let cellHeight = localBoardRect.height / CGFloat(session.difficulty.grid.rows)
            let threshold = hypot(cellSize, cellHeight) * 0.48 * boardZoom
            let isNear = hypot(node.position.x - target.x, node.position.y - target.y) <= threshold
            if isNear {
                node.removeAction(forKey: "piece-pickup")
                node.setScale(boardZoom)
                node.zRotation = 0
            }
            if isNear != nearTarget {
                nearTarget = isNear
                node.setHighlighted(isNear)
                if isNear {
                    effects.targetPreview(on: self, at: target, size: effectSize(for: node), enabled: effectsEnabled)
                }
            }
            return
        }

        if let previous = lastTrayScrollPoint {
            // Keep the tray content moving with the user's finger.
            scrollTray(by: previous.y - point.y)
            lastTrayScrollPoint = point
        } else if let previous = lastPanPoint {
            boardRoot.position.x += point.x - previous.x
            boardRoot.position.y += point.y - previous.y
            lastPanPoint = point
        }
    }

    private func endDragging() {
        clearPendingTrayTouch()
        guard let draggedPieceID, let node = pieceNodes[draggedPieceID],
              let session, let piece = session.pieces.first(where: { $0.id == draggedPieceID }) else {
            lastPanPoint = nil
            lastTrayScrollPoint = nil
            return
        }
        let cursor = node.position
        let local = boardPoint(from: cursor)
        let normalized = currentLayout?.boardRect.contains(cursor) == true
            ? normalizedBoardPoint(local)
            : CGPoint(x: -1, y: -1)
        let target = normalizedBoardPoint(targetLocalPosition(for: piece))
        node.setScale(1)
        node.zRotation = 0
        nearTarget = false
        self.draggedPieceID = nil
        lastPanPoint = nil
        lastTrayScrollPoint = nil
        onDrop?(draggedPieceID, normalized, target)
    }

    #if os(iOS) || os(tvOS)
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = true

        if twoFingerPanRecognizer?.view !== view {
            if let twoFingerPanRecognizer {
                twoFingerPanRecognizer.view?.removeGestureRecognizer(twoFingerPanRecognizer)
            }
            if let pinchRecognizer {
                pinchRecognizer.view?.removeGestureRecognizer(pinchRecognizer)
            }

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delegate = self
            view.addGestureRecognizer(pan)
            twoFingerPanRecognizer = pan

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.cancelsTouchesInView = false
            pinch.delaysTouchesBegan = false
            pinch.delegate = self
            view.addGestureRecognizer(pinch)
            pinchRecognizer = pinch
        }
    }

    @objc private func handleTwoFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        switch recognizer.state {
        case .began:
            clearPendingTrayTouch()
            lastTrayScrollPoint = nil
            let point = convertPoint(fromView: recognizer.location(in: view))
            let canPan = inputEnabled && draggedPieceID == nil
            isTwoFingerTrayScrolling = canPan
                && currentLayout?.mode == .horizontal
                && currentLayout?.trayRect.contains(point) == true
            isTwoFingerBoardPanning = canPan
                && !isTwoFingerTrayScrolling
                && boardZoom > 1
                && currentLayout?.boardRect.contains(point) == true
        case .changed:
            let translation = recognizer.translation(in: view)
            if isTwoFingerTrayScrolling {
                // UIKit view coordinates grow downward; invert Y so the tray
                // follows the two-finger motion on screen.
                scrollTray(by: -translation.y)
            } else if isTwoFingerBoardPanning {
                boardRoot.position.x += translation.x
                boardRoot.position.y -= translation.y
            }
            recognizer.setTranslation(.zero, in: view)
        case .ended, .cancelled, .failed:
            isTwoFingerTrayScrolling = false
            isTwoFingerBoardPanning = false
        default:
            break
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard inputEnabled, let view = recognizer.view else { return }
        if recognizer.state == .changed {
            let point = convertPoint(fromView: recognizer.location(in: view))
            guard currentLayout?.boardRect.contains(point) == true else { return }
            zoom(by: recognizer.scale)
            recognizer.scale = 1
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if let arrow = trayScrollArrow(at: point) {
            pressedTrayScrollArrow = arrow
            return
        }
        if currentLayout?.mode == .horizontal, horizontalTrayViewport().contains(point) {
            if hasDraggablePiece(at: point) {
                // A moving finger scrolls. Only a stationary long press starts
                // a piece drag, so slow swipes are never mistaken for a hold.
                clearPendingTrayTouch()
                pendingTrayPieceID = selectablePieces(at: point).first?.pieceID
                pendingTrayTouchStart = point
                guard let pieceID = pendingTrayPieceID else { return }
                let start = point
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self,
                          self.pendingTrayPieceID == pieceID,
                          self.pendingTrayMaxMovement < 8 else { return }
                    self.pendingTrayDragWorkItem = nil
                    self.beginDragging(at: start)
                }
                pendingTrayDragWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: workItem)
            } else {
                lastTrayScrollPoint = point
            }
            return
        }
        beginDragging(at: point)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if pendingTrayPieceID != nil, let start = pendingTrayTouchStart {
            let distance = hypot(point.x - start.x, point.y - start.y)
            pendingTrayMaxMovement = max(pendingTrayMaxMovement, distance)
            guard distance >= 8 else { return }
            clearPendingTrayTouch()
            lastTrayScrollPoint = start
            scrollTray(by: start.y - point.y)
            lastTrayScrollPoint = point
            return
        }
        drag(to: point)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let arrow = pressedTrayScrollArrow,
           let touch = touches.first,
           trayScrollArrow(at: touch.location(in: self)) == arrow {
            activateTrayScrollArrow(arrow)
        }
        pressedTrayScrollArrow = nil
        clearPendingTrayTouch()
        endDragging()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressedTrayScrollArrow = nil
        clearPendingTrayTouch()
        isTwoFingerTrayScrolling = false
        isTwoFingerBoardPanning = false
        endDragging()
    }
    #endif

    #if os(macOS)
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if let macScrollEventMonitor {
            NSEvent.removeMonitor(macScrollEventMonitor)
        }
        macScrollEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self, weak view] event in
            guard let self, self.inputEnabled, let view, let window = view.window, event.window === window else { return event }
            let viewPoint = view.convert(event.locationInWindow, from: nil)
            let point = self.convertPoint(fromView: viewPoint)
            guard self.currentLayout?.mode == .horizontal,
                  self.currentLayout?.trayRect.contains(point) == true else { return event }
            self.scrollTray(by: self.trayScrollDelta(for: event))
            return nil
        }
    }

    private func trayScrollDelta(for event: NSEvent) -> CGFloat {
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY * 28
        return event.isDirectionInvertedFromDevice ? delta : -delta
    }
    #endif

    #if os(macOS)
    override func mouseDown(with event: NSEvent) { beginDragging(at: event.location(in: self)) }
    override func mouseDragged(with event: NSEvent) { drag(to: event.location(in: self)) }
    override func mouseUp(with event: NSEvent) {
        if let arrow = pressedTrayScrollArrow, trayScrollArrow(at: event.location(in: self)) == arrow {
            activateTrayScrollArrow(arrow)
        }
        pressedTrayScrollArrow = nil
        endDragging()
    }
    override func scrollWheel(with event: NSEvent) {
        let point = event.location(in: self)
        if currentLayout?.mode == .horizontal, currentLayout?.trayRect.contains(point) == true {
            scrollTray(by: trayScrollDelta(for: event))
        } else if event.modifierFlags.contains(.command) {
            zoom(by: event.scrollingDeltaY > 0 ? 0.92 : 1.08)
        } else if boardZoom > 1 {
            boardRoot.position.x -= event.scrollingDeltaX
            boardRoot.position.y += event.scrollingDeltaY
        }
    }
    override func magnify(with event: NSEvent) { zoom(by: 1 + event.magnification) }
    #endif
}

#if os(iOS) || os(tvOS)
extension PuzzleBoardScene: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
#endif
