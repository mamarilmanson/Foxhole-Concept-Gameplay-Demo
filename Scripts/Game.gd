#################################################################
# TODOS
#################################################################
# PRIORITY:
# ADD: Screenshake when firing





#################################################################
# ADD: Line2d aim fade texture
# ADD: Dummy plane for air with collision and HP for warfare demonstration
# ADD: Player made structures, vehicles and dummy infantry for visual/fow presentation purposes
# ADD: Animated WW2 Soldier as character
# ADD: Simulated server hopping
# ADD: Particle Clouds
#################################################################
# FIX: Remember camera rotation on enter/exit vehicle (test get_euler()
# FIX: Player down velocity affected by movement actions
#################################################################
# REWORK: Make planes inherit codes
# REWORK: Make plane UI inherit codes
# REWORK: Main and UI nodes/scripts to data process(main node) and reader(UI scripts) format
# REWORK: Plane firing conditions/state machine
# REWORK: plane movement states machine
# REWORK: Unify plane velocity calculations for gravity/smooth landing
# REWORK: Make planes rigidbody (WEEKEND)
#################################################################
# NOTES: variable+= -> variable = clamp(variable, min, max) works
#################################################################


#################################################################
# DONE
#################################################################
# ADD: Player firing with (scaled) bullet impacts
# ADD: Plane hitscan with damage onhit effects and tracers
# ADD: Terrain and Trees
# ADD: Black bar behind Packaging Text
# ADD: Paratrooper plane paradrop container
# ADD: Parachute items
# ADD: Drivable Crane
# ADD: White line plane aim/crosshair
# ADD: Import Paratrooper plane for cosmetics/presentaion
# FIX: Camera right click aiming (use lerp) XZ Axis remaining
# FIX: Try using lerp for plane rotation force
# FIX: Crane rotations breaks some time (check collisions to floor)
# REWORK: Camera Height based on CameraRoot distance
# REWORK: Enter/Exit vehicle area enter/exit (similar to paratrooper plane)
# REWORK: Change Plane Trailrenderer to 10
# REWORK: Turn plane flight speeds to LERP function
# REWORK: Add shortcut to add 3rd (scroll wheel-height) aiming mode
# REWORK: Use trail render for plane wings smoke trails
#################################################################



extends Spatial


onready var PlayerSpawn = preload("res://Player/Player.tscn")
onready var GameCamera = get_viewport().get_camera()


var riddenvehicle = false
var RememberRotation = null

func _ready():
	pass

func _physics_process(_delta):
	RememberRotation = get_viewport().get_camera().global_transform.basis.get_euler().y
	pass
	
# SPAWN PLAYER
func SpawnPlayer(spawnlocation):
	var PlayerSpawnInstance = PlayerSpawn.instance()
	add_child(PlayerSpawnInstance)
	PlayerSpawnInstance.global_transform.origin = spawnlocation
	PlayerSpawnInstance.MakeCurrent()

	pass


# REMEMBER ROTATION
func GetRememberRotation():
	return RememberRotation

func EmptyRememberRotation():
	RememberRotation = Vector3.ZERO
