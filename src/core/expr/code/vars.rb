
module Vars
  def eval1_EVar(name, env, *args)
    env[name]
  end
  def render_EVar(name, *args)
    "#{name}"
  end
end

