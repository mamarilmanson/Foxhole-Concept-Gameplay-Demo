extends Spatial
onready var GameMode = get_node("/root").get_child(0)


export var MakeCurrent: bool
onready var Owner = get_parent()

var RayOrigin = Vector3()
var RayTarget = Vector3()

var RayCastCollitionPoint = Vector3()

var MonitorCenter = Vector2()
var MousePosition = Vector2()
var MouseOffset = Vector2()

var CameraMoveMultiplyer = 0
var CameraMoveMultiplyerDefault = 0.02
var CameraMoveMultiplyerRightClick = 0.08
var CameraMoveMultiplyerZoom = 0.1

var CustomAimHeight:int = 0

var RayLayer = null
var CursorState = null

onready var GetOwner = get_parent()
onready var CameraSetup = get_node(".")
onready var CameraRoot = get_node("CameraRoot")
onready var CameraParent = get_node("CameraRoot/CameraParent")
onready var MainCamera = get_node("CameraRoot/CameraParent/Camera")

onready var TempCursor = get_node("GUI/TempCursor")

onready var CloseButton = get_node("GUI/CloseButton")
onready var RestartButton = get_node("GUI/RestartButton")

var ZoomHorizontalOffset = 0.5
var ZoomVerticalOffset = 0.5
var ZoomUpOffset = 0

var MouseSpeed = Vector2()

var testevent = null
var VerticalLerpWeight = 0
var Intersection

# REWORK CAMERA ROTATION VARIABLES
var MouseMotionX = 0
var MouseMotionY = 0
var RememberMousePositionOnce = {
	"coord": Vector2(),
	"isset": false
}



# Called when the node enters the scene tree for the first time.
func _ready():
	MainCamera.current = MakeCurrent
	TempCursor.hide()

	#Connect
	RestartButton.connect("button_up", self, "RestartGame")
	CloseButton.connect("button_up", self, "ExitGame")
	CameraMoveMultiplyer = CameraMoveMultiplyerDefault
	
	set_as_toplevel(true)
	pass # _ready() END

func _physics_process(delta):
	if(MainCamera.is_current() == true):
		FollowParent() # Follow player/vehicle CameraSetup is attached to...
		SetCameraParentOffset() # Set camera offset based on player/vehicle...
		##############################################
		
		MonitorCenter = get_viewport().get_size() / 2
		MousePosition = get_viewport().get_mouse_position()
		MouseOffset = MousePosition - MonitorCenter
		
		RayOrigin = MainCamera.project_ray_origin(MousePosition)
		RayTarget = RayOrigin + MainCamera.project_ray_normal(MousePosition) * 2000

		var space_state = get_world().direct_space_state
		if(RayLayer != null):
			Intersection  = space_state.intersect_ray(RayOrigin, RayTarget, [], RayLayer, true, true)
		else:
			Intersection  = space_state.intersect_ray(RayOrigin, RayTarget, [], 8, true, true)

		if (Intersection.has("position")):
			RayCastCollitionPoint = Intersection.position
		
	#	print(CameraRoot.transform.origin.x)
		
		if Input.is_action_pressed("RightMouseButton"):
			if(Owner.MyType() == "PLAYER"):
				RightClickPlayerVehicle(delta)
			elif(Owner.MyType() == "CRANE"):
				pass
		else:
			ZoomHorizontalOffset = 0.5
			ZoomVerticalOffset = 0.5
			ZoomUpOffset = 0
			VerticalLerpWeight = 0


		# REWORK TO AVOID CAMERA LOCATION JITTER
		if Input.is_action_pressed("MiddleMouseButton"):
#			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			if(abs(MouseMotionX) > 1):
				rotate_y(deg2rad(MouseMotionX) * 8 * delta)
				
			if(RememberMousePositionOnce.isset == false):
				RememberMousePositionOnce.coord = MousePosition
				RememberMousePositionOnce.isset = true
		else:
