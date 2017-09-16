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
  end

  def |(other)
    RX::Alternative.new(self, other)
  end

  def star
    RX::Star.new(self)
  end

  def optional
    # a? is same as (|a)
    self | RX::Empty.new
  end

  def +(other)
    RX::Sequence.new(self, other)
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
