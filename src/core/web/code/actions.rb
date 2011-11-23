
require 'core/web/code/web'

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

  def my_actions
    [:submit_action, :delete_action, :check_delete_action, :insert_action]
  end
  
  def submit_action(link)
    puts "REDIRECTING: #{link}"
    redirect(link)
  end

  def delete_action(obj, link)
    puts "OBJ to be deleted: = #{obj.inspect}"
    obj.value.delete!
    redirect(link)
  end

  def insert_action(obj, coll) 
    coll.value << obj.value
  end

  def check_delete_action(obj)
    obj.value.delete!
  end


end
