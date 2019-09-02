require_relative 'class.rb'

class RunistClass < PlayerClass
  def initialize
    super({
      classname: "Runist",
      illegal: "Dog"
    })
  end
end