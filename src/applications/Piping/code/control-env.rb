
class ControlEnv
  include Env
  def initialize(piping)
    @piping = piping
  end
  def [](key)
    if @piping.sensors.has_key? key
      @piping.sensors[key]
    elsif @piping.elements.has_key? key
      @piping.elements[key]
    else
      @parent.nil? ? nil : @parent[key]
    end
  end
  def []=(key, value)
    if @piping.elements.has_key? key
      @piping.elements[key] = value
    else
      @parent[key] = value
    end
  end
  def each(&block)
    @piping.sensors.each do |s|
      yield s.name, s
    end
    @piping.elements.each do |e|
      yield e.name, e
    end
    @parent.each &block unless @parent.nil?
  end
end
