extends Control


var RenderAimLines = false
var OwnerNode = null

export(NodePath) var Owner

# Called when the node enters the scene tree for the first time.
func _ready():
	OwnerNode = get_node(Owner)
	pass # Replace with function body.


func _draw():
	# START: DRAW PLANE HEIGHT LINE
	DrawLineToFloor(Owner, Color.yellow, 1.0, true)
	# END: DRAW PLANE HEIGHT LINE

func DrawCircle(position, radius, color, renderme):
	var DrawPosition = Unproject(position)
	if (renderme == true):
		draw_circle (DrawPosition, radius, color)

func DrawLine(from, fromusenode, to, tofromusenode,  color, width, renderme):
	# Crosshair Height Draw Line
	var CrosshairHeightFromPoint
	var CrosshairHeightToPoint
	
	if(fromusenode == true):
		CrosshairHeightFromPoint = Unproject(get_node(from).global_transform.origin)
	else:
		CrosshairHeightFromPoint = Unproject(from)
	
	
	if(tofromusenode == true):
		CrosshairHeightToPoint = Unproject(get_node(to).global_transform.origin)
	else: 
		CrosshairHeightToPoint = Unproject(to)

	if (renderme == true):
		draw_line(CrosshairHeightFromPoint, CrosshairHeightToPoint, color, width, true)
	pass
	
func DrawLineToFloor(from, color, width, renderme):
	
	# Crosshair Height Draw Line
	var CrosshairHeightFromPoint = Unproject(get_node(from).global_transform.origin)
	var CrosshairHeightToPoint = Unproject(Vector3(get_node(from).global_transform.origin.x, 0, get_node(from).global_transform.origin.z))
	
	if (renderme == true):
		if (get_node(from).global_transform.origin.y < 0):
			draw_line(CrosshairHeightFromPoint, CrosshairHeightToPoint, Color.red, width, true)
		else:
			draw_line(CrosshairHeightFromPoint, CrosshairHeightToPoint, color, width, true)
	pass


func Unproject(item):
	var CameraSetupNode = get_parent().get_node("CameraSetup")
	return CameraSetupNode.ReturnMainCamera().unproject_position(item)



func SetRenderAimLinesON():
	RenderAimLines = true
	
func SetRenderAimLinesOFF():
	RenderAimLines = false

func _process(_delta):
	update()
