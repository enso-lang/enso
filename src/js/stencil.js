define([
	"enso", 
	'core/system/load/load', 
	'core/diagram/code/construct', 
	'diagram'
], 
function(Enso, Load, Construct, Diagram) {
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
			$("body").append(data);
			$("title").text(diagram.title)
			$("html").css("height", "100%")
			$("body").css("height", "100%")
			$("body").css("margin", "0")
		}
	};
	return Stencil;
})
