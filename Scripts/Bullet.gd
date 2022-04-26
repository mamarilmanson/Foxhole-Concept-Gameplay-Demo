extends Spatial

onready var GameRoot = get_node("/root").get_child(0)
onready var BulletRayCast = get_node("BulletRayCast")

#onready var BulletCollisionShape = get_node("BulletCollisionShape")

export var speed = 300
export var damage = 1

const KILL_TIME = 1
var timer = 0

var MainNode
var StartPoint
var EndPoint
var StartRotation

var BulletImpact = preload("res://Weapons/GroundBulletImpact.tscn")

func _ready():
	set_as_toplevel(true)

func _physics_process(delta):
	if(MainNode != null):
		var forward_direction = global_transform.basis.z
		global_translate(forward_direction * speed * delta)
		
		timer += delta
		if timer >= KILL_TIME:
			queue_free()

		if BulletRayCast.is_colliding():
			var bulletImpactInstance = BulletImpact.instance()
			GameRoot.add_child(bulletImpactInstance)
			bulletImpactInstance.global_transform.origin = BulletRayCast.get_collision_point()
			queue_free()	
	
	
func SetBullet(startpoint, endpoint):
	MainNode = startpoint
	
	StartPoint = startpoint.global_transform.origin
	EndPoint = endpoint
	
	global_transform.origin = startpoint.global_transform.origin
	global_transform.basis.z = startpoint.global_transform.basis.z
	pass

func AreaEntered(body: Node):
#	print("I hit you! ", body)
	var bulletImpactInstance = BulletImpact.instance()
	add_child(bulletImpactInstance)
	queue_free()
