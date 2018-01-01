

class WebUI
  @name
  
  def initialize(name)
    @name = name
  end
  
  def get_query(request)
    return nil
  end
  
  def present(request, data)
    return "this is where the app goes!"
  end
end
