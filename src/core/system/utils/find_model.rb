
module FindModel
  class FindModel
    def self.file_map
      if @file_map.nil?
        @file_map = File.create_file_map("..")
      end
      @file_map
    end
	def self.find_model(name, &block) 
	  if File.exists?(name)
	    block.call name
	  else
	    
	    path = file_map[name]
	    raise EOFError, "File not found #{name}" unless path
	    block.call path
	  end
	end
  end
end