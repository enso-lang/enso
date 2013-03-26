
module DeformatGrammar

  def self.deformat(grammar)
    Deformatter.new.remove_formatting(grammar)
  end


  class Deformatter
    
    def remove_formatting(x)
      if is_formatting?(x) then
        $stderr << "WARNING: *not* removing formatting #{x}\n"
      elsif respond_to?(x.schema_class.name)
        send(x.schema_class.name, x)
      end
    end
    
    def Grammar(this)
      this.rules.each do |x|
        remove_formatting(x.arg)
      end
    end
    
    def Sequence(this)
      del = []
      this.elements.each do |x|
        if is_formatting?(x) then
          del << x
        else
          remove_formatting(x)
        end
      end
      del.each do |x|
        this.elements.delete(x)
      end
    end

    def Alt(this)
      this.alts.each do |x|
        remove_formatting(x)
      end
    end

    def Create(this)
      remove_formatting(this.arg)
    end

    def Field(this)
      remove_formatting(this.arg)
    end
    
    def Regular(this)
      remove_formatting(this.arg)
      if this.sep && is_formatting?(this.sep) then
        this.sep = nil
      elsif this.sep then
        remove_formatting(this.sep)
      end
    end

    def is_formatting?(x)
      %w(NoSpace Indent Break).include?(x.schema_class.name)
    end    
  end

end
