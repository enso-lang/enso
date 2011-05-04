
what we need is a pair of models
  * schema
    -- objects have methods in some action language
  * state machine
    -- machines have actions in some action language and a current state

and a "engine state" schema
   class XUMLState
     ports: Port
     instances: Object*
   end
   class XMLClass < Klass
     machine: StateMachine
   end


We need a list of ports too, I think, that are
the "event streams" for the objects. There might be
a finite number of declared ones, or there might be
dynamically created ports

Here is the execution engine:

def execute(xuml)
  machineState = new MachineState(xuml)
  addEvent(port_name, event)
    # find the object that is attached to a port
    obj = ports[port_name]
    obj.queue.add(event)
  end
  runStep()
    # find some object that can process an event on its port
    # TODO: should process self=send events first. 
    for obj : machineState.objects (non-deterministic)
      for transition : obj.currentState.transitions
        if transition.event.kind = obj.queue[0].kind
          event = obj.queue.pop()
          if obj.currentState != transtion.target
            obj.eval(obj.currentState.exitAction, {:db => machineState})
          obj.eval(transition.action, {:event => event, :db => machineState})
          if obj.currentState != transtion.target
            obj.currentState = transtion.target
            obj.eval(obj.currentState.enterAction, {:db => machineState})
        end
      end
    end
end  


The schema and state machines are
standard. The action language should
look something like this:

  x
  self
  let x=e in e
  e; e
  if e then e (else e)?
  while e do e
  for x in e do e
  e.f                     -- get field
  e.f = e                 -- assign field
  e.m(e*)                 -- invoke method on object
  C                       -- list of all instances of a class
  create C(e*)            -- create a new instance
  delete e                -- delete an instance
  send m(e*) to e         -- post an async message to an object
