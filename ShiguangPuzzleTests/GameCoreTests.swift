import CoreGraphics
import XCTest
@testable import ShiguangPuzzle

final class GameCoreTests: XCTestCase {
    func testDifficultyGridContainsExpectedPieceCounts() {
        for difficulty in Difficulty.allCases {
            XCTAssertEqual(difficulty.grid.rows * difficulty.grid.columns, difficulty.rawValue)
        }
    }

    func testSeedProducesStableLayout() {
        let seed = PuzzleLayoutGenerator.seed(puzzleID: "red-panda", difficulty: .pieces48)
        let first = PuzzleLayoutGenerator.makeSession(puzzleID: "red-panda", difficulty: .pieces48, seed: seed)
        let second = PuzzleLayoutGenerator.makeSession(puzzleID: "red-panda", difficulty: .pieces48, seed: seed)
        XCTAssertEqual(first, second)
    }

    func testUnseededSessionsUseDifferentPieceOrders() {
        let first = PuzzleLayoutGenerator.makeSession(puzzleID: "red-panda", difficulty: .pieces12)
        let second = PuzzleLayoutGenerator.makeSession(puzzleID: "red-panda", difficulty: .pieces12)
        XCTAssertNotEqual(first.pieces.map(\.id), second.pieces.map(\.id))
    }

    func testDifferentPuzzleOrDifficultyChangesOrder() {
        let firstSeed = PuzzleLayoutGenerator.seed(puzzleID: "red-panda", difficulty: .pieces12)
        let secondSeed = PuzzleLayoutGenerator.seed(puzzleID: "lighthouse", difficulty: .pieces12)
        let first = PuzzleLayoutGenerator.makeSession(puzzleID: "red-panda", difficulty: .pieces12, seed: firstSeed)
        let second = PuzzleLayoutGenerator.makeSession(puzzleID: "lighthouse", difficulty: .pieces12, seed: secondSeed)
        XCTAssertNotEqual(first.pieces.map(\.id), second.pieces.map(\.id))
    }

    func testSnappingTheLastPieceCompletesTheSession() {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "test", difficulty: .pieces12)
        var engine = PuzzleEngine(session: session)
        let grid = Difficulty.pieces12.grid
        var lastResult: MoveResult?

        for piece in session.pieces {
            let target = CGPoint(
                x: CGFloat(piece.targetColumn) / CGFloat(grid.columns) + 0.5 / CGFloat(grid.columns),
                y: CGFloat(grid.rows - piece.targetRow) / CGFloat(grid.rows) - 0.5 / CGFloat(grid.rows)
            )
            lastResult = engine.movePiece(id: piece.id, to: target, target: target)
        }

