extends Control


export(NodePath) var CameraSetupNodePath
onready var CameraSetup = get_node(CameraSetupNodePath)

onready var Owner = CameraSetup.get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _draw():
	# DRAW CIRCLE ON MOUSE LOCATION
#	draw_circle (CameraSetup.ReturnMainCamera().unproject_position(CameraSetup.ReturnRayCastCollitionPoint()), 3.0, Color.orange)

	if (Owner.MyType() == "PLAYER"):

		# Crosshair Height Draw Line
		var CrosshairHeightFromPoint = CameraSetup.ReturnMainCamera().unproject_position(CameraSetup.ReturnRayCastCollitionPoint())
		var CrosshairHeightToPoint = CameraSetup.ReturnMainCamera().unproject_position(Vector3(CameraSetup.ReturnRayCastCollitionPoint().x, 0, CameraSetup.ReturnRayCastCollitionPoint().z))
		
		# Barrel Starting Point Draw Line
		var BarrelFromPoint = CameraSetup.ReturnMainCamera().unproject_position(Owner.BarrelOpening.global_transform.origin)
		var BarrelToPoint = CameraSetup.ReturnMainCamera().unproject_position(CameraSetup.ReturnRayCastCollitionPoint())
		

		if CameraSetup.ReturnCursorState() != null:
			# Crosshair Height Draw Line
			draw_line(CrosshairHeightFromPoint, CrosshairHeightToPoint, Color.yellow, 1.0, true)
			
			# Barrel Starting Point Draw Line
			draw_line(BarrelFromPoint, BarrelToPoint, Color.white, 1.0, true)
		
		
		

func _process(_delta):
	update()
