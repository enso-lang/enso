

require 'core/web/code/xhtml'


def get(name, params, env, root, out, log)
  eval = Render.new(Expr.new, log)
  env = env.new
  params.each do |k, v|
    env[k] = Result.parse(v, root)
  end
  env[name].invoke(eval, env, out, errors)
end


def post(name, params, form, env, root, out, log)
  errors = {}
  bind(form, root, errors)
  begin
    forms.actions.each do |action|
      action.execute(form.env)
    end
  rescue Web::Redirect => e
    http.redirect(e.link.render)
  else
    get(name, params, env, root, out, log)
  end
end