        XCTAssertEqual(engine.session.placedCount, 12)
        XCTAssertEqual(lastResult?.didComplete, true)
    }

    func testAllDifficultiesAreAvailableFromTheStart() {
        var progress = PuzzleProgress()
        XCTAssertTrue(progress.isUnlocked(puzzleID: "test", difficulty: .pieces12))
        XCTAssertTrue(progress.isUnlocked(puzzleID: "test", difficulty: .pieces24))
        XCTAssertTrue(progress.isUnlocked(puzzleID: "test", difficulty: .pieces48))
        XCTAssertTrue(progress.isUnlocked(puzzleID: "test", difficulty: .pieces96))
    }

    func testSnapThresholdScalesWithPieceSize() {
        for difficulty in Difficulty.allCases {
            let session = PuzzleLayoutGenerator.makeSession(puzzleID: "snap-test", difficulty: difficulty)
            let piece = session.pieces[0]
            let grid = difficulty.grid
            let target = CGPoint(
                x: (CGFloat(piece.targetColumn) + 0.5) / CGFloat(grid.columns),
                y: (CGFloat(grid.rows - piece.targetRow) - 0.5) / CGFloat(grid.rows)
            )
            let cellDiagonal = hypot(1 / CGFloat(grid.columns), 1 / CGFloat(grid.rows))
            var engine = PuzzleEngine(session: session)
            let close = CGPoint(x: target.x + cellDiagonal * 0.4, y: target.y)
            XCTAssertEqual(engine.movePiece(id: piece.id, to: close, target: target)?.didSnap, true)

            var distantEngine = PuzzleEngine(session: session)
            let distant = CGPoint(x: target.x + cellDiagonal * 0.55, y: target.y)
            XCTAssertEqual(distantEngine.movePiece(id: piece.id, to: distant, target: target)?.didSnap, false)
        }
    }

    func testIncorrectDropStaysOnBoardAndCanBeMovedAgain() {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "loose-piece", difficulty: .pieces12)
        let piece = session.pieces.first { $0.targetRow == 1 && $0.targetColumn == 1 }!
        let grid = session.difficulty.grid
        let target = CGPoint(
            x: (CGFloat(piece.targetColumn) + 0.5) / CGFloat(grid.columns),
            y: (CGFloat(grid.rows - piece.targetRow) - 0.5) / CGFloat(grid.rows)
        )
        var engine = PuzzleEngine(session: session)

        let wrongDrop = CGPoint(x: 0.95, y: 0.12)
        XCTAssertEqual(engine.movePiece(id: piece.id, to: wrongDrop, target: target)?.didSnap, false)
        let misplaced = engine.session.pieces.first { $0.id == piece.id }!
        XCTAssertTrue(misplaced.isOnBoard)
        XCTAssertFalse(misplaced.isInTray)
        XCTAssertFalse(misplaced.isPlaced)

        XCTAssertEqual(engine.movePiece(id: piece.id, to: target, target: target)?.didSnap, true)
        let corrected = engine.session.pieces.first { $0.id == piece.id }!
        XCTAssertTrue(corrected.isPlaced)
        XCTAssertEqual(engine.session.placedCount, 1)
    }

    func testCorrectlyPlacedPieceCanBePickedUpAndMovedAgain() {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "move-snapped-piece", difficulty: .pieces12)
        let piece = session.pieces[0]
        let grid = session.difficulty.grid
        let target = CGPoint(
            x: (CGFloat(piece.targetColumn) + 0.5) / CGFloat(grid.columns),
            y: (CGFloat(grid.rows - piece.targetRow) - 0.5) / CGFloat(grid.rows)
        )
        var engine = PuzzleEngine(session: session)

        XCTAssertEqual(engine.movePiece(id: piece.id, to: target, target: target)?.didSnap, true)
        XCTAssertEqual(engine.session.placedCount, 1)

        let wrongPosition = CGPoint(x: 0.98, y: 0.04)
        XCTAssertEqual(engine.movePiece(id: piece.id, to: wrongPosition, target: target)?.didSnap, false)
        XCTAssertEqual(engine.session.placedCount, 0)
        let movedPiece = engine.session.pieces.first { $0.id == piece.id }!
        XCTAssertFalse(movedPiece.isPlaced)
        XCTAssertTrue(movedPiece.isOnBoard)

        XCTAssertEqual(engine.movePiece(id: piece.id, to: target, target: target)?.didSnap, true)
        XCTAssertEqual(engine.session.placedCount, 1)
    }

    func testDroppingOutsideBoardReturnsPieceToTray() {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "tray-piece", difficulty: .pieces12)
        let piece = session.pieces[0]
        let target = CGPoint(
            x: (CGFloat(piece.targetColumn) + 0.5) / 4,
            y: (CGFloat(3 - piece.targetRow) - 0.5) / 3
        )
        var engine = PuzzleEngine(session: session)
        _ = engine.movePiece(id: piece.id, to: CGPoint(x: -1, y: -1), target: target)
        XCTAssertTrue(engine.session.pieces.first { $0.id == piece.id }!.isInTray)
    }
}

