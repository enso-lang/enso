
module Dispatch1

  def method_missing(method_sym, obj, arguments=nil, &block)
      if respond_to?("#{method_sym}_#{obj.schema_class.name}")
        m = method("#{method_sym}_#{obj.schema_class.name}".to_sym)
        fields = m.parameters.select{|k,v|k==:req}.map{|k,v|v.to_s}

        params = []
        fields.each do |f|
          params << obj[f]
        end

        m.call(*params, arguments)
      #elsif !obj.schema_class.supers.empty?
        #do superclass lookup
      elsif respond_to?("#{method_sym}_?")
        m = method("#{method_sym}_#{obj.schema_class.name}".to_sym)
        fields = obj.schema_class.fields

        params = []
        fields.each do |f|
          params << obj[f.name]
        end

        m.call(params, arguments)
      else
        super
      end
  end
end
