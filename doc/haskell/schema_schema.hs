import Data.Maybe

---------------------
-- This is a simple typed model of Enso data
data Prim 
  = PrimS String 
  |  PrimB  Bool
  |  PrimI   Int

data Value 
  = Nil 
  | Prim    Prim
  | Composite Value [(String, Attribute)]

data Attribute 
  = One  Value
  | Many [Value]
---------------------

-- The following are some helper functions for creating schemas
data Spec = OPTIONAL | MANY | INVERSE String String | KEY
  deriving Eq

schema :: [Value] -> Value
schema types = 
  Composite (get_class "Schema") [
    ("types", Many types)
    ]

primitive :: String -> Value
primitive name = 
  Composite (get_class "Primitive") [ 
     ("name", One$Prim$PrimS name)
    ]

def_class :: String -> Value -> [Value] -> Value
def_class name parent fields = 
  Composite (get_class "Class") [ 
     ("name", One$Prim$PrimS name),
     ("super", One$parent),
     ("fields", Many fields)
    ]

def_field :: String -> String -> [Spec] -> Value
def_field name _type spec =
  Composite (get_class "Field") [
    ("name", One$Prim$PrimS name),
    ("type", One$(get_class _type)),
    ("key", One$Prim$PrimB False),
    ("required", One$Prim$PrimB (not (elem OPTIONAL spec))),
    ("single", One$Prim$PrimB (not (elem MANY spec))),
    ("inverse", One$inverse spec)
    ]

---------------------
-- Here are some helper functions for accessing Enso data

get_class :: String -> Value
get_class name = lookup_by_name name (mfield "types" schema_schema)

lookup_by_name :: String -> [Value] -> Value
lookup_by_name str vals = fromJust (lookup str [(name o,o) | o <- vals])

name = strfield "name"
strfield :: String -> Value -> String
strfield field_name obj = s
  where Prim(PrimS s) = sfield field_name obj

sfield :: String -> Value -> Value
sfield field_name (Composite _ fields) = v
  where One v = fromJust (lookup field_name fields)

mfield :: String -> Value -> [Value]
mfield field_name (Composite _ fields) = vs
  where Many vs = fromJust (lookup field_name fields)

inverse [] = Nil
inverse (INVERSE c f:_) =  lookup_by_name f (mfield "fields" (get_class c))
---------------------
-- Finally, the Enso schema schema

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
  
  def_class "Primitive" (get_class "Type") [ ],
  
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



