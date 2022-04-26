extends Spatial

onready var SmallDebris = get_node("SmallDebris")
onready var TallDebris = get_node("TallDebris")
onready var Smoke = get_node("Smoke")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_toplevel(true)
	
	SmallDebris.emitting = true
	TallDebris.emitting = true
	Smoke.emitting = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if (SmallDebris.emitting == false) and (TallDebris.emitting == false) and (Smoke.emitting == false):
#		queue_free()
#		pass
	pass

#func DestroyBulletImpact():
#	queue_free()

