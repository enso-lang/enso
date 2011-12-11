

check(Instances {instances: Is}, Schema, Report {errors: Errors}) :-
	check(Is, Schema, Errors).

check(Instance {type: Type}, Schema {types: Types}, Errors) :-
	exists(C, Type, Types),
	check_type(C, Errors)

check(Instance {type: Type, origin: Org}, Schema {types: Types}, 
	Error{message: "Undefined type"; origin: Org}, _*) :-
	not exists(C, Type, Types),


	
