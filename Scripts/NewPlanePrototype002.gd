extends RigidBody
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

var CameraZoomOffset = {
	"horizontal": 70,
	"vertical": 50
}

var SeatSelected = null
var SetActive = true


var Velocity = Vector3.ZERO

var Gravity = -9.8

var Grounded = false

var MinUngroundedSpeed = 30
var MinFlightSpeed = 10
var MaxFlightSpeed = 50
var ReverseSpeed = -10
var ThrottleDelta = 50
var TakeOffSpeed = 10

var SteeringSpeed = 10
var FlightSteeringSpeed = 30

var StableFlightSpeed = 40

var Acceleration = 10.0
var ForwardSpeed = 0
var LevelSpeed = 3.0
var TargetSpeed = 0
var TurnInput = 0
var TurnSpeed = 0.75
var PitchInput = 0
var PitchSpeed = 0.5

var Planemass = 0


var PlaneMovementStates = null

var PlaneSteeringStates = null
var PlaneDivingStates = null
var PlaneEngineStates = null
var PlaneGroundedStates = null

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

		SetPlaneMovementStates()
		FlightMovement(delta)



		#############################################################
		# Program ENDS here...


func FlightMovement(delta):

	print(PlaneGroundedStates)
#	print(PlaneDivingStates)
#	print(PlaneSteeringStates)
#	print(TargetSpeed)

	var FlightSteeringSpeedDeltaX = FlightSteeringSpeed * transform.basis.x * delta
	var FlightSteeringSpeedDeltaZ = FlightSteeringSpeed * transform.basis.z * delta
	var SteeringSpeedDelta = SteeringSpeed * transform.basis.y * delta


	if (PlaneGroundedStates == true):


		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			Planemass = 0
			pass

		if (PlaneEngineStates == "Reverse"):
			var limit = ReverseSpeed if GroundCheck.is_colliding() else MinFlightSpeed
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, limit)
			pass

		if (PlaneEngineStates == null):
			TargetSpeed = lerp(TargetSpeed, 0, 0.025) # Target Speed goes to 0 if no movement is pressed
			pass

		if (PlaneSteeringStates == "Right"):
			if (PlaneEngineStates == "Accelerate"):
				set_angular_velocity(-SteeringSpeedDelta)
			if (PlaneEngineStates == "Reverse"):
				set_angular_velocity(SteeringSpeedDelta)
			pass

		if (PlaneSteeringStates == "Left"):
			if (PlaneEngineStates == "Accelerate"):
				set_angular_velocity(SteeringSpeedDelta)
			if (PlaneEngineStates == "Reverse"):
				set_angular_velocity(-SteeringSpeedDelta)
			pass

		if (PlaneDivingStates == "Up"):
			if(TargetSpeed >= TakeOffSpeed):
				print("take off go")
				set_angular_velocity(-FlightSteeringSpeedDeltaX)
			else:
				print("take off NO go")
			pass

		if (PlaneDivingStates == "Down"):
			pass

	elif (PlaneGroundedStates == false):


		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			pass

		if (PlaneEngineStates == "Reverse"):
			pass


		if (PlaneEngineStates == null):
#			print("Not moving")
			pass

		
		if (PlaneSteeringStates == "Right"):
			set_angular_velocity(FlightSteeringSpeedDeltaZ)

		if (PlaneSteeringStates == "Left"):
			set_angular_velocity(-FlightSteeringSpeedDeltaZ)

		if (PlaneDivingStates == "Up"):
			set_angular_velocity(-FlightSteeringSpeedDeltaX)
			
		if (PlaneDivingStates == "Down"):
			set_angular_velocity(FlightSteeringSpeedDeltaX)
		


	# Accelerate/decelerate
	ForwardSpeed = lerp(ForwardSpeed, TargetSpeed, Acceleration * delta)
	# Movement is always forward
	Velocity = transform.basis.z * ForwardSpeed
	
	set_linear_velocity(Velocity)


func SetPlaneMovementStates():

	# Set Accelerate or Reverse
	if Input.is_action_pressed("LeftShift"):
		PlaneEngineStates = "Accelerate"
	elif Input.is_action_pressed("Spacebar"):
		PlaneEngineStates = "Reverse"
	else:
		PlaneEngineStates = null

	# Set Left or Right Controls
	if Input.is_action_pressed("MoveRight"):
		PlaneSteeringStates = "Right"
	elif Input.is_action_pressed("MoveLeft"):
		PlaneSteeringStates = "Left"
	else:
		PlaneSteeringStates = null

	# Set Up or Down Controls
	if Input.is_action_pressed("MoveForward"):
		PlaneDivingStates = "Up"
	elif Input.is_action_pressed("MoveBack"):
		PlaneDivingStates = "Down"
	else:
		PlaneDivingStates = null

	# Set Grounded True or False
	if(GroundCheck.is_colliding() == true):
		PlaneGroundedStates = true
	else:
		PlaneGroundedStates = false

	# INCLUDE VELOCITY VECTOR TO GLIDE LEFT OR RIGHT



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

func GetCameraOffset():
	return CameraOffset

func GetCameraZoomOffset():
	return CameraZoomOffset

func MyType():
	return "PLANE"


