extends KinematicBody

onready var GameRoot = get_node("/root").get_child(0)

export(NodePath) var CameraSetupNodePath
onready var CameraSetup = get_node(CameraSetupNodePath)

onready var PlayerInteractionRight = get_node("PilotInteractionRight")
onready var PlayerInteractionLeft = get_node("PilotInteractionLeft")
onready var Propeller = get_node("MeshInstances/Propeller")
onready var GroundCheck = get_node("GroundCheck")


onready var MeshBody = get_node("MeshInstances")

onready var PrototypePlaneUI = get_node("PrototypePlaneUI")
onready var PlaneRotationUI = get_node("PrototypePlaneUI/Panel/PlaneAxis")

onready var TrailRendererRight = get_node("TrailRendererRight")
onready var TrailRendererLeft = get_node("TrailRendererLeft")

# AUDIO
onready var EngineSound = get_node("EngineSound")

onready var LeftFiringSounds = get_node("LeftFiringSounds")
onready var RightFiringSounds = get_node("RightFiringSounds")

onready var LeftFireEffect = get_node("LeftFireEffect")
onready var LeftFireEffectAnim = get_node("LeftFireEffect/FireEffectAnimation")
onready var RightFireEffect = get_node("RightFireEffect")
onready var RightFireEffectAnim = get_node("RightFireEffect/FireEffectAnimation")

onready var LeftAimingRaycast = get_node("AimingLines/LeftAimingRaycast")
onready var RightAimingRaycast = get_node("AimingLines/RightAimingRaycast")

var AreaObject = null
var AreaName = null
var PlayerSpawn = null

var RNG = RandomNumberGenerator.new()

var FireTimer: float = 0
var FireRate: float = .1
var AimDeviation: float = 2
var OriginalLeftAimingRaycast = null
var OriginalRightAimingRaycast = null
var Bullet = preload("res://Weapons/Bullet.tscn")

onready var LeftFiringRaycast = get_node("FiringRaycast/LeftFiringRaycast")
onready var RightFiringRaycast = get_node("FiringRaycast/RightFiringRaycast")

var CameraOffset = {
	"horizontal": 12,
	"vertical": 50
}

var CameraZoomOffset = {
	"horizontal": 70,
	"vertical": 150
}


var Velocity = Vector3.ZERO

var Gravity = -9.8

var MaxFlightSpeed = 80
var MinUngroundedSpeed = 30
var MinFlightSpeed = 10
var ReverseSpeed = -10
var ThrottleDelta = 30
var TakeOffSpeed = 10

var SteeringSpeed = 2
var FlightSteeringSpeed = 5

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
	PrototypePlaneUI.hide()

	LeftFireEffect.hide()
	RightFireEffect.hide()
	
	LeftFireEffectAnim.stop()
	RightFireEffectAnim.stop()

	PlayerInteractionLeft.connect("area_entered", self, "EnteredSpitfireArea", [PlayerInteractionLeft])
	PlayerInteractionLeft.connect("area_exited", self, "ExitedSpitfireArea")
	
	PlayerInteractionRight.connect("area_entered", self, "EnteredSpitfireArea", [PlayerInteractionRight])
	PlayerInteractionRight.connect("area_exited", self, "ExitedSpitfireArea")

	OriginalLeftAimingRaycast = LeftFiringRaycast.rotation_degrees
	OriginalRightAimingRaycast = RightFiringRaycast.rotation_degrees

	pass # Replace with function body.


func _physics_process(delta):

	
	if (CameraSetup.ReturnMainCamera().is_current()):
		# Program STARTS here...
		#############################################################

		EnterVehicle() # Run Engine Animation/SoundEffects Function
#		ExitVehicle() # Exit Engine function

		SetPlaneMovementStates()
		RenderPlaneAimLines()
		FlightMovement(delta)

		#############################################################
		# Program ENDS here...
	else:
		pass
		
func _unhandled_input(event):
	if AreaName == "PLAYER" and Input.is_action_just_released("RideVehicle"):
		CameraSetup.ReturnMainCamera().make_current()
		AreaObject.queue_free()
	elif (CameraSetup.ReturnMainCamera().is_current() and Input.is_action_just_released("RideVehicle")):
		GameRoot.SpawnPlayer(PlayerSpawn.global_transform.origin)
		pass


