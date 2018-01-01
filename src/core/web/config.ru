# my_rack_app.rb
 
require 'rack'
require 'core/web/code/web_app'

enso = EnsoWeb.new('todo')

Rack::Handler::WEBrick.run enso.rack()
