extends KinematicBody

#REWORK: Transfer camerasetup function to GameRoot
var CameraSetupInstance = preload("res://Scenes/CameraSetup.tscn")

export(NodePath) var CameraSetupNodePath

onready var CameraSetup = get_node(CameraSetupNodePath)


onready var CameraSetupNode = get_node("CameraSetup")

onready var PromptUI = get_node("PlayerUI/Prompt")
onready var PromptUIKey = get_node("PlayerUI/Prompt/MarginContainer/HBoxContainer/ButtonMargin/InnerButtonMargin/KeyButton")
onready var PromptUIInstructions = get_node("PlayerUI/Prompt/MarginContainer/HBoxContainer/Instructions")

onready var GameRoot = get_node("/root").get_child(0)

onready var PlayerBody = get_node("PlayerBody")
onready var PlayerHand = get_node("PlayerBody/PlayerMesh/Hand")
onready var LookAtReference = get_node("LookAtReference")
onready var BarrelOpening = get_node("PlayerBody/PlayerMesh/Hand/BarrelOpening")


var RNG = RandomNumberGenerator.new()
var FireTimer: float = 0
var FireRate: float = .1
var AimDeviation: float = 2
var OriginalPlayerFiringRaycast = null
var Bullet = preload("res://Weapons/Bullet.tscn")
onready var PlayerFiringRaycast = get_node("PlayerBody/PlayerMesh/Hand/PlayerFiringRaycast")

var AimingModes = ["normal", "modified", "scrollwheel"]

var GetCameraParent = null
var CameraVertical = Vector3()
var CameraHorizontal = Vector3()

var isMoving = false
var MovementStates = null

var velocity = Vector3()
var NormalSpeed = 8
var RunSpeed = 16
var WalkSpeed = 4
var gravity = -9.8

var VehicleArea = {
	"isset": false,
	"content": null,
	"seatselected": null
}

var CameraOffset = {
	"horizontal": 10,
	"vertical": 30
}

var CameraZoomOffset = {
	"horizontal": 50,
	"vertical": 50
}

var CameraCustomAimHeightOffset = {
	"horizontal": 30,
	"vertical": 150
}

var AimingMode = 0
var AimingHeight = 0
var MaxAimingHeight = 100


func _ready():
	HidePrompt()
	AimingHeight = MaxAimingHeight
	
	OriginalPlayerFiringRaycast = PlayerFiringRaycast.rotation_degrees
	
	# Player Area Connection
	$PLAYER.connect("area_entered", self, "PlayerAreaEntered")
	$PLAYER.connect("area_exited", self, "PlayerAreaExited")
	pass
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if(CameraSetup.ReturnMainCamera().is_current() == true):
	
		SetMovementStates()
		GetCameraParent = get_viewport().get_camera().get_parent()
		CameraVertical = GetCameraParent.global_transform.basis.z
		CameraHorizontal = GetCameraParent.global_transform.basis.x


		if (MovementStates == "Normal"):
			CameraSetupNode.SetAimingCursorOFF()

		if (MovementStates == "Aiming"):
			Aiming()

		if (MovementStates == "Firing"):
			Aiming()
			FireGuns(delta, true)
		else:
			FireGuns(delta, false)
			
		if (MovementStates == "Running"):
			CameraSetupNode.SetAimingCursorOFF()

		if VehicleArea.isset == true and Input.is_action_just_released("RideVehicle") and MovementStates == "Aiming":
			VehicleArea.content.add_child(CameraSetupInstance.instance())
			VehicleArea.content.SetActiveTrue(VehicleArea.seatselected)
			GameRoot.SetRememberRotation(CameraSetupNode.rotation.y)
			queue_free() # Delete Player from Game Tree
			
		# Movement
		# Include PlayerBody Orientation
		PlayerMovement(delta)

func _input(event):
	if(event is InputEventMouseButton and AimingModes[AimingMode] == "scrollwheel"):
		var aimheightincreament = 2
		if(event.button_index == 4):
			AimingHeight += aimheightincreament
		elif(event.button_index == 5):
			AimingHeight -= aimheightincreament
			
		AimingHeight = clamp(AimingHeight, 0, MaxAimingHeight)

	CameraSetupNode.SetCustomAimHeightCollitionPoint(AimingHeight)
################################################################################


################################################################################
func _unhandled_input(_event):
	if Input.is_action_just_released("AimingMode"):
		if(AimingMode < 2):
			AimingMode += 1
		else:
			AimingMode = 0
		
		print(AimingModes[AimingMode])
		pass
################################################################################


