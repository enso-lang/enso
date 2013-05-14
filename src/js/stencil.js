define([
	"enso", 
	'core/system/load/load', 
	'core/diagram/code/construct',
	'core/grammar/render/layout',
	'core/schema/tools/print',
	'core/expr/code/renderexp',
	'diagram'
], 
function(Enso, Load, Construct, Layout, Print, RenderExp, Diagram) {
	var Stencil = {
		render : function(data_file, stencil_file) {
			var filetype = data_file.split('.')[1];
			if (stencil_file === undefined) {
				stencil_file = filetype + ".stencil"
			}
			data = Load.load(data_file)
			stencil = Load.load(stencil_file)

			var modelmap = new EnsoHash({ })
			params = new EnsoHash({
				data : data,
				modelmap : modelmap
			})
			diagram = Construct.eval(stencil, params)
			main = $("<div>")
			main.append(Diagram.render(diagram, modelmap))
			main.css("width", "900px")
			main.css("height", "100%")
			main.css("float", "left")
			$("body").append(main);

			dbgmain = $("<div id='dbg-main'>")

			//Debugger source
			out = new StringBuilder();
			g = Load.load(filetype+".grammar")
			Layout.DisplayFormat.print(g, data, out, false, true)
			out2 = new StringBuilder();
			g2 = Load.load("stencil.grammar")
			Layout.DisplayFormat.print(g2, stencil, out2, false, true)

			dbg = $("<div id='dbg-src'>")
			dbg.css("width", "400px")
			dbg.css("height", "70%")
			dbg.css("overflow", "auto")
			dbg.css("background", "#D9D9D9")
			dbg.css("font-family", "Courier New")
			dbg.css("font-size", "small")
			s = out.toDocument().replace(/\*\[\*/g, "<").replace(/\*\]\*/g, ">").replace(/<debug&nbsp;/g, "<debug ")

			console.log(s)
			dbg.append($(s))
			dbg.append($("<div><br>---------------------<br><br></div>"))

			s2 = out2.toDocument().replace(/\*\[\*/g, "<").replace(/\*\]\*/g, ">").replace(/<debug&nbsp;/g, "<debug ")
			console.log(s2)
			dbg.append($(s2))
			dbgmain.append(dbg);

			//Debugger edit panel
			dbgtree = $("<div id='dbgtree'>")
			dbgmain.append(dbgtree);
			$("body").append(dbgmain);

			//Main
			$("title").text(diagram.title)
			$("html").css("height", "100%")
			$("body").css("height", "100%")
			$("body").css("margin", "0")
		}
	};
	return Stencil;
})
