extends KinematicBody
# REWORK TO RIGIDBODY IF POSSIBLE


var CameraOffset = {
	"horizontal": 12,
	"vertical": 50
}

var active = false

# Reverse speed
var reverse_speed = -5
# Can't fly below this speed
var min_flight_speed = 15
# Maximum airspeed
var max_flight_speed = 80
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

var SteeringSpeed = 3
var SteeringSpeedWeight = 0.3
var LerpVertical
var HorizontalVertical

var velocity = Vector3.ZERO
var turn_input = 0
var pitch_input = 0

var planemass = 100 # use later

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

	if Input.is_action_pressed("Spacebar"):
		target_speed = min(forward_speed + throttle_delta * delta, max_flight_speed)
	elif Input.is_action_pressed("LeftShift"):
		if $RayCast.is_colliding() == true:
			# rotate NOT by physics plane back to zero with lerp
			
			pass
		var limit = reverse_speed if grounded else min_flight_speed
		target_speed = max(forward_speed - throttle_delta * delta, limit)
	else: 
		target_speed = lerp(target_speed, 0, 0.025) # Target Speed goes to 0 if no movement is pressed
		
	
	PoorDebug("target_speed", target_speed)
	
	
	if Input.is_action_pressed("MoveBack"):
		# Flying Down Here
		if(target_speed >= take_off_speed):
			print("take off go")
			rotate_object_local(Vector3(0, 0, -1), SteeringSpeed * delta) # Rotate Local
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
			rotate_object_local(Vector3(0, 0, 1), SteeringSpeed * delta) # Rotate Local
		else:
			print("take off NO go")
			
		# Flying Animation
		if(BackWingAnimation.RotateUp == false):
			$BackWingAnimationNode.play("BackWingMoveUp")
			BackWingAnimation.RotateUp = true
	else:
		# Flying Animation
		BackWingAnimation.RotateUp = false
		
	PoorDebug("Raycast Colliding", $RayCast.is_colliding())
	if($RayCast.is_colliding() == true):
		# rework to check velocity for rotation
		if Input.is_action_pressed("MoveLeft"):
			if Input.is_action_pressed("Spacebar"):
				rotate_y(SteeringSpeed * delta)
			elif Input.is_action_pressed("LeftShift"):
				rotate_y(-SteeringSpeed * delta)
		pass
		
		if Input.is_action_pressed("MoveRight"):
			if Input.is_action_pressed("Spacebar"):
				rotate_y(-SteeringSpeed * delta)
			elif Input.is_action_pressed("LeftShift"):
				rotate_y(SteeringSpeed * delta)
		pass
	elif($RayCast.is_colliding() == false):
		# MOVELEFT
		if Input.is_action_pressed("MoveLeft"):
			rotate_object_local(Vector3(-1,0,0), lerp(0, SteeringSpeed, SteeringSpeedWeight) * delta) # Rotate Local
			if(FrontWingAnimation.RotateLeft == false):
				$FrontWingAnimationNode.play("RotateLeft")
				FrontWingAnimation.RotateLeft = true
		else:
			FrontWingAnimation.RotateLeft = false
		
	# MOVERIGHT
		if Input.is_action_pressed("MoveRight"):
			rotate_object_local(Vector3(1,0,0), lerp(0, SteeringSpeed, SteeringSpeedWeight) * delta) # Rotate Local
			if(FrontWingAnimation.RotateRight == false):
				$FrontWingAnimationNode.play("RotateRight")
				FrontWingAnimation.RotateRight = true
		else:
			FrontWingAnimation.RotateRight = false
		
		
	# Reset Animations if not AD is being pressed
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
	velocity = $RayCast.global_transform.basis.x * forward_speed
	var currentplanemass
	
	if target_speed >= min_flight_speed:
		currentplanemass = 1
	else:
		currentplanemass = planemass
		
	velocity.y += -9.8 * currentplanemass * delta
	velocity = move_and_slide(velocity, Vector3.UP)

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


####################################################################

func PoorDebug(Name, Value):
#	print(Name + ": " + String(Value))
	pass
