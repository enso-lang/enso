
require 'apps/web/code/web'

class DefaultActions

  # the return value of actions
  # is used to indicate redirection

  def submit_action(link)
    link
  end

  def delete_action(obj, link)
    obj.value.delete!
    link
  end

  def insert_action(obj, coll) 
    coll.value << obj.value
    nil
  end

  def check_delete_action(obj)
    obj.value.delete!
    nil
  end


end
