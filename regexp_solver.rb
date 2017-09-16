class RegexpCrosswordSolver
  def initialize(rows, cols)
    @rows = rows
    @cols = cols
    @xsize = @cols.size
    @ysize = @rows.size
  end

  def cell(x, y)
    Z3.Int("c#{x},#{y}")
  end

  def setup
    @ysize.times do |y|
      @xsize.times do |x|
        @solver.assert cell(x,y) >= " ".ord
        @solver.assert cell(x,y) <= 127
      end
    end
  end

  def print_solution
    model = @solver.model
    puts "*" * (2 + @cols.size)
    @ysize.times do |y|
      print "*"
      @xsize.times do |x|
        c = model[cell(x,y)].to_i.chr
        print c
      end
      print "*\n"
    end
    puts "*" * (2 + @cols.size)
  end

  def row_cells(y)
    (0...@xsize).map{|x| cell(x,y) }
  end

  def column_cells(x)
    (0...@ysize).map{|y| cell(x,y) }
  end

  def add_constraints
    @rows.each_with_index do |row_rx, y|
      @solver.assert row_rx.match(row_cells(y))
    end
    @cols.each_with_index do |col_rx, x|
      @solver.assert col_rx.match(column_cells(x))
    end
  end

  def solve
    @solver = Z3::Solver.new
    setup
    add_constraints
    if @solver.satisfiable?
      print_solution
    else
      puts "There is no solution"
    end
  end
end
