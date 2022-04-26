extends RigidBody
# REWORK TO RIGIDBODY IF POSSIBLE


var active = false

##########################################################
# CAMERA VARIABLES
##########################################################

var MonitorCenter = Vector2()
var MousePosition = Vector2()
var MouseOffset = Vector2()

var CameraMoveMultiplyer = 0
var CameraMoveMultiplyerDefault = 0.02
var CameraMoveMultiplyerRightClick = 0.08
var CameraMoveMultiplyerZoom = 0.1

var CameraRotationDifference = 0
var CurrentPlayerRotation = 0
var YRotation = 0
var RememberMousePositionOnce = {
	"coord": Vector2(),
	"isset": false
}
#
#onready var MainCamera = get_node("CameraSetup/CameraParent/Camera")
#onready var CameraParent = get_node("CameraSetup/CameraParent")
#onready var CameraSetup = get_node("CameraSetup")
#
#onready var LookAtMouse = get_node("GUI/LookAtMouse")
#onready var LookAtMouseInitial = get_node("GUI/LookAtMouseInitial")

##########################################################

# Reverse speed
var reverse_speed = -5
# Can't fly below this speed
var min_flight_speed = 15
# Maximum airspeed
var max_flight_speed = 50
# Turn rate
var turn_speed = 0.75
# Climb/dive rate
var pitch_speed = 0.5
# Wings "autolevel" speed
var level_speed = 3.0
# Throttle change speed
var throttle_delta = 30
# Acceleration/deceleration
var acceleration = 6.0

# Current speed
var forward_speed = 0
# Throttle input speed
var target_speed = 0
# Lets us change behavior when grounded
var grounded = true

var steering_speed = 0.15

var velocity = Vector3.ZERO
var turn_input = 0
var pitch_input = 0

var planemass = 100

var take_off_speed = 10

onready var Propeller = get_node("PropellerParent")
onready var Anim = get_node("CorsairAnimations")
onready var FrontWingAnimationNode = get_node("FrontWingAnimationNode")
onready var BackWingAnimationNode = get_node("BackWingAnimationNode")

var LandingGear = true

var FrontWingAnimation = {
	"RotateLeft": false,
	"RotateRight": false
}

var BackWingAnimation = {
	"RotateUp": false,
	"RotateDown": false
}


# Called when the node enters the scene tree for the first time.
func _ready():
	$CockpitAnimationNode.play("CockPitClosing")
	$LandingGearAnimationNode.play("WheelsOpenClose", 0, 0)
	
	
	
	pass # Replace with function body.


func _physics_process(delta):
	##########################################################
	# PLANE SCRIPTS
	##########################################################
	
	FlightMovement(delta)
	StartEngine()
	

	##########################################################
	# CAMERA SCRIPTS
	##########################################################
	
	MonitorCenter = get_viewport().get_size() / 2
	MousePosition = get_viewport().get_mouse_position()
	MouseOffset = MousePosition - MonitorCenter
	
	if Input.is_action_pressed("RightMouseButton"):
		CameraMoveMultiplyer = lerp(CameraMoveMultiplyer, CameraMoveMultiplyerRightClick, 0.05)
	else:
		CameraMoveMultiplyer = lerp(CameraMoveMultiplyer, CameraMoveMultiplyerDefault, 0.05)

	#MiddleMouseButton
#	RotateCamera()
	
	##########################################################
	pass
	
func _input(event):
	if Input.is_action_just_released("ModeChange"):
		if (LandingGear == true):
			$LandingGearAnimationNode.play("WheelsOpenClose")
			$Collision_LeftWheel.disabled = true
			$Collision_RightWheel.disabled = true
			$Collision_BackWheel.disabled = true
			rotation_degrees.z -= 10
			
			LandingGear = false
		elif (LandingGear == false):
			$LandingGearAnimationNode.play_backwards("WheelsOpenClose")
			$Collision_LeftWheel.disabled = false
			$Collision_RightWheel.disabled = false
			$Collision_BackWheel.disabled = false
			LandingGear = true
			rotation_degrees.z += 10
			
