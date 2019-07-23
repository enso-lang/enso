const electron = require('electron');
// const MyMenu = require('mymenu')
// Module to control application life.
const {app} = electron;
// Module to create native browser window.
const {BrowserWindow} = electron;
const ipc = electron.ipcMain
const dialog = electron.dialog
const Menu = electron.Menu

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let win;

function createWindow() {
  // Create the browser window.
 win = new BrowserWindow({
  						webPreferences: {
    						nodeIntegration: true,
    						webviewTag: true,
    						allowRunningInsecureContent: true
  						}
				})

  // and load the index.html of the app.
  win.loadURL(`file://${__dirname}/main.html`);

  // Open the DevTools.
  // win.webContents.openDevTools();

  // Emitted when the window is closed.
  win.on('closed', () => {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    win = null;
  });
}

 var template = [{
    label: 'File',
    submenu: [{
        label: 'New',
		    accelerator: 'CmdOrCtrl+N',
        click: (menuItem, browserWindow, event) => {  
        		files = dialog.showOpenDialog(browserWindow, {
        			title: "New Model", 
        			properties: ['openFile'],
        			extensions: ['stencil']});  
            if (files)
	        	  browserWindow.webContents.send("do-new", files[0]); 
        }
		  },{
        label: 'Open',
		    accelerator: 'CmdOrCtrl+O',
        click: (menuItem, browserWindow, event) => {  
        		files = dialog.showOpenDialog(browserWindow, {properties: ['openFile']}); 
            if (files)
	        	  browserWindow.webContents.send("do-open", files[0]); 
	       }
		  },{
        label: 'Save',
		    accelerator: 'CmdOrCtrl+S',
        click: (menuItem, browserWindow, event) => {  
           browserWindow.webContents.send("do-save"); 
        }
		  }, /* {
        label: 'Export',
		    accelerator: 'CmdOrCtrl+E',
        click: (menuItem, browserWindow, event) => {  
           browserWindow.webContents.send("do-export"); 
        }
		  }*/ 
		  ]
		}, {
		label: 'Edit',
		submenu: [{
	    label: 'Undo',
	    accelerator: 'CmdOrCtrl+Z',
	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-undo") }
	  }, {
	    label: 'Redo',
	    accelerator: 'Shift+CmdOrCtrl+Z',
	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-redo") }
	  }, {
	    type: 'separator'
	  }, {
	    label: 'Cut',
	    accelerator: 'CmdOrCtrl+X',
	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-cut") }
	  }, {
	    label: 'Copy',
	    accelerator: 'CmdOrCtrl+C',
	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-copy") }
	  }, {
	    label: 'Paste',
	    accelerator: 'CmdOrCtrl+V',
	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-paste") }
	  }, // {
//	    label: 'Select All',
//	    accelerator: 'CmdOrCtrl+A',
//	    click: (menuItem, browserWindow, event) => { browserWindow.webContents.send("do-select-all") }
//	  }
		]
		}, {
		label: 'View',
		submenu: [{
	    label: 'Reload',
	    accelerator: 'CmdOrCtrl+R',
	    click: function (item, focusedWindow) {
	      if (focusedWindow) {
	        // on reload, start fresh and close any old
	        // open secondary windows
	        if (focusedWindow.id === 1) {
	          BrowserWindow.getAllWindows().forEach(function (win) {
	            if (win.id > 1) {
	              win.close()
	            }
	          })
	        }
	        focusedWindow.reload()
	      }
	    }
		  }, {
		    label: 'Toggle Full Screen',
		    accelerator: (function () {
		      if (process.platform === 'darwin') {
		        return 'Ctrl+Command+F'
		      } else {
		        return 'F11'
		      }
		    })(),
		    click: function (item, focusedWindow) {
		      if (focusedWindow) {
		        focusedWindow.setFullScreen(!focusedWindow.isFullScreen())
		      }
		    }
		  }, {
		    label: 'Toggle Developer Tools',
		    accelerator: (function () {
		      if (process.platform === 'darwin') {
		        return 'Alt+Command+I'
		      } else {
		        return 'Ctrl+Shift+I'
		      }
		    })(),
    click: function (item, focusedWindow) {
      if (focusedWindow) {
        focusedWindow.toggleDevTools()
      }
    }
  }, {
    type: 'separator'
	}, {
    label: 'App Menu Demo',
    click: function (item, focusedWindow) {
      if (focusedWindow) {
        const options = {
          type: 'info',
          title: 'Application Menu Demo',
          buttons: ['Ok'],
          message: 'This demo is for the Menu section, showing how to create a clickable menu item in the application menu.'
        }
        electron.dialog.showMessageBox(focusedWindow, options, function () {})
      }
    }
  }]
	}, {
	  label: 'Window',
	  role: 'window',
	  submenu: [{
	    label: 'Minimize',
	    accelerator: 'CmdOrCtrl+M',
	    role: 'minimize'
	  }, {
	    label: 'Close',
	    accelerator: 'CmdOrCtrl+W',
	    role: 'close'
	  }]
	}, {
	  label: 'Help',
	  role: 'help',
	  submenu: [{
	    label: 'Learn More',
	    click: function () {
	      electron.shell.openExternal('http://enso-lang.org')
	    }
	  }]
	}]

	if (process.platform === 'darwin') {
	  const name = electron.app.getName()
	  template.unshift({
	    label: name,
	    submenu: [{
	      label: `About ${name}`,
	      role: 'about'
	    }, {
	      type: 'separator'
	    }, {
	      label: 'Services',
	      role: 'services',
	      submenu: []
	    }, {
	      type: 'separator'
	    }, {
	      label: `Hide ${name}`,
	      accelerator: 'Command+H',
	      role: 'hide'
	    }, {
	      label: 'Hide Others',
	      accelerator: 'Command+Alt+H',
	      role: 'hideothers'
	    }, {
	      label: 'Show All',
	      role: 'unhide'
	    }, {
	      type: 'separator'
	    }, {
	      label: 'Quit',
	      accelerator: 'Command+Q',
	      click: function () {
	        app.quit()
	      }
	    }]
	  })
	  // Window menu.
	  template[3].submenu.push({
	    type: 'separator'
	  }, {
	    label: 'Bring All to Front',
	    role: 'front'
	  })

  //addUpdateMenuItems(template[0].submenu, 1)
}

if (process.platform === 'win32') {
  const helpMenu = template[template.length - 1].submenu
  //addUpdateMenuItems(helpMenu, 0)
}

app.on('ready', function () {
  const menu = Menu.buildFromTemplate(template)
  Menu.setApplicationMenu(menu)
})


// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow);

// Quit when all windows are closed.
app.on('window-all-closed', () => {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (win === null) {
    createWindow();
  }
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.

/*
ipc.on('save-dialog', function (event) {
  const options = {
    title: 'Save an Image',
    filters: [
      { name: 'Images', extensions: ['jpg', 'png', 'gif'] }
    ]
  }
  dialog.showSaveDialog(options, function (filename) {
    event.sender.send('saved-file', filename)
  })
})
*/