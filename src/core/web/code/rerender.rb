 def rerender(url, errors, params, news, out)
    # todo for validations
    # - populate an "errors" variable with suitable keys
    # - render the original page with the current params as env...
    # - but not creating "new" stubs again, but using the current news
    
    log.debug "###### URL: #{url}"
    # e.g. http://localhost:3000/index
    
    if url =~ /http:\/\/[^\/]+\/([a-zA-Z0-9_]+)/ then
      func = $1
      # TODO: we also have to pass any params here
      # and add them to env
    end

    env = {}.update(@env)
    params.each do |k, v|
      if v =~ /^\./ then
        env[k] = Result.new(deref(@root, v), v)
      elsif v =~ /^@/ then
        env[k] = Result.new(news[v], v)
      else
        env[k] = Result.new(v)
      end
    end
    env['errors'] = Result.new(errors)
    env['url'] = Result.new(url)
    env[func].value.run(env, out)
  end
