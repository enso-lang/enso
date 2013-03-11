=begin

This is essentially the front end that manipulates all other functions

=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'applications/EnsoSync/code/io'
require 'applications/EnsoSync/code/sync'

class EnsoSync
  
  @@domainpath = "applications/EnsoSync/test/"
  @@domainfile = "domain.esync"

  #create or update the domain file
  def self.setup
    @schema = Load::load('esync.schema')
    @grammar = Load::load('esync.grammar')
    domain = Load::load('domain.esync')
    factory = domain.factory

    puts ""
    puts "Welcome to EnsoSync"
    puts "~~~~~~~~~~~~~~~~~~~"

    while (true)
      puts ""
      puts "Select: "
      puts "(1) Display setting"
      puts "(2) Manage sources"
      puts "(3) Manage rules"
      puts "(4) Execute rule"
      puts "(5) Start/stop daemon"
      puts "(6) Configuration"
      puts "(9) Quit without saving"
      puts "(0) Save and exit"
      sel = $stdin.gets.strip
      case sel
      when "1" #display settings
        info
      when "2" #add, del, edit sources
        puts ""
        puts "Manage sources:"
        puts "(1) Add a new source"
        puts "(2) Edit an existing source"
        puts "(3) Delete an existing source"
        sel2 = $stdin.gets.strip
        case sel2
        when "1"
          print "Enter source name: "
          sname = $stdin.gets.strip
          if sname.empty?
            puts "Source name cannot be empty"
            next
          end
          print "Enter source path: "
          spath = $stdin.gets.strip
          print "Update base (Y/N)? "
          update = $stdin.gets.strip.downcase == "y"
          s = factory.Source(sname)
          s.path = spath
          s.basedir = read_from_fs(spath, factory) if update
          domain.sources << s
        when "2"
          if domain.sources.size == 0
            puts "No sources currently defined!"
            next
          end
          puts "Select a source to edit:"
          s = selector(domain.sources)
          print "Enter new source name (blank=unchanged): "
          input = $stdin.gets.strip
          s.name = input if not input.empty?
          print "Enter new source path (blank=unchanged): "
          input = $stdin.gets.strip
          s.path = input if not input.empty?
          print "Update base (y/N)? "
          update = $stdin.gets.strip.downcase == "y"
          if update
            s.basedir = read_from_fs(s.path, factory)
            puts "Base updated"
          else
            puts "Base not updated"
          end
        when "3"
          if domain.sources.size == 0
            puts "No sources currently defined!"
            next
          end
          puts "Select a source to delete:"
          s = selector(domain.sources)
          puts "Are you sure you want to delete #{s.name} (Y/N)? "
          if $stdin.gets.strip.downcase == "y"
            domain.sources.delete(s)
            puts "Source #{s.name} deleted"
          end
        else
          puts "Invalid selection"
        end
      when "3" #add, del, edit rules
        puts ""
        puts "Manage rules:"
        puts "(1) Add a new rule"
        puts "(2) Edit an existing rule"
        puts "(3) Delete an existing rule"
        sel2 = $stdin.gets.strip
        case sel2
        when "1"
          if domain.sources.size == 0
            puts "No sources currently defined! Add sources before creating rules"
            next
          end
          print "Enter rule name: "
          rname = $stdin.gets.strip
          if rname.empty?
            puts "Rule name cannot be empty"
            next
          end
          puts "Select first source:"
          s1 = selector(domain.sources)
          puts "Select second source:"
          s2 = selector(domain.sources)
          r = factory.SyncRule(rname)
          r.s1 = s1
          r.s2 = s2
          r.resolver = ""
          domain.rules << r
        when "2"
          if domain.rules.size == 0
            puts "No rules currently defined!"
            next
          end
          if domain.sources.size == 0
            puts "No sources currently defined! Add sources before creating rules"
            next
          end
          puts "Select a rule to edit:"
          r = selector(domain.rules)
          print "Enter rule name (blank=unchanged): "
          input = $stdin.gets.strip
          r.name = input if not input.empty?
          puts "Select first source:"
          s1 = selector(domain.sources)
          puts "Select second source:"
          s2 = selector(domain.sources)
        when "3"
          if domain.rules.size == 0
            puts "No rules currently defined!"
            next
          end
          puts "Select a rule to delete:"
          r = selector(domain.rules)
          puts "Are you sure you want to delete #{r.name} (Y/N)? "
          if $stdin.gets.strip.downcase == "y"
            domain.rules.delete(r)
            puts "Rule #{r.name} deleted"
          end
        else
          puts "Invalid selection"
        end
      when "4" #execute one/all rule
        puts ""
        puts "Select rule to execute (blank=all):"
        r = selector(domain.rules)
        if not r.nil?
          puts "Running Rule #{r.name}"
          execrule(r)
          write_domain(domain)
          puts "Complete"
        else
          puts "Are you sure you want to run all rules? (Y/N)? "
          if $stdin.gets.strip.downcase == "y"
            puts "Running all rules"
            runonce()
            puts "Complete"
          end
        end
      when "5" #start/stop daemon
        puts "Currently not supported"
      when "6" #config -- scheduling, etc
        puts "Currently not supported"
      when "9" #quit w/o saving
        break
      when "0" #save and quit
        write_domain(domain)
        break
      else
        puts "Please make a selection from the menu"
      end
      puts ""
    end
  end

  #command-line version of setup
  def self.setup_c
    
  end

  #interactive version of setup
  def self.setup_i
    
  end

  #print status of domain
  def self.info
    domain = Load::load('domain.esync')
    puts ""
    puts "Domain file: #{@@domainpath}#{@@domainfile}"
    puts ""
    if domain.sources.size == 0
      puts "No sources defined!"
    else 
      puts "Sources:"
      domain.sources.each do |s|
        puts "  #{s.name}: #{s.path}"
      end
    end
    puts ""
    if domain.rules.size == 0
      puts "No rules defined!"
    else
      puts "Rules:"
      domain.rules.each do |r|
        #they are all sync rules
        puts "  #{r.name}: synchronize #{r.s1.name} and #{r.s2.name}" 
      end
    end
    puts ""
  end
  
  #help info
  def self.help
    puts ""
    puts "Usage: 'ruby ensosync [command]'"
    puts "Commands: "
    puts "runonce -- Run all rules once"
    puts "start   -- Start daemon as background process"
    puts "setup   -- Interactive domain file set up"
    puts "status  -- Print domain file info"
    puts "help    -- Show this screen"
    puts ""
  end
  
  #run rules at a regular fixed interval
  #this process must be kept alive
  def self.run
    puts ""
    puts "EnsoSync daemon started...."
    while true
      puts ""
      puts "Synchronization started at "+Time.now.inspect
      runonce
      puts "Synchronization completed at "+Time.now.inspect
      sleep 1800 #run once every half hour 
    end
  end

  #execute all rules immediately
  def self.runonce
    @schema = Load::load('esync.schema')
    @grammar = Load::load('esync.grammar')
    domain = Load::load('domain.esync')
    domain.rules.each do |rule|
      execrule(rule)
      write_domain(domain)
    end
  end

  #execute one rule
  def self.execrule(rule)
    #current only sync rules
    sync(rule.s1, rule.s2)
  end

  #stupid method to get past the 
  def self.write_domain(domain)
    f= File.open(@@domainpath+@@domainfile, "w")
    Layout::DisplayFormat.print(@grammar, domain, f)
    f.close
  end


  def self.selector(coll)
    map = {}
    i = 1
    coll.each do |s|
      puts "(#{i}) #{s.name}"
      map[i] = s
      i = i+1
    end
    begin
      ind = Integer($stdin.gets.strip)
    rescue
      puts "Invalid selection"
      return nil
    end
    if map.has_key?(ind)
      return map[ind]
    else
      puts "Invalid selection"
      return nil
    end
  end
end


if ARGV[0] == "setup"
  EnsoSync.setup
elsif ARGV[0] == "runonce"
  EnsoSync.runonce
elsif ARGV[0] == "start"
  EnsoSync.run
elsif ARGV[0] == "status"
  EnsoSync.info
elsif ARGV[0] == "help"
  EnsoSync.help
else
  puts "Unknown command #{ARGV[0].to_s}"
end

