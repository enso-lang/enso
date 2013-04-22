define([
	"enso", 
	'core/system/load/load', 
	'core/diagram/code/construct',
	'core/grammar/render/layout',
	'core/schema/tools/print',
	'diagram'
], 
function(Enso, Load, Construct, Layout, Print, Diagram) {
	var Stencil = {
		render : function(data_file, stencil_file) {
			if (stencil_file === undefined) {
				stencil_file = data_file.split('.')[1] + ".stencil"
			}
			data = Load.load(data_file)
			stencil = Load.load(stencil_file)

			var modelmap = new EnsoHash({ })
			params = new EnsoHash({
				data : data,
				modelmap : modelmap
			})
			diagram = Construct.eval(stencil, params)
			data = Diagram.render(diagram, modelmap)
			main = $("<div>")
			main.append(data)
			main.css("width", "900px")
			main.css("height", "100%")
			main.css("float", "left")
			$("body").append(main);

			//Debugger stuff
			out = new StringBuilder();
			g = Load.load('stencil.grammar')
			Layout.DisplayFormat.print(g, stencil, out)
			console.log(out.toString())

			dbg = $("<div>")
			dbg.css("width", "400px")
			dbg.css("height", "100%")
			dbg.css("overflow", "auto")
			dbg.css("background", "#D9D9D9")
			dbg.css("font-family", "Courier New")
//			dbg.css("font-size", "small")
s = out.toDocument()
console.log(s)
			dbg.append($(s))
//			dbg.append($("<p>"+out.toDocument()+"</p>"))
			

			$("body").append(dbg);

			//Main
			$("title").text(diagram.title)
			$("html").css("height", "100%")
			$("body").css("height", "100%")
			$("body").css("margin", "0")
		}
	};
	return Stencil;
})
