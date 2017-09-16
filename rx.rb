class RX
  class << self
    def c(character)
      RX::Character.new(character)
    end
  end

  def |(other)
    RX::Alternative.new(self, other)
  end
end

class RX::Character < RX
  def initialize(c)
    @c = c.ord
  end

  def match(str)
    str.size == 1 and str[0] == @c
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