final class JigsawGeometryTests: XCTestCase {
    private func points(in path: CGPath, offset: CGPoint = .zero) -> [CGPoint] {
        var result: [CGPoint] = []
        path.applyWithBlock { element in
            let count: Int
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint: count = 1
            case .addQuadCurveToPoint: count = 2
            case .addCurveToPoint: count = 3
            case .closeSubpath: count = 0
            @unknown default: count = 0
            }
            for index in 0..<count {
                let point = element.pointee.points[index]
                result.append(CGPoint(x: point.x + offset.x, y: point.y + offset.y))
            }
        }
        return result
    }

    func testNeighboringSeamsMatchInBothDirectionsAtEveryDifficulty() {
        for difficulty in Difficulty.allCases {
            let grid = difficulty.grid
            for side: CGFloat in [320, 1200] {
                let size = CGSize(width: side / CGFloat(grid.columns), height: side / CGFloat(grid.rows))
                for row in 0..<grid.rows {
                    for column in 0..<grid.columns {
                        let seams = jigsawSeamPaths(size: size, grid: grid, row: row, column: column)
                        var neighbors: [(Int, JigsawSeam, CGPoint)] = []
                        if column + 1 < grid.columns {
                            let right = jigsawSeamPaths(size: size, grid: grid, row: row, column: column + 1)[3]
                            neighbors.append((1, right, CGPoint(x: size.width, y: 0)))
                        }
                        if row + 1 < grid.rows {
                            let below = jigsawSeamPaths(size: size, grid: grid, row: row + 1, column: column)[2]
                            neighbors.append((0, below, CGPoint(x: 0, y: -size.height)))
                        }
                        for (index, neighbor, offset) in neighbors {
                            let own = points(in: seams[index].path)
                            let adjacent = points(in: neighbor.path, offset: offset).reversed()
                            XCTAssertEqual(own.count, adjacent.count)
                            XCTAssertEqual(seams[index].outward, -neighbor.outward)
                            for (first, second) in zip(own, adjacent) {
                                XCTAssertEqual(first.x, second.x, accuracy: 0.000_001)
                                XCTAssertEqual(first.y, second.y, accuracy: 0.000_001)
                            }
                        }
                    }
                }
            }
        }
    }

    func testCurvedSeamsHaveSmoothJoins() {
        let grid = Difficulty.pieces96.grid
        for row in 0..<grid.rows {
            for column in 0..<grid.columns {
                let seams = jigsawSeamPaths(size: CGSize(width: 100, height: 150), grid: grid, row: row, column: column)
                for seam in seams where seam.outward != 0 {
                    let controls = points(in: seam.path)
                    for index in stride(from: 3, to: controls.count - 1, by: 3) {
                        let incoming = CGVector(dx: controls[index].x - controls[index - 1].x, dy: controls[index].y - controls[index - 1].y)
                        let outgoing = CGVector(dx: controls[index + 1].x - controls[index].x, dy: controls[index + 1].y - controls[index].y)
                        XCTAssertEqual(incoming.dx * outgoing.dy - incoming.dy * outgoing.dx, 0, accuracy: 0.000_001)
                        XCTAssertGreaterThan(incoming.dx * outgoing.dx + incoming.dy * outgoing.dy, 0)
                    }
                }
            }
        }
    }

    func testPiecesFillTheBoardWithoutGapsOrOverlaps() {
        for difficulty in Difficulty.allCases {
            let grid = difficulty.grid
            let board = CGRect(x: 0, y: 0, width: 720, height: 720)
            let size = CGSize(width: board.width / CGFloat(grid.columns), height: board.height / CGFloat(grid.rows))
            var paths: [CGPath] = []
            for row in 0..<grid.rows {
                for column in 0..<grid.columns {
                    let center = PuzzleLayoutGenerator.targetPosition(row: row, column: column, difficulty: difficulty, boardRect: board)
                    var transform = CGAffineTransform(translationX: center.x, y: center.y)
                    let path = piecePath(size: size, grid: grid, row: row, column: column).copy(using: &transform)!
                    XCTAssertTrue(board.insetBy(dx: -0.000_001, dy: -0.000_001).contains(path.boundingBoxOfPath))
                    paths.append(path)
                }
            }
            for x in 0..<53 {
                for y in 0..<53 {
                    let sample = CGPoint(x: (CGFloat(x) + 0.371) * board.width / 53, y: (CGFloat(y) + 0.619) * board.height / 53)
                    XCTAssertEqual(paths.filter { $0.contains(sample) }.count, 1, "Invalid coverage at \(sample) for \(difficulty)")
                }
            }
        }
    }
}

