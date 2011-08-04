

class Store

  def self.new?(key)
    key =~ /^@(.*):[0-9]+$/
    return $1
  end

  def initialize(factory)
    @factory = factory
    @new_count = 0
    @table = {}
  end

  def clear
    @new_count = 0
    @table.clear
  end
  
  def [](key)
    cls = Store.new?(key)
    obj, _ = create(cls, key)
    return obj
    # raise "Not a new key: #{key}" unless cls
    # @table[key] ||= @factory[cls]
  end

  def create(class_name, key = nil)
    if key.nil? then
      id = @new_count += 1 unless key
      key = "@#{class_name}:#{id}"
    end
    @table[key] ||= @factory[class_name]
    return @table[key], key
  end


end
