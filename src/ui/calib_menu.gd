extends Control


func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	$CalibCountDown.show()
	var label := $CalibCountDown/Label
	for i in range(5):
		label.text = str(5-i)
		await get_tree().create_timer(1.0).timeout
	var startTime := Time.get_ticks_msec()
	var success := false
	while true:
		var time := Time.get_ticks_msec()
		if (time - startTime) > 40: # kinect updates every 33ms, but just in case wait 40ms
			break
		if owner.kinect.GetSkeletonFrame():
			if owner.kinect.GetXforms().size() > 0: # TODO
				success = true
				var rootBone:Transform3D = owner.kinect.GetXforms()[0]
				# root bone is origo, need to add leg length v
				GlobalData.offsetPos = rootBone.origin# + Vector3(0,GlobalData.playerHeightOffset,0)
				$VBoxContainer/Distance/Label2.text = str(GlobalData.offsetPos)
				GlobalData.offsetRot = rootBone.basis.get_euler().y
				$VBoxContainer/Rotation/Label2.text = str(GlobalData.offsetRot)
				break
	if success:
		label.text = "OK"
	else:
		label.text = "FAILED"
	await get_tree().create_timer(1.0).timeout
	GlobalSignals.NEW_CALIB_VALUES.emit(GlobalData.offsetPos, GlobalData.offsetRot)
	$CalibCountDown.hide()
