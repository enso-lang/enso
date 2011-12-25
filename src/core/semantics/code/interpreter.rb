=begin
Base interpreter container. Operations must be rolled in before it is used
=end

class Interpreter
  def initialize(*mods)
    mods.each {|mod| extend(mod)}
  end
end