#			global_transform.basis.z = 0
		
	pass

func StartEngine():
	Propeller.rotate_object_local(Vector3(1,0,0), 60)
	pass


func FlightMovement(delta):
	if Input.is_action_pressed("LeftShift"):
		target_speed = min(forward_speed + throttle_delta * delta, max_flight_speed)
	elif Input.is_action_pressed("Spacebar"):
		var limit = reverse_speed if grounded else min_flight_speed
		target_speed = max(forward_speed - throttle_delta * delta, limit)
	else: 
		target_speed = lerp(target_speed, 0, 0.025) # Target Speed goes to 0 if no movement is pressed
		
#	print(grounded)
	
	
	if Input.is_action_pressed("MoveBack"):
		# Flying Down Here
		if(target_speed >= take_off_speed):
			print("take off go")
			rotate_x(steering_speed * delta)
		else:
			print("take off NO go")
		
		
		# Flying Animation
		if(BackWingAnimation.RotateDown == false):
			$BackWingAnimationNode.play("BackWingMoveDown")
			BackWingAnimation.RotateDown = true
	else:
		# Flying Animation
		BackWingAnimation.RotateDown = false
		
		
	if Input.is_action_pressed("MoveForward"):
		# Flying Up Here
		if(target_speed >= take_off_speed):
			print("take off go")
			rotate_x(-steering_speed * delta)
		else:
			print("take off NO go")
			
		# Flying Animation
		if(BackWingAnimation.RotateUp == false):
			$BackWingAnimationNode.play("BackWingMoveUp")
			BackWingAnimation.RotateUp = true
	else:
		# Flying Animation
		BackWingAnimation.RotateUp = false
		
	
	if(grounded == true):
		# rework to check velocity for rotation
		if Input.is_action_pressed("MoveLeft"):
			if Input.is_action_pressed("LeftShift"):
				rotate_y(steering_speed * delta)
			elif Input.is_action_pressed("Spacebar"):
				rotate_y(-steering_speed * delta)
		pass
		
		if Input.is_action_pressed("MoveRight"):
			if Input.is_action_pressed("LeftShift"):
				rotate_y(-steering_speed * delta)
			elif Input.is_action_pressed("Spacebar"):
				rotate_y(steering_speed * delta)
		pass
	else:
		# MOVELEFT
		if Input.is_action_pressed("MoveLeft"):
			if(FrontWingAnimation.RotateLeft == false):
				$FrontWingAnimationNode.play("RotateLeft")
#				$RayCast.rotate_object_local(Vector3(-1,0,0), steering_speed * delta) # Rotate Local
				FrontWingAnimation.RotateLeft = true
		else:
			FrontWingAnimation.RotateLeft = false
		
	# MOVERIGHT
		if Input.is_action_pressed("MoveRight"):
			if(FrontWingAnimation.RotateRight == false):
				$FrontWingAnimationNode.play("RotateRight")
#				$RayCast.rotate_object_local(Vector3(1,0,0), steering_speed * delta) # Rotate Local
				FrontWingAnimation.RotateRight = true
		else:
			FrontWingAnimation.RotateRight = false
		
		
	if(FrontWingAnimation.RotateRight == false and FrontWingAnimation.RotateLeft == false):
		$FrontWingAnimationNode.play("RotateLeft", 0, 0)
		$FrontWingAnimationNode.play("RotateRight", 0, 0)
	pass
	
	if(BackWingAnimation.RotateDown == false and BackWingAnimation.RotateUp == false):
		$BackWingAnimationNode.play("BackWingMoveDown", 0, 0)
		$BackWingAnimationNode.play("BackWingMoveUp", 0, 0)
	pass
	
	
	# Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, acceleration * delta)
	# Movement is always forward
	velocity = transform.basis.x * forward_speed
	velocity.y += -9.8 * planemass * delta

##########################################################
# CAMERA FUNCTIONS
##########################################################


####################################################################

func GetInPlane():
	active = true
	pass
	
func GetOutPlane():
	active = false
	pass
