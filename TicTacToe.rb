require_relative "Game"
require "csv"
require "fileutils"

class TicTacToe < Game
  def initialize
    @name = "TicTacToe"
    @state = Array.new(3) {Array.new(3, 0)}
    @turn = 1
    @humanturn = -1 #only used in computer games
    @compturn = -1 #only used in computer games
    @mode = "" #becomes HUMAN or COMPUTER
  end
  #display the current board on the screen
  def displayState(position)
    print "\n"
    for x in 0..2
      for y in 0..2
        print position[x][y].to_s+" "
      end
      print "\n"
    end
    print "\n"
  end
  #message to print when the game starts
  def opening
    puts "Welcome to TicTacToe! You can play with a human or computer opponent."
    while true
      puts "If you would like to play against a human, type \"human\"."
      puts "If you would like to play against the computer, type \"computer\"."
      @mode = gets.strip.upcase
      if @mode == "HUMAN"
        break
      elsif @mode == "COMPUTER"
        @humanturn = rand(1..2)
        @compturn = (@humanturn%2) + 1
        puts "You are Player " + @humanturn.to_s + "."
        puts "The computer is Player " + @compturn.to_s + "."
        break
      else
        puts "That is not a valid input."
      end
    end
  end

  #displays help information for making a turn
  def printHelp
    puts "\n-----------------------"
    puts "There are nine possible moves in TicTacToe, indicated by the numbers 1 through 9 as shown below:"
    helparr = [[1,2,3],[4,5,6],[7,8,9]]
    displayState(helparr)
    puts "Simply state a number (1-9) to play in the corresponding location."
  end
  #returns true if board is full, false otherwise
  def fullBoard(position)
    for x in 0..2
      for y in 0..2
        if position[x][y] == 0
          return false
        end
      end
    end
    return true
  end
  #returns an array of possible moves, 1 to 9
  def possibleMoves(position)
    moves = []
    for x in 0..2
      for y in 0..2
        if position[x][y]==0
          moves << 3*x + y + 1 #board labeled 1 - 9
        end
      end
    end
    return moves
  end
  #input is state in array form
  #returns a hash of the possible new states in string form, which map to their corresponding moves (1-9)
  def possibleStates(currentstate)
    states = {}
    for p in possibleMoves(currentstate)
      newstate = makeMove(p, currentstate, false)
      states[stateToString(newstate)] = p
    end
    return states
  end
  #checks if game is over, returns winner if true, returns -1 if tie, returns 0 if false
  def gameOver(position)
    #horizontal rows
    for x in 0..2
      if position[x][0]!=0 and position[x][0]==position[x][1] and position[x][1]==position[x][2]
        return position[x][0]
      end
    end
    #vertical rows
    for y in 0..2
      if position[0][y]!=0 and position[0][y]==position[1][y] and position[1][y]==position[2][y]
        return position[0][y]
     end
    end
    #diagonals
    if position[0][0]!=0 and position[0][0]==position[1][1] and position[1][1]==position[2][2]
      return position[0][0]
    end
    if position[2][0]!=0 and position[2][0]==position[1][1] and position[1][1]==position[0][2]
      return position[2][0]
    end
    if fullBoard(position)
      return -1
    end
    return 0
  end
  #returns a random move from list of possible moves
  def getRandomMove(position)
    posmoves = possibleMoves(position)
    randmove = rand(0..posmoves.size-1)
    return posmoves[randmove]
  end
  #convert state to 9-char string
  def stateToString(position)
    retVal = ""
    for x in 0..2
      for y in 0..2
        retVal+=(position[x][y].to_s)
      end
    end
    return retVal
  end
  #converts 9-char string to state
  def stringToState(position)
    state = Array.new(3) {Array.new(3,0)}
    count = 0
    for x in 0..2
      for y in 0..2
        state[x][y] = position[count].to_i
        count+=1
      end
    end
    return state
  end
  #expected value
  def getExpectedValue(turn, p1num, p2num, drawnum)
    total = p1num+p2num+drawnum
    if turn == 1
      return (p1num+drawnum*0.5)/total
    elsif turn == 2
      return (p2num+drawnum*0.5)/total
    end
  end
  #returns the computers sugguested move
  def getCompMove(filename, position)
    #iterate through each of the possible moves, making a new position string for each
    #get the effective value of each new position
    #update best_move to the position with the best effective value
    pos_moves = possibleMoves(position)
    best_move = -1
    best_move_effective_score = 0.0
    new_positions = {}
    #get all the possible new positions as keys, set their values to the correponding move
    for m in pos_moves
      new_pos = stateToString(makeMove(m, position, false))
      new_positions[new_pos]=m
    end
    #try to find the positions in the database, update their effective score
    CSV.foreach(filename) do |row|
      if new_positions.key?(row[0])
        if @turn == 1
          ev = row[1].to_f
        elsif @turn == 2
          ev = 1-(row[1].to_f)
        end
        if ev >= best_move_effective_score
          best_move_effective_score = ev
          best_move = new_positions[row[0]]
        end
      end
    end
    if best_move > 0
      return best_move
    else
      return getRandomMove(position)
    end
  end
  #takes a hash of states and their p1/p2/draw values and stores in a .csv file
  def createCSVFromStates(states, filename, numgames)
    CSV.open(filename, "wb"){ |f|
      #initialize the file
      f << ["total_games", numgames.to_s]
      f << ["state", "p1_win_prob"]
      #iterate through each state in the hash, adding it to the data file
      states.each do |key, value|
        f << [key, value]
      end
    }
  end
  #training with primitive reinforcement learning
  #records positions, intitializing prob of p1 winning for each position to .5 unless a win or lose position
  #updates probabilities through self-play with temporal-difference learning
  #epsilon parameter is the probablity exploration is chosen over greed
  #alpha parameter is the update magnitude in temporal-difference i.e. V(S_t)=V(S_t)+a[V(S_t+1)-V(S_t)]
  #first few pages of http://www.andrew.cmu.edu/course/10-703/textbook/BartoSutton.pdf
  def trainAI_RL(numgames, epsilon, alpha)
    @mode = "TRAINING_RL"
    #hash of states with key/value position(str)/prob of p1 win pairs
    statehash = {}
    for i in 1..numgames
      #reset state/turn to default
      @state = Array.new(3) {Array.new(3, 0)}
      @turn = 1
      #smaller hash of the positions and probabilities this game
      stateprobs = {}
      #list of positions that came from being explored
      exploredpositions = []
      #play through a game, update the probabilities for each state at the end of the game
      while true
        #get the possible states / move pairs for this turn
        posstates = possibleStates(@state)
        #puts posstates.keys
        #determine exploration or exploitation for this turn
        randval = rand
        #explore with random move, add to stateprobs
        if rand <= epsilon
          newpos = posstates.keys.shuffle.first
          if statehash.key?(newpos)
            stateprobs[newpos]=statehash[newpos]
          else
            gval = gameOver(stringToState(newpos))
            #prob p1 win is 1
            if gval==1
              stateprobs[newpos]=1
            #prob p1 win is 0
            elsif gval==2
              stateprobs[newpos]=0
            #unfinished game or draw
            else
              stateprobs[newpos]=0.5
            end
          end
          exploredpositions << newpos
        #exploit with move of greatest probability, add to stateprobs
        else
          newpos = ""
          probmax = 0.0
          probmin = 1.0
          #iterate through each possible state
          #find the one with the greatest/least (depending on player) probability of p1 winning (new is .5 or 0/1 for a win)
          for s, m in posstates #state (string), move

            #get the current probability for the given position
            if statehash.key?(s)
              currentprob = statehash[s]
            else
              gval = gameOver(stringToState(s))
              if gval == 1
                currentprob = 1
              elsif gval == 2
                currentprob = 0
              else
                currentprob = 0.5
              end
            end

            #update if the current probability is better than the previous best
            if @turn == 1
              if currentprob >= probmax
                probmax = currentprob
                newpos = s
              end
            elsif @turn == 2
              if currentprob <= probmin
                probmin = currentprob
                newpos = s
              end
            end
          end
          if @turn == 1
            stateprobs[newpos] = probmax
          elsif @turn == 2
            stateprobs[newpos] = probmin
          end
        end
        #do the turn
        makeMove(posstates[newpos], @state)
        #check if game is over
        if gameOver(@state)!=0
          #update probs
          for j in 0..stateprobs.size-2
            poslow = stateprobs.keys.reverse[j] #lower in the tree, updater
            poshigh = stateprobs.keys.reverse[j+1] #higher in the tree, updatee
            if !(exploredpositions.include?(poslow)) #updater must not be an experimental position
              stateprobs[poshigh] = stateprobs[poshigh] + alpha*(stateprobs[poslow]-stateprobs[poshigh])
            end
          end
          break
        end
        @turn = (@turn%2)+1
      end
      #add the updated probabilities to the overall hash
      for p in stateprobs.keys
        statehash[p] = stateprobs[p]
      end
      if(i%10000==0)
        puts "Game "+i.to_s+" complete."
      end
    end

    filename = "data_tictactoe_RL"
    backup_folder = "backups_RL"
    createCSVFromStates(statehash, filename+".csv", numgames)
    #save current data file as a backup with date and time as name marker
    FileUtils.cp(filename+".csv", backup_folder)
    time = Time.new
    FileUtils.mv(backup_folder+"/"+filename+".csv", backup_folder+"/"+filename+"_"+(time.inspect.delete(':'))+".csv")
  end
  #perform a turn
  def doTurn
    if @mode == "HUMAN"
      puts "\n-----------------------"
      puts "It is Player "+@turn.to_s+"'s turn."
      puts "Current Position:"
      displayState(@state)
      posmoves = possibleMoves(@state)
      while true
        puts "Please enter a valid move. For help making a move, type \"help\"."
        move = gets.strip
        if move.upcase == "HELP"
          printHelp
        elsif possibleMoves(@state).include? move.to_i
          makeMove(move.to_i, @state)
          break
        else
          puts "That is not a valid input."
        end
      end
    elsif @mode == "COMPUTER"
      if @turn == @humanturn
        puts "\n-----------------------"
        puts "It is your turn."
        puts "Current Position:"
        displayState(@state)
        posmoves = possibleMoves(@state)
        while true
          puts "Please enter a valid move. For help making a move, type \"help\"."
          move = gets.strip
          if move.upcase == "HELP"
            printHelp
          elsif possibleMoves(@state).include? move.to_i
            makeMove(move.to_i, @state)
            break
          else
            puts "That is not a valid input."
          end
        end
      elsif @turn == @compturn
        puts "\n-----------------------"
        puts "The computer will now make a move."
        move = getCompMove("data_tictactoe_RL.csv", @state)
        makeMove(move, @state)
        puts "The computer plays "+move.to_s+"."
      end
    elsif @mode == "TRAINING_RL"
      puts "This is a placeholder option, and may be unused."
    end
  end
  #updates the state with a new move
  #does not check if move is illegal
  #optional parameter to return a new array instead of directly modifying the position
  def makeMove(val, position, direct = true)
    x = ((val-1)/3).floor
    y = (val-1)%3
    if direct
      position[x][y]=@turn
    else
      temp = Array.new(3) {Array.new(3, 0)}
      for i in 0..2
        for j in 0..2
          temp[i][j] = position[i][j]
        end
      end
      temp[x][y] = @turn
      return temp
    end
  end

  def playGame
    opening
    while true
      doTurn
      if gameOver(@state)!=0
        break
      end
      @turn = (@turn%2)+1
    end
    if gameOver(@state) > 0
      puts "\n-----------------------"
      if @mode == "HUMAN"
        puts "The game is complete. Player "+gameOver(@state).to_s+" won!"
      elsif @mode == "COMPUTER"
        if @turn == @humanturn
          winner = "You"
        elsif @turn == @compturn
          winner = "The computer"
        end
        puts "The game is complete. "+winner+" won!"
      end

      puts "Final Board: "
      displayState(@state)
    else
      puts "The game ended in a draw."
      puts "Final Board: "
      displayState(@state)
    end
  end
end
