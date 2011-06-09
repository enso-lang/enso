Enso example: Ruby

This is an interpreter of the Ruby programming language written using Enso.

By a strange but not completely unexpected twist of fate Ruby also happens to be the language in which Enso interpreters are written in, hence this example has the somewhat peculiar distinction of being *almost* able to run itself.

Having an interpreter as a model facilitates:

- Consistency checking. We can hijack the type checker of the interpreter host language to statically enforce the type constraints of our models. Unfortunately this does not apply to Ruby since it uses duck typing.

- Interpreter co-evolution. Automatic refactoring of the interpreter as the (meta-)model changes.