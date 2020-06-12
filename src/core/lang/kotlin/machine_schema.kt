package Machine
import schema.Many
interface Machine {
  var start : State
  val states : Keyed<State>
}
interface State {
  var machine : Machine
  var name : String
  val outs : Keyed<Trans>
  val ins : Keyed<Trans>
}
interface Trans {
  var event : String
  var from : State
  var to : State
}
