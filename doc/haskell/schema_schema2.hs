import Data.Maybe

---------------------
data Prim 
  = PrimS String 
  |  PrimB  Bool
  |  PrimI   Int

type Object = String -> Attribute
data Value 
  = Nil 
  | Prim    Prim
  | Object Object

data Attribute 
  = One  Value
  | Many [Value]

instance Show Prim where
  show (PrimS x)  = x
  show (PrimB x) = show x
  show (PrimI x) = show x

instance Show Value where
  show Nil = "NIL"
  show (Prim x) = show x
  show (Object _) = "OBJECT"

instance Show Attribute where
  show (One x) = show x
  show (Many x) = show x

---------------------

data Spec = OPTIONAL | MANY | INVERSE String String | KEY
  deriving Eq

start :: (Object -> a) -> a
start k = k (\s -> error ("undefined field: '" ++ s ++ "'"))


object :: Value -> (Object -> a) -> a
object c = start  -- bind "schema_class" (One c) 

bind :: Object -> String -> Attribute -> (Object -> a) -> a
bind r x a k = k (\s -> if s==x then a else r s)

end :: Object -> Value
end r = Object r

schema :: [Value] -> Value
schema types = 
  object Nil -- (get_class "Schema")
  bind "types"  (Many types)
  end

primitive :: String -> Value
primitive name = 
  object Nil -- (get_class "Primitive") 
  bind "name" (One$Prim$PrimS name)
  end

def_class :: String -> Value -> [Value] -> Value
def_class name parent fields = 
  object Nil -- (get_class "Class")
  bind "name" (One$Prim$PrimS name)
  bind "super" (One$parent)
  bind "fields" (Many fields)
  end

def_field :: String -> String -> [Spec] -> Value
def_field name _type spec =
 object Nil -- (get_class "Field")
 bind "name" (One$Prim$PrimS name)
 bind "type" (One$(get_class _type))
 bind "key" (One$Prim$PrimB False)
 bind "required" (One$Prim$PrimB (not (elem OPTIONAL spec)))
 bind "single" (One$Prim$PrimB (not (elem MANY spec)))
 bind "inverse" (One$inverse spec)
 end

---------------------

get_class :: String -> Value
get_class name =  (mfield "types" schema_schema) name

lookup_by_name :: String -> [Value] -> Value
lookup_by_name str vals = fromJust (lookup str [(name o,o) | o <- vals])

name = strfield "name"
strfield :: String -> Value -> String
strfield field_name obj = s
  where Prim(PrimS s) = sfield field_name obj

sfield :: String -> Value -> Value
sfield field_name (Object fields) = v
  where One v = fromJust (lookup field_name fields)

mfield :: String -> Value -> [Value]
mfield field_name (Object fields) = vs
  where Many vs = fromJust (lookup field_name fields)

inverse [] = Nil
inverse (INVERSE c f:_) =  lookup_by_name f (mfield "fields" (get_class c))
---------------------

schema_schema = schema [
  primitive "str",
  primitive "int",
  primitive "bool",
  primitive "real",

  def_class "Schema" Nil [
    def_field "types" "Type" [MANY] 
    ],

  def_class "Type" Nil [
    def_field "name" 		"str" [KEY],
    def_field "schema" 	"Schema" [KEY, INVERSE "Schema" "types"]
    ],
  
  def_class "Primitive" (get_class "Type") [
    ],
  
  def_class "Class" (get_class "Type") [
    def_field "super"     	"Class" [OPTIONAL],
    def_field "subtypes"  	"Class" [MANY, INVERSE "Class" "super"],
    def_field "fields"    	"Field" [MANY]
    ],
  
  def_class "Field" Nil [
    def_field "name"		"str" [KEY],
    def_field "owner" 		"Class" [KEY, INVERSE "Class" "fields"],
    def_field "type" 		"Type" [],
    def_field "optional" 	"bool" [],
    def_field "many" 		"bool" [],
    def_field "key" 		"bool" [],
    def_field "inverse" 	"Field" [OPTIONAL, INVERSE "Field" "inverse"],
    def_field "computed" 	"str" [OPTIONAL]
    ]
  ]





