extends Spatial

var ray_origin = Vector3()
var ray_target = Vector3()

onready var player = $Player
onready var hand = $Player/Body/Hand
onready var navmap = $Navigation

onready var PlayerSpawn = preload("res://Player/Player.tscn")

var riddenvehicle = false

onready var GameCamera = get_viewport().get_camera()

func _ready():
	var MonitorCenter = get_viewport().get_size() / 2
	get_viewport().warp_mouse(MonitorCenter)

	pass

func _physics_process(delta):
	# "[Deleted Object]"
	if is_instance_valid(player):
		var mouse_position = get_viewport().get_mouse_position()
	#	print("Mouse Position: ", mouse_position)
		
		ray_origin = GameCamera.project_ray_origin(mouse_position)
	#	print("ray_origin: ", ray_origin)
		ray_target = ray_origin + GameCamera.project_ray_normal(mouse_position) *2000
		
		var space_state = get_world().direct_space_state
		var intersection = space_state.intersect_ray(ray_origin, ray_target, [], 8)
		
	#		print("NOT EMPTY!")
#		if not intersection.empty():
#			var pos = intersection.position
#			var look_at_me = Vector3(pos.x, player.translation.y ,pos.z)
#			player.look_at(look_at_me, Vector3.UP )
#			var distance_to_pointer = hand.global_transform.origin - look_at_me
#			if distance_to_pointer.length() > 3:
#				hand.look_at(look_at_me, Vector3.UP )
	pass
	
# SPAWN PLAYER
func SpawnPlayer(spawnlocation):
	var PlayerSpawnInstance = PlayerSpawn.instance()
	add_child(PlayerSpawnInstance)
	PlayerSpawnInstance.global_transform.origin = spawnlocation.global_transform.origin
	RiddenFalse()
	pass
	

# VEHICLE ACTIVATION
func ReturnRidden():
	return riddenvehicle
	
func RiddenTrue():
	riddenvehicle = true
	
func RiddenFalse():
	riddenvehicle = false
