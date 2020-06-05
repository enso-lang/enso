package Machine
import schema.Many
interface Machine {
  var start : State
  val states : Many<State>
}
interface State {
  var machine : Machine
  var name : String
  val outs : Many<Trans>
  val ins : Many<Trans>
}
interface Trans {
  var event : String
  var from : State
  var to : State
}
