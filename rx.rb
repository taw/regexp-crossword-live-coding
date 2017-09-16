class RX
  class << self
    def c(character)
      RX::Character.new(character)
    end

    def cclass(characters)
      RX::CharacterClass.new(characters)
    end

    def nclass(characters)
      RX::NegCharacterClass.new(characters)
    end

    def group(a, name)
      RX::Group.new(a, name)
    end

    def backref(name)
      RX::Backref.new(name)
    end

    def space
      # \s = [\t\n\v\f\r ]
      cclass("\t\n\v\f\r ")
    end
  end

  def |(other)
    RX::Alternative.new(self, other)
  end

  def star
    RX::Star.new(self)
  end

  # A+ == A A*
  def plus
    self + RX::Star.new(self)
  end

  def optional
    # a? is same as (|a)
    self | RX::Empty.new
  end

  def +(other)
    RX::Sequence.new(self, other)
  end

  def times(n)
    if n == 0
      RX::Empty.new
    else
      self + self.times(n-1)
    end
  end

  def times_or_more(n)
    if n == 0
      self.star
    else
      self + self.times_or_more(n-1)
    end
  end
end

class RX::CharacterClass < RX
  def initialize(characters)
    @characters = characters.chars.map(&:ord)
  end

  def match(str)
    return Z3.False unless str.size == 1
    Z3.Or( *@characters.map{|c| str[0] == c} )
  end
end

class RX::NegCharacterClass < RX
  def initialize(characters)
    @characters = characters.chars.map(&:ord)
  end

  def match(str)
    return Z3.False unless str.size == 1
    !Z3.Or( *@characters.map{|c| str[0] == c} )
  end
end

class RX::Character < RX
  def initialize(c)
    @c = c.ord
  end

  def match(str)
    return Z3.False unless str.size == 1
    str[0] == @c
  end
end

class RX::Alternative < RX
  def initialize(a,b)
    @a = a
    @b = b
  end

  def match(str)
    @a.match(str) | @b.match(str)
  end
end

class RX::Sequence < RX
  def initialize(a,b)
    @a = a
    @b = b
  end

  def match(str)
    # "ABC" ~ xy
    # "" ~ x    "ABC" ~ y
    # "A" ~ x    "BC" ~ y
    # "AB" ~ x    "C" ~ y
    # "ABC" ~ x    "" ~ y
    Z3.Or(*
      (0..str.size).map{|i|
        left = str[0, i]
        right = str[i..-1]
        @a.match(left) & @b.match(right)
      }
    )
  end
end

class RX::Star < RX
  def initialize(a)
    @a = a
  end

  def match(str)
    return Z3.Const(true) if str.size == 0
    # a* = empty | a a*
    Z3.Or(*
      (1..str.size).map{|i|
        left = str[0, i]
        right = str[i..-1]
        @a.match(left) & self.match(right)
      }
    )
  end
end

class RX::Empty < RX
  def match(str)
    Z3.Const(str.size == 0)
  end
end

class RX::Backref < RX
  def initialize(name)
    @name = name
  end

  def match(str)
    (Z3.Int("#{@name}-size") == str.size) & (
      (0...str.size).map{|i| str[i] == Z3.Int("#{@name}-char-#{i}")}
    ).inject(Z3.True, :&)
  end
end

class RX::Group < RX
  def initialize(a, name)
    @a = a
    @name = name
  end

  def match(str)
    @a.match(str) & (Z3.Int("#{@name}-size") == str.size) & (
      (0...str.size).map{|i| str[i] == Z3.Int("#{@name}-char-#{i}")}
    ).inject(Z3.True, :&)
  end
end