func FlightMovement(delta):
	
	if (RightMouseButtonState == true):
		# Render AimLines ON
		PrototypePlaneUI.SetRenderAimLinesON()
		
		# REWORK FIRING state machines
		# Plane Firing
		if(LeftMouseButtonState == true):
			RightFiringSounds._set_playing(true)
			LeftFireEffectAnim.play("PlaneFireAnimation")
			RightFireEffectAnim.play("PlaneFireAnimation")
			FireGuns(delta, true)
		else: 
			RightFiringSounds._set_playing(false)
			LeftFireEffect.hide()
			RightFireEffect.hide()
			LeftFireEffectAnim.stop()
			RightFireEffectAnim.stop()
			FireGuns(delta, false)
	else:
		# Render AimLines OFF
		PrototypePlaneUI.SetRenderAimLinesOFF()
		
		RightFiringSounds._set_playing(false)

		LeftFireEffect.hide()
		RightFireEffect.hide()
		
		LeftFireEffectAnim.stop()
		RightFireEffectAnim.stop()
		
		

	if (PlaneGroundedStates == true):
		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			EngineSound.pitch_scale = 1

		if (PlaneEngineStates == "Reverse"):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, ReverseSpeed)
			rotation_degrees = lerp(rotation_degrees, Vector3(-10, rotation_degrees.y, rotation_degrees.z), 0.3)

		if (PlaneEngineStates == null):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, 0)
			EngineSound.pitch_scale = .6

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
		if (PlaneEngineStates == "Accelerate"):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			EngineSound.pitch_scale = 1
			
		if (PlaneEngineStates == "Reverse"):
			TargetSpeed = max(ForwardSpeed - ThrottleDelta * delta, ReverseSpeed)
			Velocity += global_transform.basis.y * -9.8 * delta
			
		if (PlaneEngineStates == null):
			TargetSpeed = min(ForwardSpeed + ThrottleDelta * delta, MaxFlightSpeed)
			Velocity += global_transform.basis.y * -9.8 * delta
			EngineSound.pitch_scale = .6

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
		Velocity = transform.basis.z * ForwardSpeed

	move_and_slide(Velocity, Vector3.UP)

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
		

	# INCLUDE VELOCITY VECTOR TO GLIDE LEFT OR RIGHT

func RenderPlaneAimLines():
	if(LeftAimingRaycast.is_colliding()):
		LeftAimingRaycastData.boolean = true
		LeftAimingRaycastData.coords = LeftAimingRaycast.get_collision_point()
	else:
		LeftAimingRaycastData.boolean = false
		LeftAimingRaycastData.coords = Vector3.ZERO
		
	if(RightAimingRaycast.is_colliding()):
		RightAimingRaycastData.boolean = true
		RightAimingRaycastData.coords = RightAimingRaycast.get_collision_point()
	else:
		RightAimingRaycastData.boolean = false
		RightAimingRaycastData.coords = Vector3.ZERO

func FireGuns(delta, onf):
	if onf == true:
		FireTimer -= delta
	
		if FireTimer < 0:
			FireTimer = FireRate
			RNG.randomize()
			var LeftRNGAimDeviation = RNG.randf_range(-AimDeviation, AimDeviation)
			
			RNG.randomize()
			var RightRNGAimDeviation = RNG.randf_range(-AimDeviation, AimDeviation)

			LeftFiringRaycast.rotation_degrees.x = OriginalLeftAimingRaycast.x + LeftRNGAimDeviation
			LeftFiringRaycast.rotation_degrees.y = OriginalLeftAimingRaycast.y + LeftRNGAimDeviation
			
			RightFiringRaycast.rotation_degrees.x = OriginalLeftAimingRaycast.x + RightRNGAimDeviation
			RightFiringRaycast.rotation_degrees.y = OriginalLeftAimingRaycast.y + RightRNGAimDeviation
			
			var rightBulletInstance = Bullet.instance()
			GameRoot.add_child(rightBulletInstance)
			rightBulletInstance.SetBullet(RightFiringRaycast, 0)
			
			var leftBulletInstance = Bullet.instance()
			GameRoot.add_child(leftBulletInstance)
			leftBulletInstance.SetBullet(LeftFiringRaycast, 0)
			
		else:
			FireGuns(delta, false)
	elif onf == false:
		LeftFiringRaycast.rotation_degrees = OriginalLeftAimingRaycast
		RightFiringRaycast.rotation_degrees = OriginalRightAimingRaycast

# firerate variable
	# rotate raycast every frame based on firerate
	pass

func EmmitSmokeTrails(boolean):
	TrailRendererLeft.render = boolean
	TrailRendererRight.render = boolean


func EnterVehicle():
	PrototypePlaneUI.show()
	EngineSound._set_playing(true) 
	Propeller.rotate_object_local(Vector3(0,0,1), 5)
	pass


func EnteredSpitfireArea(area, playerspawn):
	if(area.name == "PLAYER"):
		PlayerSpawn = playerspawn
		AreaObject = area.get_parent()
		AreaName = area.name
		pass
	
func ExitedSpitfireArea(area):
	AreaObject = null
	AreaName = null

##################################################
# PLANE AIM RAYCAST START
func ReturnRightAimingRaycast():
	return RightAimingRaycastData

func ReturnLeftAimingRaycast():
	return LeftAimingRaycastData
# PLANE AIM RAYCAST END	
##################################################


func GetCameraOffset():
	return CameraOffset

func GetCameraZoomOffset():
	return CameraZoomOffset

func MyType():
	return "PLANE"


