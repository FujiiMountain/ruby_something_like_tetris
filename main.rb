require 'curses'

class App
  C = Curses
  BLIND = 5

  # [y_value, x_value, 回転軸 or 正x軸を基準としたときの角度]
  Blocks = [
    #[[0, 0, false], [0, 1, false], [2, 0, false], [2, 1, false]], # delete確認用 ブロック一段とばし
    [[0, 0, Math::PI/2], [1, 0, Math::PI/2], [2, 0, true], [3, 0, Math::PI/2 * 3]],
    [[0, 0, false], [1, 0, false], [0, 1, false], [1, 1, false]],
    [[0, 0, Math::PI/2 * 2], [0, 1, true], [0, 2, Math::PI/2 * 0], [1, 1, Math::PI/2 * 3]]
  ]

  def initialize(index)
    @index = index
    @board = Array.new(index + BLIND, Array.new(index, 0))
    @time = 1
    period
    view_init
  end

  def period
    y_max = 0
    block = Blocks[rand(Blocks.size)]
    block.each do |y, x, o|
      y_max = y if y_max < y
    end
    blind = BLIND - y_max
    block = block.map { |y, x, o| [y + blind, x + @index / 2, o] }
    @block = block
  end

  def move?(block_change)
    block_change.each do |bl|
      # boardをはみ出しているか
      if @board[bl[0]] == nil
        return false
      end
      if bl[0] > @board.size || 0 > bl[0] || bl[1] > @board[bl[0]].size || 0 > bl[1]
        return false
      end
      # boardのその場所の値が0以外であるか
      if @board[bl[0]][bl[1]] != 0
        return false
      end
    end
  end

  def fall
    block_change = @block.map { |y, x, o| [y + 1, x, o] }
    if move?(block_change)
      @block = block_change
    else
      # インスタンス変数に直接代入するとバグが起きる
      # -> ローカル変数に代入した後それをインスタンス変数に代入
      board_change = @board.map { |bo| bo.map { |b| b } }
      @block.each do |y, x|
        board_change[y][x] = 2
      end
      @board = board_change
      period
    end
  end

  # ブロック動作
  # 左 
  def left
    block_change = @block.map { |y, x, o| [y, x - 1, o] }
    if move?(block_change)
      @block = block_change
    end
  end

  # 右
  def right
    block_change = @block.map { |y, x, o| [y, x + 1, o] }
    if move?(block_change)                                                                                                                    
      @block = block_change
    end
  end

  # 下
  def down
    block_change = @block.map { |y, x, o| [y + 1, x, o] }
    if move?(block_change)                                                                                                                    
      @block = block_change
    end
  end

  # 要修正
  # 下まで落下
  def falldown
    # 落下距離の決定
    min_length = 0
    @block.each do |bl|
      count = @board.size - 1 - bl[0]
      break if count < 1
      count.times do |c|
        if @board[c + bl[0]][bl[1]] != 0
          min_length = c if min_length < c
          break
        end
      end
      min_length = count if min_length < count
    end
    # 移動
    block_change = @block
    for i in 0..(block_change.size - 1) do
      block_change[i][0] = block_change[i][0] + min_length
    end
    if move?(block_change)
      @block = block_change
    else
      # ボード変更
      @block.each do |bl|
        @board[bl[0]][bl[1]] = 2
      end
      period
    end
  end

  def leftturn
    block_change = @block.map { |bl| bl.map { |b| b } }
    for i in 0..(block_change.size - 1) do 
      if block_change[i][2] == true
        x_base = block_change[i][1]
        y_base = block_change[i][0]
      end
    end
    for i in 0..(block_change.size - 1) do
      if block_change[i][2] == true
        next
      elsif block_change[i][2] == false
        return
      end
      # 回転行列から
      x_sub = block_change[i][1] - x_base
      y_sub = block_change[i][0] - y_base
      block_change[i][1] = (x_sub * Math.cos((-1) * Math::PI/2) - y_sub * Math.sin((-1) * Math::PI/2)).round + x_base
      block_change[i][0] = (x_sub * Math.sin((-1) * Math::PI/2) + y_sub * Math.cos((-1) * Math::PI/2)).round + y_base
      # 角度プラス
      block_change[i][2] = block_change[i][2] - Math::PI/2
    end
    if move?(block_change)
      @block = block_change
    end
  end

  def rightturn
    block_change = @block.map { |bl| bl.map { |b| b } }
    for i in 0..(block_change.size - 1) do 
      if block_change[i][2] == true
        x_base = block_change[i][1]
        y_base = block_change[i][0]
      end
    end
    for i in 0..(block_change.size - 1) do
      if block_change[i][2] == true
        next
      elsif block_change[i][2] == false
        return
      end
      # 回転行列から
      x_sub = block_change[i][1] - x_base
      y_sub = block_change[i][0] - y_base
      block_change[i][1] = (x_sub * Math.cos(Math::PI/2) - y_sub * Math.sin(Math::PI/2)).round + x_base
      block_change[i][0] = (x_sub * Math.sin(Math::PI/2) + y_sub * Math.cos(Math::PI/2)).round + y_base
      # 角度プラス
      block_change[i][2] = block_change[i][2] + Math::PI/2
    end
    if move?(block_change)
      @block = block_change
    end
  end

  def view_init
    # C = Curses
    C.init_screen
    # 上部分
    C.addstr("+")
    C.addstr("-" * @index) 
    C.addstr("+\n")
    # 外枠とblockとboard
    #@board.each_with_index do |bo, i|
    for i in BLIND..@board.size-1 do
      C.addstr("|")
      @board[i].each_with_index do |b, j|
        if b == 0
          C.addstr(" ")
          next
        elsif b == 2
          C.addstr("@")
          #C.color_pair(1)
          next
        end 
        @block.each do |bl|
          C.addstr("O") if bl[0] == i && bl[1] == j
          #C.color_pair(2) if bl[0] == i && bl[1] == j
        end
      end 
      C.addstr("|\n")
    end 
    # 下部分
    C.addstr("+")
    C.addstr("-" * @index) 
    C.addstr("+\n")
    C.refresh
  end

  def view
    # C = Curses
    # C.init_screen
    C.clear
    # 上部分
    C.addstr("+")
    C.addstr("-" * @index) 
    C.addstr("+\n")
    # 外枠とblockとboard
    f = 0
    #@board.each_with_index do |bo, i|
    for i in BLIND..@board.size-1 do
      C.addstr("|")
      @board[i].each_with_index do |b, j|
        @block.each do |bl|
          if bl[0] == i && bl[1] == j
            C.addstr("O")
            f = 1
          end
        end
        if f == 1
          f = 0
          next
        end
        if b == 0
          C.addstr(" ")
          next
        elsif b == 2
          C.addstr("@")
          next
        end
        #@block.each do |bl|
          #C.addstr("O") if bl[0] == i && bl[1] == j
        #end
      end
      C.addstr("|\n")
    end
    # 下部分
    C.addstr("+")
    C.addstr("-" * @index) 
    C.addstr("+\n")
    C.refresh
  end

  def delete
    @board.each_with_index do |bo, y|
      if bo.all? { |b| b != 0 }
        for y2 in 0..y-1
          @board[y-y2] = @board[y - y2 - 1]
        end
        @board[0] = @board[0].map do |b|
          b = 0
        end
      end
    end
  end

  def move(command)
    case command
    when "h"
      left
    when "l"
      right
    when "j"
      down
    when "k"
      #falldown
    when "a"
      leftturn
    when "s"
      rightturn
    when "q"
      C.close_screen
      exit
    end
  end

  def run
    m = Mutex.new
    loop do
      Thread.new do
        loop do
          m.synchronize do
            fall
            delete
            view
          end
          gameover
          sleep @time
        end
      end

      loop do
        move(C.getch.to_s)
        m.synchronize do
          delete
          view
        end
        gameover
      end
    end
  end

  def gameover
    f = 0
    board_check = @board.map { |bo| bo.map { |b| b } }
    for i in 0..BLIND-1 do
      board_check[i].each do |b|
        if b == 2
          f = 1
          break
        end
      end
      break if f == 1
    end

    if f == 1
      C.clear
      # 上部分
      C.addstr("+")
      C.addstr("-" * @index)
      C.addstr("+\n")
      # 外枠とblockとboard
      #@board.each_with_index do |bo, i|
      for i in BLIND..@board.size-1 do
        C.addstr("|")
        @board[i].each_with_index do |b, j|
          if i == @board.size - BLIND #&& j == @board[i].size - BLIND
            C.addstr("GAME OVER!")
            break
          end
          C.addstr(" ")
        end
        C.addstr("|\n")
      end 
      # 下部分
      C.addstr("+")
      C.addstr("-" * @index)
      C.addstr("+\n")
      C.refresh
      sleep 1
      exit
    end
  end
end

App.new(10).run
