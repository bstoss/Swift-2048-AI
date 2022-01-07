import UIKit
import Foundation

class AddButton: UIButton {
    let position: Position
    
    required init(position: Position) {
        self.position = position

        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class GameViewController : UIViewController, EngineProtocol {
    var size: Int = 4
    
    var makeMoveSwitch: UISwitch?
    var valueSlider: UISlider?
    var addTileValue = 0
    var valueSliderLabel: UILabel?
    
    var boardView: BoardView?
    var backupBoard: Board?
    private(set) var game: Engine?

    var scoreView: UILabel?
    var score: Int = 0 {
        didSet {
            scoreView?.text = "Score: \(score)"
        }
    }
    var delaySlider: UISlider?
    var delay: Double = 0.4
    
    var intSlider: UISlider?
    var intelligence: Int = 100 {
        didSet {
            solver?.intelligence = intelligence
        }
    }
    
    var solver: Solver?
    var solverBtn: UIButton?
    var solverOneBtn: UIButton?
    var solverRunning: Bool = false {
        didSet {
            solverBtn?.backgroundColor = solverRunning ? .red : .green
            solverBtn?.setTitle(solverRunning ? "Stop AI" : "Start AI", for: .normal)
        }
    }
    
    public init(size s: Int) {
        self.size = s
        super.init(nibName: nil, bundle: nil)
        game = Engine(boardSize: size, delegate: self)
        solver = Solver(game: game!)
        solver?.intelligence = intelligence

        self.view.backgroundColor = UIColor.white
        
        let up = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.upCommand(_:)))
        up.numberOfTouchesRequired = 1
        up.direction = UISwipeGestureRecognizer.Direction.up
        view.addGestureRecognizer(up)
        
        let down = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.downCommand(_:)))
        down.numberOfTouchesRequired = 1
        down.direction = UISwipeGestureRecognizer.Direction.down
        view.addGestureRecognizer(down)
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.leftCommand(_:)))
        left.numberOfTouchesRequired = 1
        left.direction = UISwipeGestureRecognizer.Direction.left
        view.addGestureRecognizer(left)
        
        let right = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.rightCommand(_:)))
        right.numberOfTouchesRequired = 1
        right.direction = UISwipeGestureRecognizer.Direction.right
        view.addGestureRecognizer(right)

    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override public func viewDidLoad()  {
        super.viewDidLoad()
        let boardView = BoardView(size: self.size, width: 300)

        self.view.addSubview(boardView)
        self.boardView = boardView
        boardView.center = CGPoint(x: view.bounds.midX, y: 200)
        boardView.autoresizingMask = [.flexibleLeftMargin]
        
        
        let addButtonsStack = UIStackView()
        self.view.addSubview(addButtonsStack)
        addButtonsStack.axis = .vertical
        addButtonsStack.distribution = .fill
        addButtonsStack.alignment = .center
        addButtonsStack.spacing = 4
        
        addButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        addButtonsStack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        addButtonsStack.trailingAnchor.constraint(equalTo: boardView.leadingAnchor, constant: 10).isActive = true
        addButtonsStack.topAnchor.constraint(equalTo: boardView.topAnchor).isActive = true
        
        for row in 0...3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fill
            rowStack.alignment = .center
            rowStack.spacing = 4
            
            for col in 0...3 {
                let button = AddButton(position: (row,col))
                button.backgroundColor = .red
                button.setTitle( "\(row)-\(col)", for: .normal)
                button.setTitleColor(UIColor.white, for: .normal)
                button.titleLabel!.font = UIFont.boldSystemFont(ofSize: 12)
                button.layer.cornerRadius = 8.0
                button.addTarget(self, action: #selector(self.numberButtonDidPress), for: .touchUpInside)

                rowStack.addArrangedSubview(button)
            }
            addButtonsStack.addArrangedSubview(rowStack)
        }

        let valueSlider = UISlider()
        self.view.addSubview(valueSlider)
        self.valueSlider = valueSlider
        valueSlider.maximumValue = 10
        valueSlider.minimumValue = 0
        valueSlider.value = Float(addTileValue)
        valueSlider.tintColor = .brown
        valueSlider.translatesAutoresizingMaskIntoConstraints = false
        valueSlider.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        valueSlider.trailingAnchor.constraint(equalTo: boardView.leadingAnchor, constant: -10).isActive = true
        valueSlider.topAnchor.constraint(equalTo: addButtonsStack.bottomAnchor, constant: 10).isActive = true
        valueSlider.addTarget(self, action: #selector(self.valueSliderDidChange(_:)), for: .valueChanged)

        let valueSliderLabel = UILabel()
        self.view.addSubview(valueSliderLabel)
        self.valueSliderLabel = valueSliderLabel
        valueSliderLabel.text = "Value: \(addTileValue)"
        valueSliderLabel.textColor = .brown
        valueSliderLabel.font = UIFont.boldSystemFont(ofSize: 10)
        valueSliderLabel.textAlignment = NSTextAlignment.center
        valueSliderLabel.translatesAutoresizingMaskIntoConstraints = false
        valueSliderLabel.topAnchor.constraint(equalTo: valueSlider.bottomAnchor, constant: 4).isActive = true
        valueSliderLabel.centerXAnchor.constraint(equalTo: valueSlider.centerXAnchor).isActive = true
        
        let makeMoveSwitch = UISwitch()
        self.view.addSubview(makeMoveSwitch)
        self.makeMoveSwitch = makeMoveSwitch
        makeMoveSwitch.isOn = true
        makeMoveSwitch.translatesAutoresizingMaskIntoConstraints = false
        makeMoveSwitch.topAnchor.constraint(equalTo: valueSliderLabel.bottomAnchor, constant: 4).isActive = true
        makeMoveSwitch.centerXAnchor.constraint(equalTo: valueSliderLabel.centerXAnchor).isActive = true
        
        let backupBtn = UIButton()
        self.view.addSubview(backupBtn)
        backupBtn.backgroundColor = .brown
        backupBtn.setTitle("Backup", for: .normal)
        backupBtn.setTitleColor(UIColor.white, for: .normal)
        backupBtn.titleLabel!.font = UIFont.boldSystemFont(ofSize: 12)
        backupBtn.layer.cornerRadius = 8.0
        backupBtn.addTarget(self, action: #selector(self.backup(_:)), for: .touchUpInside)
        backupBtn.translatesAutoresizingMaskIntoConstraints = false
        backupBtn.centerXAnchor.constraint(equalTo: valueSliderLabel.centerXAnchor).isActive = true
        backupBtn.topAnchor.constraint(equalTo: makeMoveSwitch.bottomAnchor, constant: 10).isActive = true
        
        let scoreView = UILabel()
        self.view.addSubview(scoreView)
        self.scoreView = scoreView
        scoreView.text = "Score: 0"
        scoreView.textColor = .brown
        scoreView.font = UIFont.boldSystemFont(ofSize: 10)
        scoreView.textAlignment = NSTextAlignment.center
        scoreView.translatesAutoresizingMaskIntoConstraints = false
        scoreView.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: 10).isActive = true
        scoreView.centerXAnchor.constraint(equalTo: boardView.centerXAnchor).isActive = true
        
        let intLabel = UILabel()
        self.view.addSubview(intLabel)
        intLabel.text = "Intelligence:"
        intLabel.textColor = .brown
        intLabel.font = UIFont.boldSystemFont(ofSize: 20)
        intLabel.translatesAutoresizingMaskIntoConstraints = false
        intLabel.topAnchor.constraint(equalTo: scoreView.bottomAnchor, constant: 20).isActive = true
        intLabel.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true

        let intSlider = UISlider()
        self.view.addSubview(intSlider)
        self.intSlider = intSlider
        intSlider.maximumValue = 100
        intSlider.minimumValue = 0
        intSlider.value = Float(intelligence)
        intSlider.tintColor = .brown
        intSlider.translatesAutoresizingMaskIntoConstraints = false
        intSlider.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true
        intSlider.trailingAnchor.constraint(equalTo: boardView.trailingAnchor).isActive = true
        intSlider.topAnchor.constraint(equalTo: intLabel.bottomAnchor, constant: 10).isActive = true
        intSlider.addTarget(self, action: #selector(self.intSliderDidChange(_:)), for: .valueChanged)
//
        let delayLabel = UILabel()
        self.view.addSubview(delayLabel)
        delayLabel.text = "Delay Per Move:"
        delayLabel.textColor = .brown
        delayLabel.font = UIFont.boldSystemFont(ofSize: 20)
        delayLabel.translatesAutoresizingMaskIntoConstraints = false
        delayLabel.topAnchor.constraint(equalTo: intSlider.bottomAnchor, constant: 20).isActive = true
        delayLabel.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true

        let delaySlider = UISlider()
        self.view.addSubview(delaySlider)
        self.delaySlider = delaySlider
        delaySlider.maximumValue = 1
        delaySlider.minimumValue = 0
        delaySlider.value = Float(delay)
        delaySlider.tintColor = .brown
        delaySlider.translatesAutoresizingMaskIntoConstraints = false
        delaySlider.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true
        delaySlider.trailingAnchor.constraint(equalTo: boardView.trailingAnchor).isActive = true
        delaySlider.topAnchor.constraint(equalTo: delayLabel.bottomAnchor, constant: 10).isActive = true
        delaySlider.addTarget(self, action: #selector(self.delaySliderDidChange(_:)), for: .valueChanged)

        let buttonsStack = UIStackView()
        self.view.addSubview(buttonsStack)
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .fill
        buttonsStack.alignment = .center
        buttonsStack.spacing = 8
        
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        buttonsStack.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true
        buttonsStack.trailingAnchor.constraint(equalTo: boardView.trailingAnchor).isActive = true
        buttonsStack.topAnchor.constraint(equalTo: delaySlider.bottomAnchor, constant: 40).isActive = true
        
        
        let resetBtn = UIButton()
        resetBtn.backgroundColor = .brown
        resetBtn.setTitle("Reset", for: .normal)
        resetBtn.setTitleColor(UIColor.white, for: .normal)
        resetBtn.titleLabel!.font = UIFont.boldSystemFont(ofSize: 12)
        resetBtn.layer.cornerRadius = 8.0
        resetBtn.addTarget(self, action: #selector(self.reset), for: .touchUpInside)
//        resetBtn.translatesAutoresizingMaskIntoConstraints = false
//        resetBtn.leadingAnchor.constraint(equalTo: boardView.leadingAnchor).isActive = true
//        resetBtn.topAnchor.constraint(equalTo: delaySlider.bottomAnchor, constant: 40).isActive = true
        buttonsStack.addArrangedSubview(resetBtn)
        
        let solverBtn = UIButton()
        self.view.addSubview(solverBtn)
        self.solverBtn = solverBtn
        solverBtn.backgroundColor = .green
        solverBtn.setTitle("Start AI", for: .normal)
        solverBtn.setTitleColor(UIColor.white, for: .normal)
        solverBtn.titleLabel!.font = UIFont.boldSystemFont(ofSize: 12)
        solverBtn.layer.cornerRadius = 8.0
        solverBtn.addTarget(self, action: #selector(self.solveButtonDidPress), for: .touchUpInside)
//        solverBtn.translatesAutoresizingMaskIntoConstraints = false
//        solverBtn.leadingAnchor.constraint(equalTo: resetBtn.trailingAnchor, constant: 10).isActive = true
//        solverBtn.topAnchor.constraint(equalTo: delaySlider.bottomAnchor, constant: 40).isActive = true
        buttonsStack.addArrangedSubview(solverBtn)
        
        let solverOneBtn = UIButton()
        self.view.addSubview(solverOneBtn)
        self.solverOneBtn = solverOneBtn
        solverOneBtn.backgroundColor = .green
        solverOneBtn.setTitle("Start AI Once", for: .normal)
        solverOneBtn.setTitleColor(UIColor.white, for: .normal)
        solverOneBtn.titleLabel!.font = UIFont.boldSystemFont(ofSize: 12)
        solverOneBtn.layer.cornerRadius = 8.0
        solverOneBtn.addTarget(self, action: #selector(self.solveButtonOnceDidPress), for: .touchUpInside)
//        solverOneBtn.translatesAutoresizingMaskIntoConstraints = false
//        solverOneBtn.leadingAnchor.constraint(equalTo: solverBtn.trailingAnchor, constant: 10).isActive = true
//        solverOneBtn.trailingAnchor.constraint(equalTo: boardView.trailingAnchor).isActive = true
//        solverOneBtn.topAnchor.constraint(equalTo: delaySlider.bottomAnchor, constant: 40).isActive = true
        buttonsStack.addArrangedSubview(solverOneBtn)
        
        
        //game!.addRandTile()
        //game!.addRandTile()
  
        // setDefaults()
    }
    
    @objc func reset() {
        solverRunning = false
        boardView!.reset()
        game!.reset()
            
        if let board = backupBoard {
            for row in board {
                for tile in row {
                    if !tile.isEmpty {
                        game!.addTile(at: tile.position, value: tile.value)
                    }
                }
            }
        }
        
//        if let tiles = backupTiles {
//            for tile in tiles {
//                if !tile.isEmpty {
//                    game!.addTile(at: tile.position, value: tile.value)
//                }
//            }
//        }
//
        // game!.addTile(at: (1,0), value: 2)
       // game!.addTile(at: (3,2), value: 2)
        
//        game!.addRandTile()
//        game!.addRandTile()
//       setDefaults()
    }
    
    func setDefaults() {
        /*
         2 - 0
         4 - 1
         8 - 2
         16 - 3
         32 - 4
         64 - 5
         128 - 6
         256 - 7
         512 - 8
         1024 - 9
         2048 - 10
         */
        
        
        game!.addTile(at: (0,0), value: 4)
        game!.addTile(at: (0,1), value: 2)
        game!.addTile(at: (0,2), value: 8)
        game!.addTile(at: (0,3), value: 8)

//        game!.addTile(at: (1,0), value: 2)
        game!.addTile(at: (1,1), value: 128)
//        game!.addTile(at: (1,2), value: 64)
//        game!.addTile(at: (1,3), value: 512)

        game!.addTile(at: (2,0), value: 1024)
        game!.addTile(at: (2,1), value: 32)
//        game!.addTile(at: (2,2), value: 4)
//        game!.addTile(at: (2,3), value: 8)

        game!.addTile(at: (3,0), value: 2)
        game!.addTile(at: (3,1), value: 16)
//        game!.addTile(at: (3,2), value: 2)
        game!.addTile(at: (3,3), value: 2)
        
        backupBoard = Engine.cloneBoard(board: game!.board)
    }

    func makeMove(direction d: Direction!, addRandom: Bool = false) {
        _ = game!.move(direction: d, addRandom: addRandom)
        let isOver = game!.isGameOver()
        if isOver {
            solverRunning = false
        } else if solverRunning {
            makeSolverMove()
        }
    }
    
    func makeSolverMove() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            if self.solverRunning {
//                self.solveButtonDidPress(self.solverBtn)
                let bestMove = self.solver!.findBestMove()
                self.makeMove(direction: bestMove, addRandom: true)
            }
        }
    }
    
    func makeSolverMoveOnce() {
        if !self.solverRunning {
            let bestMove = self.solver!.findBestMove()
            self.makeMove(direction: bestMove)
        }
    }
    
    func scoreChanged(to s: Int) {
        score = s
    }
    
    @objc func backup(_ sender:UIButton!) {
        backupBoard = Engine.cloneBoard(board: game!.board)
    }
    
    @objc func intSliderDidChange(_ sender:UISlider!) {
        intelligence = Int(round(sender.value))
    }
    
    @objc func delaySliderDidChange(_ sender:UISlider!) {
        delay = Double(sender.value)
    }
    
    @objc func valueSliderDidChange(_ sender:UISlider!) {
        addTileValue = Int(sender.value)
        valueSliderLabel!.text = "Value: \(addTileValue)"
    }
    
    @objc func solveButtonDidPress(_ sender:UIButton!) {
        if (solverRunning) {
            solverRunning = false
        } else {
            solverRunning = true
            makeSolverMove()
        }
    }
    
    @objc func solveButtonOnceDidPress(_ sender:UIButton!) {
        if !solverRunning {
            makeSolverMoveOnce()
        }
    }
    
    @objc func numberButtonDidPress(_ sender:AddButton!) {
        let value = pow(2,addTileValue+1)
        
        let added = game!.addTile(at: sender.position, value: Int(truncating: NSDecimalNumber(decimal: value)))
        
        if !solverRunning && added && self.makeMoveSwitch!.isOn {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                self.makeSolverMoveOnce()
            }
        }
    }
    
    func tileMoved(from: Position, to: Position, value: Int) {
        boardView!.moveTile(from: from, to: to, value: value)
    }
    
    func tileAdded(at position: Position, value: Int) {
        boardView!.insertTile(at: position, value: value)
    }

    @objc(up:)
    func upCommand(_ r: UIGestureRecognizer!) {
        makeMove(direction: .UP)
    }
    
    @objc(down:)
    func downCommand(_ r: UIGestureRecognizer!) {
        makeMove(direction: .DOWN)
    }
    
    @objc(left:)
    func leftCommand(_ r: UIGestureRecognizer!) {
        makeMove(direction: .LEFT)
    }
    
    @objc(right:)
    func rightCommand(_ r: UIGestureRecognizer!) {
        makeMove(direction: .RIGHT)
    }
}
