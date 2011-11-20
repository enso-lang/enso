
module Vars
  def eval_EVar(env, *args)
    env[name]
  end
  def render_EVar(*args)
    "#{name}"
  end
end