################################################################################
func PlayerMovement(delta):
	# REWORK: rotation to match global camera rotation similar to 3rd person controller
	velocity = Vector3()
	
	# REWORK: match player body to rotation
	if Input.is_action_pressed("ui_right"):
		velocity += CameraHorizontal
	if Input.is_action_pressed("ui_left"):
		velocity -= CameraHorizontal
	if Input.is_action_pressed("ui_up"):
		velocity -= CameraVertical
	if Input.is_action_pressed("ui_down"):
		velocity += CameraVertical
	
	# DIRTY MOVEMENT CHECK
	if(!Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down")):
		isMoving = false
	else:
		isMoving = true
		
		
	velocity.y += gravity * delta
	

	if (MovementStates == "Normal"):
		velocity = velocity.normalized() * NormalSpeed
		if (isMoving == true):
			PlayerBody.look_at(Vector3(global_transform.origin.x + velocity.x, PlayerBody.global_transform.origin.y, global_transform.origin.z + velocity.z), Vector3(0, 1, 0))

	if (MovementStates == "Aiming"):
		velocity = velocity.normalized() * WalkSpeed
		pass

	if (MovementStates == "Running"):
		velocity = velocity.normalized() * RunSpeed
		if (isMoving == true):
			PlayerBody.look_at(Vector3(global_transform.origin.x + velocity.x, PlayerBody.global_transform.origin.y, global_transform.origin.z + velocity.z), Vector3(0, 1, 0))

	move_and_slide(velocity, Vector3.UP, false, 4, 0.785398, false)
################################################################################


################################################################################
func Aiming():
	# PlayerHand Lookat
	PlayerHand.look_at(CameraSetupNode.ReturnRayCastCollitionPoint(), Vector3.UP)
	
	# PlayerBody Lookat
	PlayerBody.rotation.y = LookAtReference.rotation.y
	LookAtReference.look_at(CameraSetupNode.ReturnRayCastCollitionPoint(), Vector3.UP)

	# Drawline
	if(AimingModes[AimingMode] == "normal"):
		CameraSetupNode.SetAimingCursorON("Aiming", CameraSetupNode.ReturnRayCastCollitionPoint())
	elif(AimingModes[AimingMode] == "modified"):
		CameraSetupNode.SetAimingCursorON("ModifiedAiming", CameraSetupNode.ReturnRayCastCollitionPoint())
	elif(AimingModes[AimingMode] == "scrollwheel"):
		CameraSetupNode.SetAimingCursorON("CustomAiming", CameraSetupNode.ReturnRayCastCollitionPoint())
################################################################################


################################################################################
func SetMovementStates():
	# SET MOVEMENT STATES LOGIC
	if Input.is_action_pressed("RightMouseButton"):
		if Input.is_action_pressed("LeftMouseButton"):
			MovementStates = "Firing"
		else:
			MovementStates = "Aiming"
	elif Input.is_action_pressed("LeftShift"):
		MovementStates = "Running"
	else:
		MovementStates = "Normal"
################################################################################


################################################################################
func PlayerAreaEntered(area):
	if area.is_in_group("plane"):
		ShowPrompt("Q", "to Enter the Spitfire")
		VehicleArea.isset = true
		VehicleArea.content = area.get_parent()
		VehicleArea.seatselected = area
################################################################################


################################################################################
func PlayerAreaExited(area):
	if area.is_in_group("plane"):
		HidePrompt()
		VehicleArea.isset = false
		VehicleArea.content = null
		VehicleArea.seatselected = null
################################################################################


################################################################################
func FireGuns(delta, onf):
	if onf == true:
		FireTimer -= delta
	
		if FireTimer < 0:
			FireTimer = FireRate
			RNG.randomize()
			var firingRNGAimDeviation = RNG.randf_range(-AimDeviation, AimDeviation)
		

			PlayerFiringRaycast.rotation_degrees.x = OriginalPlayerFiringRaycast.x + firingRNGAimDeviation
			PlayerFiringRaycast.rotation_degrees.y = OriginalPlayerFiringRaycast.y + firingRNGAimDeviation
				
			var bulletInstance = Bullet.instance()
			GameRoot.add_child(bulletInstance)
			bulletInstance.SetBullet(PlayerFiringRaycast, 0)
			
		else:
			FireGuns(delta, false)
	elif onf == false:
		PlayerFiringRaycast.rotation_degrees = OriginalPlayerFiringRaycast
################################################################################


################################################################################
func ShowPrompt(key, instructions):
	PromptUI.show()
	PromptUIKey.set_text(key)
	PromptUIInstructions.set_text(instructions)

func HidePrompt():
	PromptUI.hide()

func PoorDebug(Name, Value):
	print(Name + ": " + String(Value))
	

func GetCameraOffset():
	return CameraOffset

func GetCameraZoomOffset():
	if(AimingModes[AimingMode] == "scrollwheel"):
		return CameraCustomAimHeightOffset
	else:
		return CameraZoomOffset

func MakeCurrent():
	CameraSetup.ReturnMainCamera().make_current()
	
func End():
	queue_free()

func MyType():
	return "PLAYER"
