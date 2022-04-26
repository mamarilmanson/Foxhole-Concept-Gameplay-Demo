extends KinematicBody

export(NodePath) var PackagedIndicatorNodePath
export(NodePath) var BeingCarriedIndicatorNodePath

onready var PackagedIndicator = get_node(PackagedIndicatorNodePath)
onready var BeingCarriedIndicator = get_node(BeingCarriedIndicatorNodePath)

onready var ContainerArea = get_node("ContainerArea")
onready var ContainerCollision = get_node("ContainerCollision")
onready var Chute = get_node("Chute")
onready var PackageUI = get_node("UserInterface/PackageUI")
onready var PackageLabel = get_node("UserInterface/PackageUI/Label")
onready var ProgressTextureParent = get_node("UserInterface/TextureProgressParent")
onready var ProgressTexture = get_node("UserInterface/TextureProgressParent/TextureProgress")
onready var ProgressTextureLabel = get_node("UserInterface/TextureProgressParent/TextureProgress/Label")
onready var FloorDetectorArea = get_node("FloorDetectorArea")
onready var ContainerAnimations = get_node("ContainerAnimations")

var ContainerStates = ["normal", "packaged", "beingcarried", "dropped"]
var ContainerStateCounter = 0
var Gravity = -9.8
var Velocity = Vector3.ZERO

var ParentCrane = null
var CraneDistance = null
var RecordRotation = null

# Called when the node enters the scene tree for the first time.
func _ready():
	PackageUI.hide()
	ProgressTexture.hide()
	Chute.hide()
	
	ContainerArea.connect("area_entered", self, "EnteredContainerArea")
	ContainerArea.connect("area_exited", self, "ExitedContainerArea")
	pass # Replace with function body.
	

func _physics_process(delta):
	
	if(ContainerStates[ContainerStateCounter] == "beingcarried"):
		ContainerCollision.disabled = true
		PackagedIndicator.hide()
		BeingCarriedIndicator.show()
		global_transform.origin = ParentCrane.global_transform.origin - Vector3(0, CraneDistance, 0)
	elif(ContainerStates[ContainerStateCounter] == "dropped"):
		Chute.show()
		ContainerAnimations.play("ProgressAnimation")
		ContainerAnimations.seek(3, true)
		Velocity.y += Gravity * delta * 0.005
#		print(Velocity)
		var moveCollide = move_and_collide(Velocity, false)
		
		if (moveCollide):
			if (moveCollide.collider.name == "GROUND"):
				ContainerStateCounter = 1
				Chute.hide()
	else:
		ContainerCollision.disabled = false
		PackagedIndicator.show()
		BeingCarriedIndicator.hide()
	
		ProgressTextureParent.set_position(get_viewport().get_camera().unproject_position(global_transform.origin))
		
		if(PackageUI.visible) and Input.is_action_just_pressed("Interact"):
			if(ContainerStates[ContainerStateCounter] == "normal"):
				ContainerAnimations.play("ProgressAnimation")
				ProgressTextureLabel.text = "Packaging..."
				ContainerStateCounter = 1
				PackageLabel.text = "E: Unpack Container"
			elif(ContainerStates[ContainerStateCounter] == "packaged"):
				ContainerAnimations.play_backwards("ProgressAnimation")
				ProgressTextureLabel.text = "Unpacking..."
				ContainerStateCounter = 0
		pass

func SetCrane(dictionary):
	if (dictionary.beingcarried == true):
		ContainerStateCounter = 2
		ParentCrane = dictionary.crane
		CraneDistance = dictionary.distance
	elif (dictionary.beingcarried == false):
		ContainerStateCounter = 1
		ParentCrane = null
		CraneDistance = null
	pass

func MatchTargetRotation(target, weight):
	rotation.y = lerp(RecordRotation, target.rotation.y, weight)
	pass
	
func SetRecordRotation():
	RecordRotation = rotation.y
	pass

func ReturnContainerState():
	return ContainerStates[ContainerStateCounter]
	
func EnteredContainerArea(area):
	if(area.name == "PLAYER"):
		if(ContainerStates[ContainerStateCounter] == "normal"):
			PackageLabel.text = "E: Package Container"
		elif(ContainerStates[ContainerStateCounter] == "packaged"):
			PackageLabel.text = "E: Unpack Container"
		PackageUI.show()
	pass
	
func ExitedContainerArea(area):
	if(area.name == "PLAYER"):
		PackageUI.hide()
	pass
	
func BeingDropped(spawnlocation):
	global_transform.origin = spawnlocation.global_transform.origin
	ContainerStateCounter = 3
	
func ReturnFloorDetectorArea():
	return FloorDetectorArea.get_overlapping_areas()

func MyType():
	return "SHIPPABLE"
