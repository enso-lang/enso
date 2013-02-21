require 'wx'
include Wx

class BaseWindow < Wx::Frame
  def initialize(title)
    super(nil, title: title)
    @menu_id = 100
    setup_menus()
  end

  def next_menu_id
    @menu_id = @menu_id + 1
    return @menu_id
  end

  def add_menu(menu, name, desc, action, pos = 0, id = 0)
    pos = menu.get_menu_item_count if pos == 0
    id = next_menu_id() if id == 0
    menu.append( id, name, desc )
    evt_menu( id, action )
  end

  def add_menu2(menu, name, desc, &action)
    pos = menu.get_menu_item_count
    id = next_menu_id()
    menu.append( id, name, desc )
    evt_menu( id, &action )
  end
    
  def setup_menus()
    menu = Wx::MenuBar.new
 
    file = Wx::Menu.new
    add_menu(file, "&Open\tAlt-O", "Open File", :on_open)
    add_menu(file, "&Save\tAlt-S", "Save File", :on_save)
    add_menu(file, "&Close\tAlt-W", "Close File", :on_close)
     
    file.append_separator 
    add_menu(file, "E&xit\tAlt-Q", "Quit", :on_quit, 0, Wx::ID_EXIT)
    menu.append( file, "&File" )
 
    # Create the Help menu
    help = Wx::Menu.new
    add_menu(help, "&About...\tF1", "Show about dialog", :on_about, 0, Wx::ID_ABOUT)
    menu.append( help, "&Help" )
 
    self.menu_bar = menu
  end
  
  # Close the window when the user clicks Quit in the File
  # menu
  def on_quit
    close
  end
 
  # Display an "About this program" dialog
  def on_about
    Wx::about_box(
      name: self.title,
      version: "1.0",
      description: "Enso Diagram Editor"
    )
  end
  
  def on_open
    raise "Must implement open method"
  end
  
  def on_close
    raise "Must implement open method"
  end
  
end