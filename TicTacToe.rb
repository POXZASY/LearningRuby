require_relative "Game"

class TicTacToe < Game
  def initialize
    @state = Array.new(3, Array.new(3,0))
    @turn = 1
    @p1turn = -1
    @mode = ""
  end
  #display the current board on the screen
  def displayState
    for x in 0..2
      for y in 0..2
  #message to print when the game starts
  def opening
    puts "Welcome to TicTacToe! You can play with a human or computer opponent."
    while true
      puts "If you would like to play against a human, type \"human\"."
      puts "If you would like to play against the computer, type \"computer\"."
      @mode = gets.strip
      if @mode == "human" or @mode == "computer"
        @p1turn = rand(1..2)
        break
      else
        puts "That is not a valid input."
      end
    end
  end

  def doTurn
    if @mode == "human"
      puts "It is Player "+@turn.to_s+"'s turn."
      puts "Current Position:"
      displayState

    end
  end

  #returns an array of possible moves, 0 to 9
  def possibleMoves
    moves = []
    for x in 0..2
      for y in 0..2
        if @state[x][y]==0
          moves << 3*x + y + 1 #board labeled 1 - 9
        end
      end
    end
    return moves
  end
  #updates the state with a new move
  #does not check if move is illegal
  def makeMove(x, y)
    @state[x][y]=turn
  end

  def playGame
    opening
    doTurn
  end
end
