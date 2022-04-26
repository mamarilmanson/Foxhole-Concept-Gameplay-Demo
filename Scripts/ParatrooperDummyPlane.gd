extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var LeftPropeller = get_node("LeftPropeller")
onready var RightPropeller = get_node("RightPropeller")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	translate_object_local(Vector3(0, 0, 1))
	
	LeftPropeller.rotate_object_local(Vector3(0,0,1), 8)
	RightPropeller.rotate_object_local(Vector3(0,0,-1), 8)
	pass
