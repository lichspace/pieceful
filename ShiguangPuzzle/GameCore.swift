import CoreGraphics
import Foundation

enum Difficulty: Int, Codable, CaseIterable, Identifiable, Hashable {
    case pieces12 = 12
    case pieces24 = 24
    case pieces48 = 48
    case pieces96 = 96

    var id: Int { rawValue }
    var title: String { "\(rawValue) 片" }

    var grid: (rows: Int, columns: Int) {
        switch self {
        case .pieces12: return (3, 4)
        case .pieces24: return (4, 6)
        case .pieces48: return (6, 8)
        case .pieces96: return (8, 12)
        }
    }

    var next: Difficulty? {
        switch self {
        case .pieces12: return .pieces24
        case .pieces24: return .pieces48
        case .pieces48: return .pieces96
        case .pieces96: return nil
        }
    }
}

enum PuzzleCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case animals
    case architecture
    case vehicles
    case nature
    case space
    case mecha
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .animals: return "动物"
        case .architecture: return "建筑"
        case .vehicles: return "交通工具"
        case .nature: return "自然"
        case .space: return "太空"
        case .mecha: return "机甲"
        case .ocean: return "海洋"
        }
    }

    var subtitle: String {
        switch self {
        case .animals: return "温柔可爱的朋友们"
        case .architecture: return "城市与远方的风景"
        case .vehicles: return "出发去探索世界"
        case .nature: return "把一片宁静拾回家"
        case .space: return "向着星辰与银河出发"
        case .mecha: return "钢铁伙伴的奇妙世界"
        case .ocean: return "潜入蔚蓝色的梦境"
        }
    }

    var symbolName: String {
        switch self {
        case .animals: return "pawprint.fill"
        case .architecture: return "building.2.fill"
        case .vehicles: return "tram.fill"
        case .nature: return "leaf.fill"
        case .space: return "sparkles"
        case .mecha: return "gearshape.2.fill"
        case .ocean: return "water.waves"
        }
    }
}

struct PuzzleDefinition: Codable, Identifiable, Hashable {
    let id: String
    let category: PuzzleCategory
    let imageName: String
    let title: String
    let aspectRatio: Double
    let availableDifficulties: [Difficulty]
}

struct PuzzlePieceState: Codable, Identifiable, Hashable {
    let id: String
    let targetRow: Int
    let targetColumn: Int
    /// Stage coordinates in the range 0...1. Negative means the piece is still in the tray.
    var positionX: Double
    var positionY: Double
    var isPlaced: Bool
    /// Optional so saves created before stacking order was recorded still load.
    var stackOrder: Int? = nil

    var isOnBoard: Bool {
        (0...1).contains(positionX) && (0...1).contains(positionY)
    }

    var isInTray: Bool {
        !isPlaced && !isOnBoard
    }
}

struct PuzzleSession: Codable, Hashable {
    let version: Int
    let puzzleID: String
    let difficulty: Difficulty
    var elapsedMilliseconds: Int
    var moveCount: Int
    var hintCount: Int
    var placedCount: Int
    var pieces: [PuzzlePieceState]

    var isComplete: Bool {
        !pieces.isEmpty && placedCount == pieces.count && pieces.allSatisfy(\.isPlaced)
    }

    var looseBoardPieces: [PuzzlePieceState] {
        pieces.enumerated()
            .filter { !$0.element.isPlaced && $0.element.isOnBoard }
            .sorted {
                let left = $0.element.stackOrder ?? 0
                let right = $1.element.stackOrder ?? 0
                return left == right ? $0.offset < $1.offset : left < right
            }
            .map(\.element)
    }
}

struct PuzzleProgress: Codable, Hashable {
    var completedDifficulties: [String: [Int]] = [:]
    var bestElapsedMilliseconds: [String: Int] = [:]

    func isUnlocked(puzzleID: String, difficulty: Difficulty) -> Bool {
        // All MVP difficulties are available from the start. Progress is still
        // retained for completion statistics and future progression rules.
        true
    }

    mutating func markCompleted(puzzleID: String, difficulty: Difficulty, elapsedMilliseconds: Int) {
        var values = completedDifficulties[puzzleID] ?? []
        if !values.contains(difficulty.rawValue) {
            values.append(difficulty.rawValue)
        }
        completedDifficulties[puzzleID] = values.sorted()
        if let best = bestElapsedMilliseconds[puzzleID] {
            bestElapsedMilliseconds[puzzleID] = min(best, elapsedMilliseconds)
        } else {
            bestElapsedMilliseconds[puzzleID] = elapsedMilliseconds
        }
    }
}

