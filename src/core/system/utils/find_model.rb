require 'enso'

module FindModel
  def self.file_map
    if @file_map.nil?
      @file_map = File.load_file_map
    end
    @file_map
  end

  def self.find_model(model, &block)
    path = file_map[model]
    raise "File not found #{model}" unless path
    block.call path
  end
end
