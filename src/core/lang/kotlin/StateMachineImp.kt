package Machine
import schema.*
open class MachineImp : Machine {
  constructor(
    start : State
  ) {
    this.start = start
  }
  override var start : State
  override val states = ManyOne(this, State::machine)
}
open class StateImp : State {
  constructor(
    machine : Machine,
    name : String
  ) {
    this.machine = machine
    this.name = name
  }
  override var machine : Machine by OneMany(Machine::states)
  override var name : String
  override val outs = ManyOne(this, Trans::from)
  override val ins = ManyOne(this, Trans::to)
}
open class TransImp : Trans {
  constructor(
    event : String,
    from : State,
    to : State
  ) {
    this.event = event
    this.from = from
    this.to = to
  }
  override var event : String
  override var from : State by OneMany(State::outs)
  override var to : State by OneMany(State::ins)
}
