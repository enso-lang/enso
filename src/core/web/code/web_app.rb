require 'core/system/load/load'
require 'core/web/code/ui'
require 'core/security/code/security'

class EnsoWeb
  @name
  @ui
  @security
  @schema
  
  def initialize(name)
    @name = name
    @ui = WebUI.new(Load::load(name + '.web'))
    @security = Security.new(Load::load(name + '.auth'))
  end
  
  def process(env)
    request = Rack::Request.new(env)
 
    user = get_user(request)
    if user == null
      @ui.login()
    else
#    updates = request.get_updates()
#    if updates = null
      query = @ui.get_query(user, request)   # normal page load
      data = @security.execute(user, query)
      page = @ui.present(user, request, data)
      return page.render()
      
#     else  -- updates...
#       case SECURITY.perform_updates(updates)
#         SUCCESS:  HTTP.redirect(request.targetURL) -- redirect to prevent multiple submission
#         ERROR(err)
#           query = UI.get_query(request.originalURL)
#           data = SECURITY.execute(query)
#           page = UI.present_error(request.originalURL, data, err)
#         OPTIMISTIC_FAILURE:  
#           query = UI.get_query(request.originalURL)
#           data = SECURITY.execute(query)
#           page = UI.present_diff(request.originalURL, data, updates)
#       end
#     end
    end
  end
  
	def rack
	  lambda { |env| 
	    ['200', {'Content-Type' => 'text/html'}, [self.process(env)]]
	  }
  end
  
end

