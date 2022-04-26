extends RigidBody
onready var GameMode = get_node("/root/Game")

onready var PlayerInteractionRight = get_node("PilotInteractionRight")
onready var PlayerInteractionLeft = get_node("PilotInteractionLeft")
onready var Propeller = get_node("Propeller")
onready var GroundCheck = get_node("GroundCheck")


var CameraOffset = {
	"horizontal": 12,
	"vertical": 50
}

var MinFlightSpeed = 30
var ForwardSpeed = 10

var SeatSelected = null
var SetActive = false

var TorqueRotationSpeed = 2



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	
	if (SetActive == true):
	# Program STARTS here...
	#############################################################
		RunEngine()
		print(GetPlaneVelocity())

		# test rotation on flight
		if (GroundCheck.is_colliding()):
			if Input.is_action_pressed("MoveLeft"):
				apply_torque_impulse(Vector3(0,TorqueRotationSpeed,0))
			elif Input.is_action_pressed("MoveRight"):
				apply_torque_impulse(Vector3(0,-TorqueRotationSpeed,0))
		else:
			if Input.is_action_pressed("MoveLeft"):
				apply_torque_impulse(-global_transform.basis.z * 5)
			elif Input.is_action_pressed("MoveRight"):
				apply_torque_impulse(global_transform.basis.z * 5)
		
	
		var ForwardMove = global_transform.basis.z * .1 * ForwardSpeed

		if Input.is_action_pressed("MoveForward"):
			print(ForwardMove)
#			apply_central_impulse(ForwardMove)
			add_force(ForwardMove, Vector3.ZERO)
		elif Input.is_action_pressed("MoveBack"):
#			apply_central_impulse(-ForwardMove)
			add_force(-ForwardMove, Vector3.ZERO)


		if Input.is_action_just_released("RideVehicle") and GameMode.find_node("Player") == null:
			GameMode.SpawnPlayer(SeatSelected.global_transform.origin)
			SetActiveFalse()
			if (get_node("CameraSetup")):
				get_node("CameraSetup").queue_free()
			pass

	#############################################################	
	# Program ENDS here...
	
func GetPlaneVelocity():
	return -linear_velocity.z

func RunEngine():
	Propeller.rotate_object_local(Vector3(0,0,1), 5)
	pass


func SetActiveTrue(seatselected):
	SeatSelected = seatselected
	SetActive = true
	
func SetActiveFalse():
	SeatSelected = null
	SetActive = false

	
