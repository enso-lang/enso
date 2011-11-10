# -*-ruby-*-

# RUBYOPT="-I." thin start -V -D --stats . -R core/web/code/serve.ru

require 'core/web/code/toplevel'

require 'logger'

log = Logger.new($stderr)

# TODO: detect when thin is debug mode, otherwise use WARN
log.level = Logger::WARN

app = Web::EnsoWeb.new("esync.web", "source.esync", log)
#use Rack::CommonLogger

use Rack::Static, :urls => ["/static"], :root => "applications/EnsoSync"

run app
=begin
Rack::Handler::WEBrick.run app,
    :urls => ["/static"],
    :port => 3000,
    :root => "applications/EnsoSync"
=end