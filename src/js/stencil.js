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

			//Debugger stuff
			out = new StringBuilder();
			g = Load.load(filetype+".grammar")
			console.log("Loading grammar file: "+filetype+".grammar")
			Layout.DisplayFormat.print(g, data, out, false, true)
			console.log(out.toString())

			dbg = $("<div>")
			dbg.css("width", "400px")
			dbg.css("height", "100%")
			dbg.css("overflow", "auto")
			dbg.css("background", "#D9D9D9")
			dbg.css("font-family", "Courier New")
			dbg.css("font-size", "small")
			s = out.toDocument().replace(/\*\[\*/g, "<").replace(/\*\]\*/g, ">").replace(/<debug&nbsp;/g, "<debug ")
			console.log(s)
			dbg.append($(s))
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
