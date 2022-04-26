extends KinematicBody

onready var GameRoot = get_node("/root").get_child(0)

var ContainerResource = preload("res://Objects/Container.tscn")

# 2D
onready var GUI = get_node("GUI")
onready var SpeedIndicator = get_node("GUI/SpeedIndicator")

# 3D
export(NodePath) var CameraSetupNodePath
export(NodePath) var C47ParatrooperPlaneNodePath
export(NodePath) var GroundCheckNodePath
export(NodePath) var TrailRendererLeftPath
export(NodePath) var TrailRendererRightPath

onready var CameraSetup = get_node(CameraSetupNodePath)
onready var C47ParatrooperPlane: Spatial = get_node(C47ParatrooperPlaneNodePath)
onready var FlapsAnimations = get_node("C47ParatrooperPlane/FlapsAnimations")
onready var LeftEnigne = get_node("C47ParatrooperPlane/LeftEnigne")
onready var RightEngine = get_node("C47ParatrooperPlane/RightEngine")
onready var GroundCheck = get_node(GroundCheckNodePath)
onready var PlayerSpawn = get_node("PlayerSpawn")
onready var TrailRendererLeft = get_node(TrailRendererLeftPath)
onready var TrailRendererRight = get_node(TrailRendererRightPath)

onready var ContainerSpawn = get_node("ContainerSpawn")

onready var Container001 = get_node("Container001")
onready var Container002 = get_node("Container002")

onready var LeftParatooperArea = get_node("LeftParatooperArea")
onready var RightParatooperArea = get_node("RightParatooperArea")

onready var CheatingDirection = get_node("CheatingDirection")

onready var PlaneWheels = get_node("PlaneWheels")

var Inventory = 0

var PlaneModes = ["FlapsClosed", "FlapsOpen"]
var PlaneModesCounter = 0

var AreaObject = null
var AreaName = null

var CameraOffset = {
	"horizontal": 12,
	"vertical": 50
}

var CameraZoomOffset = {
	"horizontal": 70,
	"vertical": 150
}

var SeatSelected = null
var SetActive = false


var Velocity = Vector3.ZERO

var Gravity = -9.8

var MaxFlightSpeed = 60
var MinUngroundedSpeed = 20
var MinFlightSpeed = 5
var ReverseSpeed = -5
var ThrottleDelta = 10
var TakeOffSpeed = 30

var SteeringSpeed = 0.1
var FlightSteeringSpeed = .5

var Acceleration = 10.0
var ForwardSpeed = 0
var LevelSpeed = 3.0
var TargetSpeed = 0
var TurnInput = 0
var TurnSpeed = 0.75
var PitchInput = 0
var PitchSpeed = 0.5

var PlaneSteeringStates = null
var PlaneDivingStates = null
var PlaneEngineStates = null
var PlaneGroundedStates = null
var MovingVectorState = null
var Grounded = false

var LeftMouseButtonState = false
var RightMouseButtonState = false

var DeltaLerp = 0
var SteeringSpeedLerp = 0
var FlightSteeringSpeedLerp = 0

var LeftAimingRaycastData = {"boolean": false,"coords": Vector3()}
var RightAimingRaycastData = {"boolean": false,"coords": Vector3()}


# Called when the node enters the scene tree for the first time.
func _ready():
	GUI.hide()
	
	FlapsAnimations.play("TopFlapsOpening", -1, 0)
	
	LeftParatooperArea.connect("area_entered", self, "EnteredParatrooperArea")
	LeftParatooperArea.connect("area_exited", self, "ExitedParatrooperArea")
	
	RightParatooperArea.connect("area_entered", self, "EnteredParatrooperArea")
	RightParatooperArea.connect("area_exited", self, "ExitedParatrooperArea")
	
	pass # Replace with function body.


func _physics_process(delta):
	ShowInventory()
	SetupUI()


	if (CameraSetup.ReturnMainCamera().is_current()):
		# Program STARTS here...
		#############################################################


		EnterVehicle() # Run Engine Animation/SoundEffects Function
		ExitVehicle() # Exit Engine function

		SetPlaneMovementStates()
		FlightMovement(delta)
		

		#############################################################
		# Program ENDS here...
	else:
		pass


func _unhandled_input(_event):
	if AreaName == "PLAYER" and Input.is_action_just_released("RideVehicle"):
		CameraSetup.ReturnMainCamera().make_current()
		AreaObject.queue_free()
		AreaName = null
	elif (CameraSetup.ReturnMainCamera().is_current() and Input.is_action_just_released("RideVehicle")):
		GameRoot.SpawnPlayer(PlayerSpawn.global_transform.origin)
		
	if (CameraSetup.ReturnMainCamera().is_current()):
		SetModes()
	
		
