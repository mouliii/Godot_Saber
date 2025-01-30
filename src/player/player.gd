extends Node3D

@onready var blocks := $Blocks
@onready var lSword := $LHelp/SwordLeft
@onready var rSword := $RHelp/SwordRight

var kinect:KinectWrapper = null
const rootBone := 0
const headBone := 3
const centerShoulderBone := 3
const leftHandBone := 6#7
const rightHandBone := 10#11
# ETEENPÄIN OM -180 astetta eli -3.14 rad

enum STATE {NO_CONTROL, PLAYING}
var state := STATE.NO_CONTROL

func _ready() -> void:
	GlobalSignals.NEW_CALIB_VALUES.connect(GetNewCalibData)
	GlobalSignals.KINECT_ONLINE.connect(GetKinectDevice)
	#position.y += 1.0
	#rotation.y -= 1.2 + PI / 2.0
	var bb := $BaseBlock
	for i in range(20):
		var block = bb.duplicate()
		blocks.add_child(block)
	bb.queue_free()
	lSword.Setup(true)
	rSword.Setup(false)
	#$LHelp.reparent($Blocks.get_child(leftHandBone))
	#$RHelp.reparent($Blocks.get_child(rightHandBone))
	$Head.global_position = Vector3.ZERO
	$Head.reparent($Blocks.get_child(headBone))


func _process(_delta: float) -> void:
	if !kinect:
		return
	if kinect.GetSkeletonFrame():
		if kinect.GetXforms().size() > 0:
			for i in range(0,20):
				var block:MeshInstance3D = blocks.get_child(i)
				var xform:Transform3D = kinect.GetXforms()[i]
				xform.origin -= GlobalData.offsetPos
				xform.origin.y += GlobalData.playerHeightOffset
				xform = xform.rotated_local(Vector3.UP, GlobalData.offsetRot)
				#block.global_position.z += GlobalData.playerOffsetFromCenter
				block.transform = xform
			# update head marker
			#print(blocks.get_child(0).global_position)
			#$Head.transform = kinect.GetXforms()[headBone]
			var elbow_wrist_interpolation := 0.35 # from elbow to wrist
			var lelbowXform:Transform3D = blocks.get_child(leftHandBone).transform
			var lwristXform:Transform3D = blocks.get_child(leftHandBone+1).transform
			$LHelp.transform = lelbowXform.interpolate_with(lwristXform, elbow_wrist_interpolation)
			var relbowXform:Transform3D = blocks.get_child(rightHandBone).transform
			var rwristXform:Transform3D = blocks.get_child(rightHandBone+1).transform
			$RHelp.transform = relbowXform.interpolate_with(rwristXform, elbow_wrist_interpolation)
		

func GetNewCalibData(_pos:Vector3, rot:float)->void:
	rotation.y = -rot
#	rotation.y = PI - rot
	#print(rotation.y," ", rot)
	#global_position.z = GlobalData.playerOffsetFromCenter

func GetKinectDevice(kinect_:KinectWrapper)->void:
	kinect = kinect_
