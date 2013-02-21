# -*-ruby-*-

# RUBYOPT="-I." thin start -V -D --stats . -R apps/web/code/serve.ru

require 'apps/web/code/toplevel'

require 'logger'

log = Logger.new($stderr)

# TODO: detect when thin is debug mode, otherwise use WARN
log.level = Logger::WARN

app = Web::EnsoWeb.new(ENV['WEB'], ENV['ROOT'], log)
#use Rack::CommonLogger

# TODO: this is PetStore specific.
use Rack::Static, :urls => ["/static"], :root => "applications/PetStore"

run app
