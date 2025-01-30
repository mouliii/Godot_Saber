extends Control


func _ready() -> void:
	GlobalSignals.KINECT_ONLINE.connect(KinectOnline)

func _process(_delta: float) -> void:
	pass

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func KinectOnline(_kinect:KinectWrapper)->void:
	$ControllerStatus/Kinect/Label2.text = "Connected"
