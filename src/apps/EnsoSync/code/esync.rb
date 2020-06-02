require 'core/system/load/load'
require 'applications/EnsoSync/code/io'
require 'applications/EnsoSync/code/sync'
require 'core/schema/tools/diff'
require 'socket'
require 'yaml'

ENSOSYNC_PORT = 20000


def esync(server_host, name, rootpath)
  schema = Load::load('esync.schema')
  grammar = Load::load('esync.grammar')
  node_grammar = Clone(grammar)
  node_grammar.start=node_grammar.rules['Node']

  sourcename = name

  domain_str =  File.open("#{rootpath}/.source.esync", "rb") { |f| f.read }
  domain = Parse.load_raw(domain_str, grammar, schema, Factory::SchemaFactory.new(schema), false).finalize

  s1 = domain.sources[sourcename]
  newbase = read_from_fs(rootpath, s1.path, s1.factory)

  # initiate connection with server
  streamSock = TCPSocket.new(server_host, ENSOSYNC_PORT)
  streamSock.puts(name)

  puts "\nConnecting to server at #{server_host}:#{ENSOSYNC_PORT}\n"

  Layout::DisplayFormat.print(grammar, domain, base_str="")
  streamSock.puts(base_str.size.to_s)
  streamSock.send(base_str, 0)
  Layout::DisplayFormat.print(node_grammar, newbase, newbase_str="")
  streamSock.puts(newbase_str.size.to_s)
  streamSock.send(newbase_str, 0)

  #receive diffs
  s2c_str = streamSock.read(streamSock.gets[0..-2].to_i)
  s2c = YAML::load(s2c_str)
  c2s_str = streamSock.read(streamSock.gets[0..-2].to_i)
  c2s = YAML::load(c2s_str)

  #add c2s file contents
  c2s.each do |k,v|
    next unless v[0]=='+' and v[1]=='F'
    v[2] = File.open("#{rootpath}/#{k}", "rb").read
  end
  c2s_str = YAML::dump(c2s)
  streamSock.puts(c2s_str.size.to_s)
  streamSock.send(c2s_str, 0)

  #apply s2c contents
  s2c.each do |k,v|
    path = "#{rootpath}/#{k}"
    case v[0..1]
      when ['+','F']
        puts " #{fileis_a?("Exists")(path) ? "Modified" : "Created"} file #{path}"
        writeFile(path, v[2])
      when ['-','F']
        puts " Deleted file #{path}"
        deleteFile(path)
      when ['+','D']
        puts " Created directory #{path}"
        createDir(path)
      when ['-','D']
        puts " Deleted directory #{path}"
        deleteDir(path)
    end
  end

  #update base
  domain.sources[sourcename].basedir = read_from_fs(rootpath, s1.path, s1.factory)
  File.open("#{rootpath}/.source.esync", "w") { |f|
    Layout::DisplayFormat.print(grammar, domain, f)
  }

  puts "Sync successful\n"

  streamSock.close
end

def esyncd(server_host, name, rootpath)
  loop {
    esync(server_host, name, rootpath)
    sleep(30)
  }
end

daemon_mode = false
ARGV.each do |a|
  if a.start_with? '-'
    case a
      when '-d'
        daemon_mode = true
    end
  end
end

ARGV.reject!{|a|a.start_with? '-'}
name = ARGV[0]
server_host = ARGV[1]
rootpath = ARGV[2]

if daemon_mode
  esyncd(server_host, name, rootpath)
else
  esync(server_host, name, rootpath)
end
