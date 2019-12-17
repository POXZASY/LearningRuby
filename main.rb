require_relative "TicTacToe"

NUM_GAMES = 100000000

def main
  t = TicTacToe.new
  t.playGame
  #t.trainAI(NUM_GAMES)
end
main