final class JigsawAssemblyTests: XCTestCase {
    private func completeSession(_ difficulty: Difficulty) -> PuzzleSession {
        var session = PuzzleLayoutGenerator.makeSession(puzzleID: "assembly", difficulty: difficulty, seed: 42)
        for index in session.pieces.indices { session.pieces[index].isPlaced = true }
        return session
    }

    private func subpathCount(_ path: CGPath) -> Int {
        var count = 0
        path.applyWithBlock { if $0.pointee.type == .moveToPoint { count += 1 } }
        return count
    }

    func testCompletedArtworkHasOneMaskAndOneLinePerSharedSeam() {
        for difficulty in Difficulty.allCases {
            let session = completeSession(difficulty)
            let rect = CGRect(x: -359.73, y: -359.73, width: 719.46, height: 719.46)
            let paths = jigsawAssemblyPaths(session: session, boardRect: rect)
            let grid = difficulty.grid
            XCTAssertEqual(subpathCount(paths.silhouette), 1, "Internal mask edges remain at \(difficulty)")
            XCTAssertEqual(subpathCount(paths.seams), (grid.rows - 1) * grid.columns + (grid.columns - 1) * grid.rows)
            XCTAssertEqual(paths.silhouette.boundingBoxOfPath.minX, rect.minX, accuracy: 0.0001)
            XCTAssertEqual(paths.silhouette.boundingBoxOfPath.maxY, rect.maxY, accuracy: 0.0001)
            XCTAssertTrue(paths.silhouette.contains(.zero))
        }
    }

    func testLiftingAPieceRemovesItsArtworkAndItsJoinedSeams() {
        for difficulty in Difficulty.allCases {
            let session = completeSession(difficulty)
            let piece = session.pieces.first { $0.targetRow == 1 && $0.targetColumn == 1 }!
            let rect = CGRect(x: -320, y: -320, width: 640, height: 640)
            let paths = jigsawAssemblyPaths(session: session, boardRect: rect, excluding: piece.id)
            let target = PuzzleLayoutGenerator.targetPosition(row: 1, column: 1, difficulty: difficulty, boardRect: rect)
            let grid = difficulty.grid
            XCTAssertFalse(paths.silhouette.contains(target))
            XCTAssertEqual(subpathCount(paths.seams), (grid.rows - 1) * grid.columns + (grid.columns - 1) * grid.rows - 4)
            for other in session.pieces where other.id != piece.id {
                let center = PuzzleLayoutGenerator.targetPosition(row: other.targetRow, column: other.targetColumn, difficulty: difficulty, boardRect: rect)
                XCTAssertTrue(paths.silhouette.contains(center))
            }
        }
    }

    func testEmptyAndDisconnectedAreasHaveNoGuidelineSeams() {
        var session = PuzzleLayoutGenerator.makeSession(puzzleID: "assembly", difficulty: .pieces12, seed: 42)
        let rect = CGRect(x: -300, y: -300, width: 600, height: 600)
        var paths = jigsawAssemblyPaths(session: session, boardRect: rect)
        XCTAssertTrue(paths.silhouette.isEmpty)
        XCTAssertTrue(paths.seams.isEmpty)
        for index in session.pieces.indices {
            let piece = session.pieces[index]
            session.pieces[index].isPlaced = (piece.targetRow + piece.targetColumn).isMultiple(of: 2)
        }
        paths = jigsawAssemblyPaths(session: session, boardRect: rect)
        XCTAssertTrue(paths.seams.isEmpty)
        for piece in session.pieces {
            let target = PuzzleLayoutGenerator.targetPosition(row: piece.targetRow, column: piece.targetColumn, difficulty: session.difficulty, boardRect: rect)
            XCTAssertEqual(paths.silhouette.contains(target), piece.isPlaced)
        }
    }
}