struct PuzzleLayoutGenerator {
    struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
            value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
            return value ^ (value >> 31)
        }
    }

    static func seed(puzzleID: String, difficulty: Difficulty) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in "\(puzzleID)-\(difficulty.rawValue)".utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }

    static func makeSession(puzzleID: String, difficulty: Difficulty, seed: UInt64? = nil) -> PuzzleSession {
        let grid = difficulty.grid
        var ids = (0..<difficulty.rawValue).map { index in
            let row = index / grid.columns
            let column = index % grid.columns
            return PuzzlePieceState(
                id: "\(puzzleID)-\(difficulty.rawValue)-\(row)-\(column)",
                targetRow: row,
                targetColumn: column,
                positionX: -1,
                positionY: -1,
                isPlaced: false
            )
        }
        var generator = SeededGenerator(seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max))
        ids.shuffle(using: &generator)
        return PuzzleSession(
            version: 1,
            puzzleID: puzzleID,
            difficulty: difficulty,
            elapsedMilliseconds: 0,
            moveCount: 0,
            hintCount: 0,
            placedCount: 0,
            pieces: ids
        )
    }

    static func targetPosition(
        row: Int,
        column: Int,
        difficulty: Difficulty,
        boardRect: CGRect
    ) -> CGPoint {
        let grid = difficulty.grid
        let cellWidth = boardRect.width / CGFloat(grid.columns)
        let cellHeight = boardRect.height / CGFloat(grid.rows)
        return CGPoint(
            x: boardRect.minX + cellWidth * (CGFloat(column) + 0.5),
            y: boardRect.minY + cellHeight * (CGFloat(grid.rows - row) - 0.5)
        )
    }
}

struct MoveResult {
    let didSnap: Bool
    let didComplete: Bool
    let pieceID: String
}

struct PuzzleEngine {
    private(set) var session: PuzzleSession

    init(session: PuzzleSession) {
        self.session = session
    }

    mutating func movePiece(
        id: String,
        to position: CGPoint,
        target: CGPoint
    ) -> MoveResult? {
        guard let index = session.pieces.firstIndex(where: { $0.id == id }) else { return nil }

        session.moveCount += 1
        let wasPlaced = session.pieces[index].isPlaced
        let distance = hypot(position.x - target.x, position.y - target.y)
        let grid = session.difficulty.grid
        let snapDistance = 0.46 * hypot(1 / CGFloat(grid.columns), 1 / CGFloat(grid.rows))
        let didSnap = distance <= snapDistance
        session.pieces[index].positionX = didSnap ? target.x : position.x
        session.pieces[index].positionY = didSnap ? target.y : position.y
        session.pieces[index].isPlaced = didSnap
        session.pieces[index].stackOrder = !didSnap && session.pieces[index].isOnBoard ? session.moveCount : nil
        if wasPlaced != didSnap {
            session.placedCount += didSnap ? 1 : -1
        }
        let didComplete = session.placedCount == session.pieces.count
        return MoveResult(didSnap: didSnap, didComplete: didComplete, pieceID: id)
    }

    @discardableResult
    mutating func recoverLoosePieces() -> [String] {
        let recoveredIDs = session.looseBoardPieces.map(\.id)
        guard !recoveredIDs.isEmpty else { return [] }
        let recovered = Set(recoveredIDs)
        var returned: [PuzzlePieceState] = []
        var remaining: [PuzzlePieceState] = []
        for var piece in session.pieces {
            if recovered.contains(piece.id) {
                piece.positionX = -1
                piece.positionY = -1
                piece.stackOrder = nil
                returned.append(piece)
            } else {
                remaining.append(piece)
            }
        }
        // Recovered pieces appear first, including in the paged phone tray.
        session.pieces = returned + remaining
        return returned.map(\.id)
    }

    mutating func registerHint() {
        session.hintCount += 1
    }

    mutating func updateElapsed(milliseconds: Int) {
        session.elapsedMilliseconds = max(0, milliseconds)
    }
}

final class SaveStore {
    static let shared = SaveStore()
    private let defaults = UserDefaults.standard
    private let progressKey = "shiguang.progress.v1"

    func key(puzzleID: String, difficulty: Difficulty) -> String {
        "shiguang.session.v\(1).\(puzzleID).\(difficulty.rawValue)"
    }

    func loadSession(puzzleID: String, difficulty: Difficulty) -> PuzzleSession? {
        guard let data = defaults.data(forKey: key(puzzleID: puzzleID, difficulty: difficulty)) else { return nil }
        return try? JSONDecoder().decode(PuzzleSession.self, from: data)
    }

    func save(session: PuzzleSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: key(puzzleID: session.puzzleID, difficulty: session.difficulty))
    }

    func deleteSession(puzzleID: String, difficulty: Difficulty) {
        defaults.removeObject(forKey: key(puzzleID: puzzleID, difficulty: difficulty))
    }

    func loadProgress() -> PuzzleProgress {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(PuzzleProgress.self, from: data) else {
            return PuzzleProgress()
        }
        return progress
    }

    func saveProgress(_ progress: PuzzleProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: progressKey)
    }
}
