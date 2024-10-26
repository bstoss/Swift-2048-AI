import Foundation

public class Solver {
    let mainGame : Engine
    let size : Int = 4
    var intelligence: Int = 0
    
    
    init(game: Engine) {
        mainGame = game
    }
    
    func runRandom(board: Board, firstMove: Direction) -> Int {
        let randomGame = Engine(withBoard: board)
        let didMove = randomGame.move(direction: firstMove, addRandom: true)
        
        if (!didMove) {
            //print("No first move found for Move: \(firstMove)")
            return randomGame.score
        }
        
        //print("Start runRandom for Move: \(firstMove)")
        while true {
            if randomGame.isGameOver() {
                //print("game over")
                break
            }
            _ = randomGame.move(direction: Direction.randomMove(), addRandom: true)
            //print(moved)
        }
        //print("Move: \(firstMove) - Score: \(randomGame.score)")
        return randomGame.score
    }
    
    func findBestMove() -> Direction {
        var average = 0
        var best = -1
        var bestMove : Direction = Direction.randomMove()
        let numRuns = Int(Double(self.intelligence) * (0.1 + 0.00005 * Double(self.mainGame.score)))
        //print("findBestMove - runs: \(numRuns)")
        if (numRuns == 0) {
            return bestMove
        }
        
        for move in Direction.moves {
            average = 0
            for _ in 1...numRuns {
                average += runRandom(board: mainGame.board, firstMove: move)
            }
            average /= numRuns
            if average >= best {
                best = average
                bestMove = move
            }
        }
        return bestMove
    }
}
