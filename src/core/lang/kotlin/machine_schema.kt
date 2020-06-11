package Machine
import schema.Many
interface Machine {
  var start : State
  val states : Map<String, State>
}
interface State {
  var machine : Machine
  var name : String
  val outs : Map<String, Trans>
  val ins : Map<String, Trans>
}
interface Trans {
  var event : String
  var from : State
  var to : State
}
