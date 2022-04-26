extends KinematicBody

onready var GameRoot = get_node("/root").get_child(0)

export(NodePath) var PlayerSpawnNodePath
export(NodePath) var OrientationTargetNodePath
export(NodePath) var CraneAreaNodePath
export(NodePath) var CommandPanelNodePath
export(NodePath) var CameraSetupNodePath
export(NodePath) var CommandLabelNodePath
export(NodePath) var UpperCraneNodePath
export(NodePath) var GearRangeNodePath
export(NodePath) var HookGearNodePath
export(NodePath) var HookGearParentNodePath
export(NodePath) var HookGrappleAreaNodePath
export(NodePath) var HookGearRayCastNodePath
export(NodePath) var ReplicateDistanceNodePath

onready var CameraSetup = get_node(CameraSetupNodePath)
onready var CommandPanel = get_node(CommandPanelNodePath)
onready var CommandLabel = get_node(CommandLabelNodePath)
onready var CraneArea = get_node(CraneAreaNodePath)
onready var GearRange = get_node(GearRangeNodePath)
onready var HookGearParent = get_node(HookGearParentNodePath)
onready var HookGear = get_node(HookGearNodePath)
onready var HookGearRayCast = get_node(HookGearRayCastNodePath)
onready var HookGrappleArea = get_node(HookGrappleAreaNodePath)
onready var OrientationTarget = get_node(OrientationTargetNodePath)
onready var ReplicateDistance = get_node(ReplicateDistanceNodePath)
onready var PlayerSpawn = get_node(PlayerSpawnNodePath)
onready var UpperCrane = get_node(UpperCraneNodePath)

onready var Gear001 = get_node("Crane/UpperCraneParent/UpperCrane/Gear001")
onready var Gear002 = get_node("Crane/UpperCraneParent/UpperCrane/Gear002")



var AreaOwner = null
var AreaOwnerStoredLocation = Vector3()
var CameraOffset = {"horizontal": 20, "vertical": 60}
var CameraZoomOffset = {"horizontal": 50, "vertical": 50}
var CraneRotationSpeed = 15

var MoveHookGrapple = null
var ShippableObject = null

var ShippableRotationWeight = 0




# Called when the node enters the scene tree for the first time.
func _ready():
	CommandPanel.hide()
	
	CraneArea.connect("area_entered", self, "EnteredCraneArea")
	CraneArea.connect("area_exited", self, "ExitedCraneArea")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	CameraSetup.CustomRayLayer(32)
	
#	if(ShippableObject != null):
#		print(ShippableObject.ReturnFloorDetectorArea())
	
	
	if (CameraSetup.ReturnMainCamera().is_current()):
		if (Input.is_action_pressed("RightMouseButton")):
