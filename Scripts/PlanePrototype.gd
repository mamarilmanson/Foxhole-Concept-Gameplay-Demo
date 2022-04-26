extends KinematicBody
onready var GameMode = get_node("/root/Game")

onready var PlayerInteractionRight = get_node("PilotInteractionRight")
onready var PlayerInteractionLeft = get_node("PilotInteractionLeft")
onready var Propeller = get_node("MeshInstances/Propeller")
onready var GroundCheck = get_node("GroundCheck")

onready var PrototypePlaneUI = get_node("PrototypePlaneUI")

onready var MeshBody = get_node("MeshInstances")

onready var PlaneRotationUI = get_node("PrototypePlaneUI/Panel/PlaneAxis")

var CameraOffset = {
	"horizontal": 12,
	"vertical": 50
}

var SeatSelected = null
var SetActive = false


var Velocity = Vector3.ZERO

var Gravity = -9.8

var Grounded = false

var MinUngroundedSpeed = 30
var MinFlightSpeed = 10
var ReverseSpeed = -10
var MaxFlightSpeed = 50
var ThrottleDelta = 30

var Acceleration = 6.0
var ForwardSpeed = 0
var LevelSpeed = 3.0
var TargetSpeed = 0
var TurnInput = 0
var TurnSpeed = 0.75
var PitchInput = 0
var PitchSpeed = 0.5



# Called when the node enters the scene tree for the first time.
func _ready():
	PrototypePlaneUI.hide()
	pass # Replace with function body.


func _physics_process(delta):
	
	
	if (SetActive == true):
		# Program STARTS here...
		#############################################################
		
		RunEngine() # Run Engine Animation/SoundEffects Function
		ExitVehicle() # Exit Engine function

		# PlaneRotationUI.set_rotation(-rotation.x)

		# Rework to accept gravity params
		# Replace with prop plane
		
		if Input.is_action_pressed("Spacebar"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
		elif Input.is_action_pressed("LeftShift"):
			var limit = ReverseSpeed if Grounded else MinFlightSpeed
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, limit)
		else:
			var limit = 0 if Grounded else MinFlightSpeed
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, limit)


			
		# Turn (roll/yaw) input
		TurnInput = 0
		TurnInput -= Input.get_action_strength("MoveRight")
		TurnInput += Input.get_action_strength("MoveLeft")
		# Pitch (climb/dive) input
		PitchInput = 0
		PitchInput -= Input.get_action_strength("MoveBack")
		PitchInput += Input.get_action_strength("MoveForward")
			
			
		# Rotate the transform based on the input values
		transform.basis = transform.basis.rotated(transform.basis.x, PitchInput * PitchSpeed * delta)
		transform.basis = transform.basis.rotated(Vector3.UP, TurnInput * TurnSpeed * delta)
		# If on the ground, don't roll the body
		if Grounded:
			MeshBody.rotation.z = lerp(MeshBody.rotation.z, 0, 0.5)
		else:
			# Roll the body based on the turn input
			MeshBody.rotation.z = lerp(MeshBody.rotation.z, -TurnInput, LevelSpeed * delta)
		# Accelerate/decelerate
		ForwardSpeed = lerp(ForwardSpeed, TargetSpeed, Acceleration * delta)
		# Movement is always forward
		Velocity = transform.basis.z * ForwardSpeed
		
		# Handle landing/taking off
		if GroundCheck.is_colliding():
			if not Grounded:
				rotation.x = 0
			Grounded = true
		else:
			Grounded = false

		move_and_slide(Velocity, Vector3.UP)

		#############################################################	
		# Program ENDS here...

func ExitVehicle():
	if Input.is_action_just_released("RideVehicle") and GameMode.find_node("Player") == null:
		PrototypePlaneUI.hide()
		GameMode.SpawnPlayer(SeatSelected.global_transform.origin)
		GameMode.EmptyRememberRotation()
		SetActiveFalse()
		if (get_node("CameraSetup")):
			get_node("CameraSetup").queue_free()
		pass


	
func RunEngine():
	Propeller.rotate_object_local(Vector3(0,0,1), 5)
	pass


func SetActiveTrue(seatselected):
	PrototypePlaneUI.show()
	SeatSelected = seatselected
	SetActive = true
	
func SetActiveFalse():
	SeatSelected = null
	SetActive = false

func MyType():
	return "PLANE"

	
