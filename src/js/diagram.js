define(["enso", 'core/expr/code/eval', 'core/expr/code/lvalue', 'core/diagram/code/invert'], function(Enso, Eval, Lvalue, Invert) {
	var mm;

	function getMethods(obj) {
		var result = [];
		for (var id in obj) {
			try {
				if ( typeof (obj[id]) == "function") {
					result.push(id + ": " + obj[id].toString());
				}
			} catch (err) {
				result.push(id + ": inaccessible");
			}
		}
		return result;
	}

	function coercefromstr(type, val) {
		if (type == 'int') {
			res = parseInt(val);
			if (isNaN(res))
				return 0;
			else
				return res;
		} else
			return null;
	}

	var interp = {
		render : function(obj) {
			var self = this;
			type = obj.schema_class();
			method = S("render", "_", type.name()).to_s();
			dom = this[method](obj);
			return dom;
		},
		render_Stencil : function(obj) {
			return this.render(obj.body())
		},
		render_Container : function(obj) {
			var dom;
			if (obj.direction() == 1) {//vertical
				dom = $('<div>');
				for (var i = 0, len = obj.items().size(); i < len; i++) {
					var t = this.render(obj.items()._get(i));
					//	    	var row = $('<tr>');
					//	    	row.append(t);
					dom.append(t);
				}
			} else if (obj.direction() == 2) {//horizontal
				dom = $('<table>');
				var row = $('<tr>');
				var grid = false;
				if (this.in_grid > 0) {
					grid = true;
				}
				for (var i = 0, len = obj.items().size(); i < len; i++) {
					var t = this.render(obj.items()._get(i));
					var col = $('<td>');
					col.append(t);
					row.append(col);
				}
				dom.append(row);
				if (grid) {
					dom = row;
				}
			} else if (obj.direction() == 3) {//grid
				dom = $('<table>');
				this.in_grid += 1;
				for (var i = 0, len = obj.items().size(); i < len; i++) {
					var row = this.render(obj.items()._get(i));
					dom.append(row);
				}
				this.in_grid -= 1;
			} else if (obj.direction() == 4) {//graph
			} else if (obj.direction() == 5) {//style, group
				dom = $('<div>')
				for (var i = 0, len = obj.items().size(); i < len; i++) {
					var t = this.render(obj.items()._get(i));
					dom.append(t);
				}
			}
			this.make_style(dom, obj.props());
			return dom;
		},
		update_Pages : function(doms, list, nval) {
			console.log(S("dom=", doms.current, "  val=", nval))
			if (doms.current != nval) {
				console.log(S("Flipping page from ", doms.current, " to ", nval));
				list[doms.current].hide()
				console.log(S("hiding ", list[doms.current]))
				list[nval].show()
				console.log(S("showing ", list[nval]))
				doms.current = nval
			}
		},
		render_Pages : function(obj) {
			var index = obj.current().val();
			var doms = $("<div>");
			var list = []
			for (var i = 0, len = obj.items().size(); i < len; i++) {
				var item_dom = this.render(obj.items()._get(i));
				doms.append(item_dom);
				list[i] = item_dom;
				item_dom.hide();
			}
			var path = mm._get(obj.current().to_s());
			var env = new EnsoHash({ });
			env._set("root", data);
			doms["current"] = Eval.eval(path, new EnsoHash({
				env : env
			}));
			list[doms.current].show();
			if (path != null) {
				srcs = Invert.getSources(path);
				for (var i = 0, len = srcs.size(); i < len; i++) {
					var addr = Lvalue.lvalue(srcs._get(i), new EnsoHash({
						env : env
					}));
					console.log(S("adding listener to addr: ", addr.object(), ".", addr.index()));
					addr.object().add_listener(function(val) {
						var nval = Eval.eval(path, new EnsoHash({
							env : env
						}));
						console.log(S("changed value in ", addr.object(), ".", addr.index(), " to ", nval));
						console.log(S("dom=", doms.current, "  val=", nval))
						if (doms.current != nval) {
							console.log(S("Flipping page from ", doms.current, " to ", nval));
							list[doms.current].hide()
							console.log(S("hiding ", list[doms.current]))
							list[nval].show()
							console.log(S("showing ", list[nval]))
							doms.current = nval
						}
						//				this.update_Pages(doms,list,nval);
					}, addr.index().to_s());
				}
			}
			return doms;
		},
		render_Space : function(obj) {
			var txt3 = $("<div>");
			return txt3;
		},
		render_Text : function(obj) {
			var dom = $('<text>');
			this.make_style(dom, obj.props());
			dom.text(obj.string().val().to_s());
			var path = mm._get(obj.string().to_s());
			if (path != null) {
				var env = new EnsoHash({ });
				env._set("root", data);
				srcs = Invert.getSources(path);
				for (var i = 0, len = srcs.size(); i < len; i++) {
					//add listener to when model changes value
					var addr = Lvalue.lvalue(srcs._get(i), new EnsoHash({
						env : env
					}));
					console.log(S("adding listener to addr: ", addr.object(), ".", addr.index()));
					addr.object().add_listener(function(val) {
						var nval = Eval.eval(path, new EnsoHash({
							env : env
						}));
						console.log(S("changed value in ", addr.object(), ".", addr.index(), " to ", nval));
						dom.text(nval.to_s());
					}, addr.index().to_s());

					//add debugging highlight
					self = this;
					dom.click(function() {
						self.toggleHightlight(S("#", addr.object().schema_class().name(), addr.object()._id().toString()))
					});
				}
			}
			dom.append($('<p>'))
			return dom;
		},
		render_TextBox : function(obj) {
			var dom = $("<input type='text'>");
			this.make_style(dom, obj.props());
			dom.text(obj.value().val().to_s());
			var type = obj.type().val().to_s();
			var path = mm._get(obj.value().to_s());
			if (path != null) {
				var env = new EnsoHash({ });
				env._set("root", data);
				dom.keyup(function() {
					var ui_value = coercefromstr(type, $(this).val());
					var model_value = Eval.eval(path, new EnsoHash({
						env : env
					}));
					if (ui_value.to_s() != model_value) {
						console.log(S("setting ", path, " to ", ui_value));
						addr = Lvalue.lvalue(path, new EnsoHash({
							env : env
						}));
						console.log(S("addr: ", addr.object(), "..", addr.index()));
						addr.set(ui_value);
					}
				}).keyup();
			}
			return dom;
		},
		render_SelectMulti : function(obj) {
			var dom = $('<form>');
			this.make_style(dom, obj.props());
			//guess defaults
			var arrange = obj.props._get("arrange");
			if (arrange != 'vertical' && arrange != 'horizontal') {
				//guess how to arrange
				var too_long = false;
				obj.choices().each(function(c) {
					if (c.val().length > 20)
						too_long = true;
				});
				if (too_long)
					arrange = 'vertical';
			}
			//make actual widget
			for (var i = 0, len = obj.choices().size(); i < len; i++) {
				var choice = obj.choices()._get(i);
				var line = S("<input type='checkbox' name='", obj._id().toString(), "'>", choice.val(), "</input>");
				if (arrange == 'vertical') {
					line = line + "<br>";
				}
				dom.append($(line));
			}
			return dom;
		},
		render_SelectSingle : function(obj) {
			var dom = $('<form>');
			this.make_style(dom, obj.props());
			//guess defaults
			var arrange = obj.props._get("arrange");
			if (arrange != 'vertical' && arrange != 'horizontal') {
				//guess how to arrange
				var too_long = false;
				obj.choices().each(function(c) {
					if (c.val().length > 20)
						too_long = true;
				});
				if (too_long)
					arrange = 'vertical';
			}
			var type = obj.props._get("type");
			if (type != 'radio' && type != 'dropdown') {
				if (obj.choices().size() < 5)
					type = 'radio'
				else
					type = 'dropdown'
			}
			//make actual widget
			if (type == 'radio') {
				for (var i = 0, len = obj.choices().size(); i < len; i++) {
					var choice = obj.choices()._get(i);
					var name = S("x", obj._id().toString());
					var line = S("<input type='radio' name='", name, "' value='", choice.val(), "'>", choice.val(), "</input>");
					if (arrange == 'vertical') {
						line = line + "<br>";
					}
					dom.append($(line));
				}
			} else {
				var sel = $(S("<select name='", obj._id().toString(), "'>"));
				for (var i = 0, len = obj.choices().size(); i < len; i++) {
					var choice = obj.choices()._get(i);
					var line = S("<option value='", choice.val(), "'>", choice.val(), "</option>");
					console.log(line);
					sel.append($(line));
				}
				console.log("<select name='", obj._id().toString(), "'></select>");
				dom.append(sel);
			}
			return dom;
		},
		coercetostr : function(type, val) {
		},
		coercefromstr : function() {
			if (type == 'int') {
				res = parseInt($(this).val());
				if (res.isNaN())
					return null;
				else
					return res;
			} else
				return null;
		},
		highlighted : [],
		toggleHightlight : function(name, color) {
			if (color === undefined)
				color = "yellow"
			var index = this.highlighted.indexOf(name)
			if (index <= -1) {
				$(name).css("background-color", color)
				this.highlighted.push(name)
			} else {
				$(name).css("background-color", "inherit")
				this.highlighted.splice(index, index + 1)
			}
		},
		make_style : function(dom, props) {
			props.each(function(prop) {
				//  		console.log(S("css prop:", prop.var().to_s(), " -> ", prop.val().val().to_s()));
				dom.css(prop.var().to_s(), prop.val().val().to_s());
			});
		},
		in_grid : []
	}

	var Diagram = {
		render : function(obj, modelmap) {
			var self = this;
			mm = modelmap;
			return interp.render(obj);
		},
	};

	return Diagram;
})