#			print(CameraSetup.ReturnIntersection().collider.name)

			if(CameraSetup.ReturnIntersection().collider.name == "LANDINGAREA" and ShippableObject != null):
				ShippableRotationWeight += delta * 0.5
				ShippableRotationWeight = clamp(ShippableRotationWeight, 0, 1)
				ShippableObject.MatchTargetRotation(CameraSetup.ReturnIntersection().collider.get_parent(), ShippableRotationWeight)
				pass
	
			# START: DIRTYCODE CRANE RANGE
			OrientationTarget.look_at(CameraSetup.ReturnRayCastCollitionPoint(), Vector3.UP)
			OrientationTarget.global_transform.origin.y = CameraSetup.ReturnRayCastCollitionPoint().y
			var distance = OrientationTarget.global_transform.origin.distance_to(CameraSetup.ReturnRayCastCollitionPoint())
			distance = clamp(distance, 13, 30)
			ReplicateDistance.transform.origin.z = distance			
			
			var distanceGearRangeReplicateDistance = ReturnGloblXZ(GearRange).distance_to(ReturnGloblXZ(ReplicateDistance))
			var distanceGearRangeHookGearParent = ReturnGloblXZ(GearRange).distance_to(ReturnGloblXZ(HookGearParent))
			
			if (distanceGearRangeReplicateDistance - distanceGearRangeHookGearParent) > 0:
				HookGearParent.transform.origin.z += 1 * delta
			elif (distanceGearRangeReplicateDistance - distanceGearRangeHookGearParent) < 0:
				HookGearParent.transform.origin.z -= 1 * delta
				
			HookGearParent.transform.origin.z = clamp(HookGearParent.transform.origin.z, 0, 3.5)
			# END: DIRTYCODE CRANE RANGE
			
			
			
			# START: DIRTYCODE CRANE ROTATION
			var RotDifference = UpperCrane.rotation_degrees.y - OrientationTarget.rotation_degrees.y
			
			if (RotDifference) > 0:
				if (abs(RotDifference) < 180):
					UpperCrane.rotation_degrees.y -= CraneRotationSpeed * delta
				else:
					UpperCrane.rotation_degrees.y += CraneRotationSpeed * delta
			elif (RotDifference) < 0:
				if (abs(RotDifference) < 180):
					UpperCrane.rotation_degrees.y += CraneRotationSpeed * delta
				else:
					UpperCrane.rotation_degrees.y -= CraneRotationSpeed * delta
			# END: DIRTYCODE CRANE ROTATION
		else:
			if ShippableObject != null:
					ShippableObject.SetRecordRotation()
			ShippableRotationWeight = 0

		if (Input.is_action_pressed("LeftMouseButton")):
			if(CameraSetup.ReturnIntersection().collider.name == "PICKUPAREA"):
				if (CameraSetup.ReturnIntersection().collider.get_parent().ReturnContainerState() == "packaged"):
					HookGrappleAreaNodePath = "down"
				else:
					print("Needs to be packaged...")
			elif(CameraSetup.ReturnIntersection().collider.name == "LANDINGAREA" and ShippableObject != null):
					HookGrappleAreaNodePath = "down"

		
		if (HookGrappleAreaNodePath == "down"):
			if(ShippableObject == null):
				if len(HookGrappleArea.get_overlapping_areas()) > 0:
					if (HookGrappleArea.get_overlapping_areas()[0].name == "PICKUPAREA"):
						HookGrappleAreaNodePath = "up"
						HookGrappleArea.transform.origin.y += .3
						ShippableObject = HookGrappleArea.get_overlapping_areas()[0].get_parent()
						var storeDistanceFromShippable = HookGrappleArea.global_transform.origin.distance_to(ShippableObject.global_transform.origin)
						
						ShippableObject.SetCrane({
							"beingcarried": true,
							"crane": HookGrappleArea, 
							"distance": storeDistanceFromShippable
						})
				else:
					HookGrappleArea.transform.origin.y -= 2 * delta
					
			elif len(ShippableObject.ReturnFloorDetectorArea()) > 0:
				if ShippableObject.ReturnFloorDetectorArea()[0].name == "LANDINGAREA":
					ShippableObject.ReturnFloorDetectorArea()[0].get_parent().SpawnInventory()
					HookGrappleAreaNodePath = "up"
					ShippableObject.queue_free()
					ShippableObject = null
			else:
				HookGrappleArea.transform.origin.y -= 2 * delta
					
		elif (HookGrappleAreaNodePath == "up"):
			HookGrappleArea.transform.origin.y += 2 * delta
			HookGrappleArea.transform.origin.y = clamp(HookGrappleArea.transform.origin.y, HookGrappleArea.transform.origin.y, 0)
			if (HookGrappleArea.global_transform.origin.y == 0):
				HookGrappleAreaNodePath = null
			

	if(CommandPanel.visible) and Input.is_action_just_released("RideVehicle"):
		CameraSetup.ReturnMainCamera().make_current()
		CommandPanel.hide()
		AreaOwner.End()
	elif (CameraSetup.ReturnMainCamera().is_current() and Input.is_action_just_released("RideVehicle")):
		CommandPanel.show()
		GameRoot.SpawnPlayer(PlayerSpawn.global_transform.origin)

func EnteredCraneArea(area):
	if(area.name == "PLAYER"):
		AreaOwner = area.get_parent()
		CommandPanel.show()
		CommandLabel.text = "Press Q to Enter Crane"
		pass
	
func ExitedCraneArea(area):
	if(area.name == "PLAYER"):
		AreaOwner = null
		CommandPanel.hide()
		pass


func ReturnGloblXZ(object: Spatial):
	return Vector3(object.global_transform.origin.x, 0, object.global_transform.origin.z)



func MyType():
	return "CRANE"