final class PieceRecoveryTests: XCTestCase {
    func testRecentlyMovedLoosePieceStaysOnTopAfterSaving() throws {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "stacking", difficulty: .pieces12, seed: 42)
        var engine = PuzzleEngine(session: session)
        let bottom = session.pieces[0].id
        let top = session.pieces[1].id
        let target = CGPoint(x: 0.1, y: 0.1)
        let pile = CGPoint(x: 0.85, y: 0.85)
        _ = engine.movePiece(id: bottom, to: pile, target: target)
        _ = engine.movePiece(id: top, to: pile, target: target)
        XCTAssertEqual(engine.session.looseBoardPieces.map(\.id), [bottom, top])
        _ = engine.movePiece(id: bottom, to: pile, target: target)
        XCTAssertEqual(engine.session.looseBoardPieces.last?.id, bottom)
        let restored = try JSONDecoder().decode(PuzzleSession.self, from: JSONEncoder().encode(engine.session))
        XCTAssertEqual(restored.looseBoardPieces.map(\.id), [top, bottom])
    }

    func testRecoveryPreservesCompletedPiecesAndPrioritizesReturnedPieces() {
        for difficulty in Difficulty.allCases {
            let session = PuzzleLayoutGenerator.makeSession(puzzleID: "recover", difficulty: difficulty, seed: 42)
            var engine = PuzzleEngine(session: session)
            let fixedID = session.pieces[0].id
            let fixedTarget = CGPoint(x: 0.1, y: 0.1)
            _ = engine.movePiece(id: fixedID, to: fixedTarget, target: fixedTarget)
            let returnedIDs = session.pieces.dropFirst().prefix(7).map(\.id)
            for id in returnedIDs {
                _ = engine.movePiece(id: id, to: CGPoint(x: 0.9, y: 0.9), target: fixedTarget)
            }
            engine.updateElapsed(milliseconds: 6000)
            engine.registerHint()
            let before = engine.session
            XCTAssertEqual(engine.recoverLoosePieces(), returnedIDs)
            let after = engine.session
            XCTAssertTrue(after.looseBoardPieces.isEmpty)
            XCTAssertEqual(after.pieces.first { $0.id == fixedID }, before.pieces.first { $0.id == fixedID })
            XCTAssertEqual(after.placedCount, before.placedCount)
            XCTAssertEqual(after.moveCount, before.moveCount)
            XCTAssertEqual(after.hintCount, before.hintCount)
            XCTAssertEqual(after.elapsedMilliseconds, before.elapsedMilliseconds)
            XCTAssertEqual(after.pieces.filter(\.isInTray).prefix(7).map(\.id), returnedIDs)
            XCTAssertTrue(after.pieces.prefix(7).allSatisfy { $0.isInTray && $0.stackOrder == nil })
            XCTAssertEqual(Set(after.pieces.map(\.id)), Set(before.pieces.map(\.id)))
        }
    }

    func testRecoveryWithNoLoosePiecesIsANoOp() {
        let session = PuzzleLayoutGenerator.makeSession(puzzleID: "empty-recovery", difficulty: .pieces12, seed: 42)
        var engine = PuzzleEngine(session: session)
        XCTAssertTrue(engine.recoverLoosePieces().isEmpty)
        XCTAssertEqual(engine.session, session)
    }

    func testOldSavesWithoutStackOrderRemainRecoverable() throws {
        var session = PuzzleLayoutGenerator.makeSession(puzzleID: "legacy", difficulty: .pieces12, seed: 42)
        session.pieces[0].positionX = 0.7
        session.pieces[0].positionY = 0.8
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        var pieces = try XCTUnwrap(json["pieces"] as? [[String: Any]])
        for index in pieces.indices { pieces[index].removeValue(forKey: "stackOrder") }
        json["pieces"] = pieces
        let restored = try JSONDecoder().decode(PuzzleSession.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(restored.pieces[0].stackOrder)
        var engine = PuzzleEngine(session: restored)
        XCTAssertEqual(engine.recoverLoosePieces(), [session.pieces[0].id])
        XCTAssertTrue(engine.session.pieces[0].isInTray)
    }
}
