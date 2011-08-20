
require 'core/web/code/web'
require 'core/web/code/renderable'

module Web
  class Redirect < Exception
    attr_reader :link
    
    def initialize(link)
      @link = link
    end
  end

  module ActionUtils
    def redirect(link)
      raise Redirect.new(link)
    end
  end
end


class DefaultActions
  include Web::ActionUtils
  
  def submit_action(link)
    redirect(link)
  end

  def delete_action(obj, link)
    puts "OBJ to be deleted: = #{obj.inspect}"
    obj.delete!
    redirect(link)
  end

  def check_delete_action(obj)
    obj.delete!
  end

end