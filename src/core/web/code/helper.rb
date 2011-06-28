

module Helpers
  def call_to_url(name, formals, args)
    q = args_to_query(formals, args)
    q.empty? ? name : "#{name}?#{q}"
  end

  def args_to_query(formals, args)
    params = []      
    formals.each_with_index do |frm, i|
      arg = args[i].path || args[i].value
      params << "#{frm.name}=#{URI.escape(arg)}"
    end
    params.empty? ? "" : "#{params.join('&')}"
  end

  def tag(name, attrs, out)
    out << "<#{name}"
    attrs.each do |k, v|
      out << " #{k}=\"#{@coder.encode(v)}\""
    end
    if block_given? then
      out << ">"
      yield
      out << "</#{name}>"
    else
      out << " />"
    end
  end
end