func FlightMovement(delta):
	if (PlaneGroundedStates == true):
		PlaneWheels.show()
		
		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)

		if (PlaneEngineStates == "Reverse"):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, ReverseSpeed)

		if (PlaneEngineStates == null):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, 0)

		if (PlaneSteeringStates == "Right"):
			if (MovingVectorState == "Forward"):
				rotate_y(-SteeringSpeed * delta)
			if (MovingVectorState == "Backward"):
				rotate_y(SteeringSpeed * delta)

		if (PlaneSteeringStates == "Left"):
			if (MovingVectorState == "Forward"):
				rotate_y(SteeringSpeed * delta)
			if (MovingVectorState == "Backward"):
				rotate_y(-SteeringSpeed * delta)

		if (PlaneDivingStates == "Up"):
			if(TargetSpeed >= TakeOffSpeed):
				rotate_object_local(Vector3(1,0,0), -SteeringSpeed * delta)

		if (PlaneDivingStates == "Down"):
			pass
		
	elif (PlaneGroundedStates == false):
		PlaneWheels.hide()
		
		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			
		if (PlaneEngineStates == "Reverse"):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, ReverseSpeed)
			Velocity += global_transform.basis.y * -9.8 * delta
			
		if (PlaneEngineStates == null):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			Velocity += global_transform.basis.y * -9.8 * delta

		if (PlaneSteeringStates == "Right"):
			FlightSteeringSpeedLerp += delta
			EmmitSmokeTrails(true)
			rotate_object_local(Vector3(0,0,1), lerp(0, FlightSteeringSpeed, clamp(FlightSteeringSpeedLerp, 0, 1)) * delta)

		if (PlaneSteeringStates == "Left"):
			FlightSteeringSpeedLerp += delta
			EmmitSmokeTrails(true)
			rotate_object_local(Vector3(0,0,-1), lerp(0, FlightSteeringSpeed, clamp(FlightSteeringSpeedLerp, 0, 1)) * delta)
			
		if (PlaneSteeringStates == null):
			FlightSteeringSpeedLerp = 0

		if (PlaneDivingStates == "Up"):
			SteeringSpeedLerp += delta
			EmmitSmokeTrails(true)
			rotate_object_local(Vector3(-1,0,0), lerp(0, SteeringSpeed, clamp(SteeringSpeedLerp, 0, 1)) * delta)

		if (PlaneDivingStates == "Down"):
			SteeringSpeedLerp += delta
			EmmitSmokeTrails(true)
			rotate_object_local(Vector3(1,0,0), lerp(0, SteeringSpeed, clamp(SteeringSpeedLerp, 0, 1)) * delta)

		if (PlaneDivingStates == null):
			SteeringSpeedLerp = 0
		

		if (PlaneDivingStates == null and PlaneSteeringStates == null):
			EmmitSmokeTrails(false)
	

	ForwardSpeed = lerp(ForwardSpeed, TargetSpeed, Acceleration * delta)
	
	if (PlaneEngineStates != null):
		if(TargetSpeed >= TakeOffSpeed):
			Velocity = global_transform.basis.z * ForwardSpeed
		else:
			Velocity = CheatingDirection.global_transform.basis.z * ForwardSpeed

	move_and_slide(Velocity, Vector3.UP)

func SetModes():
	if Input.is_action_just_released("ModeChange"): # F
		if (PlaneGroundedStates == true): # ONGROUND
			if(PlaneModesCounter < 1):
				PlaneModesCounter += 1
			else:
				PlaneModesCounter = 0
		
			# PLAY ANIMATION BASED ON CURRENT STATE
			match PlaneModesCounter:
				0: FlapsAnimations.play("FlapsClosing")
				1: FlapsAnimations.play("TopFlapsOpening")
				
		elif (PlaneGroundedStates == false): # FLYING
			print("F Key being pressed while flying")
			if Inventory > 0:
				var ContainerResourceInstance = ContainerResource.instance()
				GameRoot.add_child(ContainerResourceInstance)
				ContainerResourceInstance.BeingDropped(ContainerSpawn)
				DespawnInventory()
				ContainerResourceInstance = null
			else:
				print("No More Inventory...")

func SetupUI():
	if (CameraSetup.ReturnMainCamera().is_current()):
		GUI.show()
		SpeedIndicator.text = String(TargetSpeed)
	else:
		GUI.hide()
		
	


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
		
	if(TargetSpeed > 0):
		MovingVectorState = "Forward"
	elif(TargetSpeed < 0):
		MovingVectorState = "Backward"
	else:
		MovingVectorState = null
	
	if Input.is_action_pressed("LeftMouseButton"):
		LeftMouseButtonState = true
	else:
		LeftMouseButtonState = false
		
	if Input.is_action_pressed("RightMouseButton"):
		RightMouseButtonState = true
	else:
		RightMouseButtonState = false
		



func EmmitSmokeTrails(boolean):
	TrailRendererLeft.render = boolean
	TrailRendererRight.render = boolean

func EnteredParatrooperArea(area):
	if(area.name == "PLAYER"):
		AreaName = area.name
		AreaObject = area.get_parent()
		pass
	
func ExitedParatrooperArea(area):
	AreaObject = null
	AreaName = null
	if(area.name == "PLAYER"):
		pass



func EnterVehicle():
	LeftEnigne.play("LeftEngine")
	RightEngine.play("RightEngine")
	pass

func ExitVehicle():
	pass

func ShowInventory():
	match (Inventory):
		0:
			Container001.hide()
			Container002.hide()
		1:
			Container001.show()
			Container002.hide()
		2:
			Container001.show()
			Container002.show()
	pass


func SpawnInventory():
	Inventory += 1
	pass
	
func DespawnInventory():
	Inventory -= 1
	pass

func GetCameraOffset():
	return CameraOffset

func GetCameraZoomOffset():
	return CameraZoomOffset

func MyType():
	return "PARATROOPERPLANE"
