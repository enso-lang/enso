=begin
Main executable of EnsoSync host.
Sit in tight loop waiting for someone to call me
=end

require 'applications/EnsoSync/code/io'
require 'applications/EnsoSync/code/sync'
require 'core/system/load/load'
require 'socket'
require 'yaml'

#I need:
#1. your file structure (incl root), login/hash -- and imma create a new session
#2. i'll tell you what i need + send you what you need
#3. you send me what i need
#4. i tell you we're done

ENSOSYNC_PORT = 20000

def esynchost(rootpath)

  schema = Loader.load('esync.schema')
  grammar = Loader.load('esync.grammar')
  node_grammar = Clone(grammar)
  node_grammar.start=node_grammar.rules['Node']

  server = TCPServer.open(ENSOSYNC_PORT)   # Socket to listen on port 2000
  puts "\nListening to port #{ENSOSYNC_PORT}"

  loop {  # Servers run forever
    client = server.accept

      #initiate contact
      login = client.gets[0..-2]
      puts "\n#{login} initiated sync..."
      factory = Factory.new(schema)

      cbase_str = client.read(client.gets[0..-2].to_i)
      cbase = Parse.load_raw(cbase_str, grammar, schema, factory, false).finalize
      path = cbase.sources[login].path
      cnode_str = client.read(client.gets[0..-2].to_i)
      cnode = Parse.load_raw(cnode_str, node_grammar, schema, factory, false).finalize

      #merge and compute deltas
      snode = read_from_fs(rootpath, path, factory)
      d1u, d2u, newbase = sync(cnode, snode, cbase.sources[login].basedir, factory)
      s2c = collate_diffs(d1u, rootpath, path)
      c2s = collate_diffs(d2u, '', path)

      #send over diffs
      s2c_str = YAML::dump(s2c)
      client.puts(s2c_str.length.to_s)
      client.send(s2c_str, 0)
      c2s_str = YAML::dump(c2s)
      client.puts(c2s_str.length.to_s)
      client.send(c2s_str, 0)

      #receive new contents from client
      c2s_str = client.read(client.gets[0..-2].to_i)
      c2s = YAML::load(c2s_str)

      #apply s2c contents
      c2s.each do |k,v|
        path = "#{rootpath}/#{k}"
        case v[0..1]
          when ['+','F']
            puts " Updated file #{path}"
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

      puts "Sync successful for #{login}\n"
      client.close                        # Disconnect from the client
  }

end

rootpath = ARGV[0]
esynchost(rootpath)
