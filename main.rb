require_relative "TicTacToe"

NUM_GAMES = 100000000
ALPHA = 0.05
EPSILON = 0.1

def main
  t = TicTacToe.new
  t.playGame
  #t.trainAI_random(NUM_GAMES)
  #t.trainAI_RL(NUM_GAMES, EPSILON, ALPHA)
end
main