#			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			if(RememberMousePositionOnce.isset == true):
				get_viewport().warp_mouse(RememberMousePositionOnce.coord)
				RememberMousePositionOnce.isset = false
			else:
				if !Input.is_action_pressed("RightMouseButton"):
					var HorizontalOffset = MouseOffset.x * CameraMoveMultiplyer
					var VerticalOffset = MouseOffset.y * CameraMoveMultiplyer
					CameraRoot.transform.origin = Vector3(HorizontalOffset, 0 , VerticalOffset)
	
	
func _input(event):
	if event is InputEventMouseMotion:
		MouseMotionX = -event.relative.x
		MouseMotionY = -event.relative.y
		MouseSpeed = event.speed
		
func RightClickPlayerVehicle(delta):
	var divider = 50
			
	if(abs(-MouseMotionX) > 1):
		ZoomHorizontalOffset += (-MouseMotionX * delta) / divider
		ZoomHorizontalOffset = clamp(ZoomHorizontalOffset, 0, 1)
		CameraRoot.transform.origin.x = lerp(-GetOwner.GetCameraZoomOffset().horizontal, GetOwner.GetCameraZoomOffset().horizontal, ZoomHorizontalOffset)

		ZoomVerticalOffset += (-MouseMotionY * delta) / divider
		ZoomVerticalOffset = clamp(ZoomVerticalOffset, 0, 1)
		CameraRoot.transform.origin.z = lerp(-GetOwner.GetCameraZoomOffset().horizontal, GetOwner.GetCameraZoomOffset().horizontal, ZoomVerticalOffset)


	var distanceCameraRoottoPlayer = ReturnRayCastCollitionPoint().distance_to(Owner.global_transform.origin)
	var cameraRootWeight = clamp(distanceCameraRoottoPlayer, 0 , GetOwner.GetCameraZoomOffset().horizontal) / GetOwner.GetCameraZoomOffset().horizontal
	
	
#	print(RayCastCollitionPoint)
#	print(GetOwner.GetCameraZoomOffset().horizontal)
#	print(distanceCameraRoottoPlayer)
#	print(cameraRootWeight)

	# Camera Vertical Distance	
	CameraParent.transform.origin.y = lerp(GetOwner.GetCameraOffset().vertical, GetOwner.GetCameraZoomOffset().vertical, cameraRootWeight)
		


func SetAimingCursorON(cursorstate, screenlocation):
#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	CursorState = cursorstate
	
	TempCursor.show()
	var ScreenPosition = MainCamera.unproject_position(screenlocation)
	TempCursor.set_position(ScreenPosition)


func SetAimingCursorOFF():
	CursorState = null
	TempCursor.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass

func SetCameraParentOffset():
	CameraParent.translation.y = get_parent().CameraOffset.vertical
	CameraParent.translation.z = get_parent().CameraOffset.horizontal
	pass

func FollowParent():
	global_transform.origin = get_parent().global_transform.origin # Global Position
	pass


func ReturnRayCastCollitionPoint():
	if CursorState == "Aiming":
		return Vector3(RayCastCollitionPoint.x, RayCastCollitionPoint.y + 3, RayCastCollitionPoint.z)
	elif CursorState == "ModifiedAiming":
		return RayCastCollitionPoint
	elif CursorState == "CustomAiming":
		return Vector3(RayCastCollitionPoint.x, RayCastCollitionPoint.y + CustomAimHeight, RayCastCollitionPoint.z)
	else:
		return RayCastCollitionPoint

func CustomRayLayer(raylayer):
	RayLayer = raylayer

func SetCustomAimHeightCollitionPoint(customaimheight):
#	print(customaimheight)
	CustomAimHeight = customaimheight
	
func ReturnCursorState():
	return CursorState

func ReturnMainCamera():
	return MainCamera
	
func ReturnIntersection():
	return Intersection

func RestartGame():
	get_tree().reload_current_scene()
	
func ExitGame():
	get_tree().quit()
