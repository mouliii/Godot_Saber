extends Node3D

# Good for gesture recognition.
# {0.5f, 0.5f, 0.5f, 0.05f, 0.04f};

# Good for a menu system that needs to be smooth but
# doesn't need the reduced latency as much as gesture recognition does.
# {0.5f, 0.1f, 0.5f, 0.1f, 0.1f};

# käsi vyötärön yläpuolella, eli > 0.0
# käsi offset map() -0.5, 0.5 | reso
# jos nopeus alle X, (joku indikaattori) timer 1s

@export var kinect: KinectWrapper

const leftHandBone := 6#7
const rightHandBone := 10#11
const clickThreshold := 60

enum STATE {NOT_IN_USE, IDLE, MOVE, SELECT}
var state = STATE.MOVE
var selectedBtn :Button = null

func _ready() -> void:
	GlobalSignals.BUTTON_SELECTED.connect(MouseEnteredBtn)
	GlobalSignals.BUTTON_DESELECTED.connect(MouseExitBtn)

func _process(_delta: float) -> void:
	if state == STATE.NOT_IN_USE:
		return
	if kinect.IsOnline():
		if kinect.GetSkeletonFrame():
			var xforms:Array = kinect.GetXforms()
			if kinect.GetXforms().size() > 0:
				var mouseVel := Input.get_last_mouse_velocity().length()
				match state:
					STATE.IDLE: # käsi alle vyötärön
						if xforms[leftHandBone].origin.y > 0.0:
							state = STATE.MOVE
						
					STATE.MOVE: # käsi yli vyötärön, liikuttaa hiirtä
						if selectedBtn:
							if mouseVel < clickThreshold:
								state = STATE.SELECT
								$Timer.start(1.0)
						var xPos := remap(xforms[leftHandBone].origin.x, -0.5, 0.5, 0, 1980)
						var yPos := remap(xforms[leftHandBone].origin.y, 0.5, 0.0, 0, 1080)
						var vec2Pos := Vector2(xPos, yPos)
						Input.warp_mouse(vec2Pos)
						$CanvasLayer/TextureProgressBar.position = \
						get_viewport().get_mouse_position() + Vector2(-32,-32) * $CanvasLayer/TextureProgressBar.scale
						if xforms[leftHandBone].origin.z < 0.0:
							state = STATE.IDLE
						
					STATE.SELECT: # käsi napin päällä ja alle ~50 mouse vel
						if $Timer.is_stopped():
							VirtualLeftClick()
							state = STATE.MOVE
						
						$CanvasLayer/TextureProgressBar.value = (1.0 - $Timer.time_left) * 100
						
						var xPos := remap(xforms[leftHandBone].origin.x, -0.5, 0.5, 0, 1980)
						var yPos := remap(xforms[leftHandBone].origin.y, 0.5, 0.0, 0, 1080)
						var vec2Pos := Vector2(xPos, yPos)
						Input.warp_mouse(vec2Pos)
						if mouseVel > clickThreshold:
							state = STATE.MOVE
							$CanvasLayer/TextureProgressBar.value = 0


func ButtonSignal(str_:String)->void:
	$CanvasLayer/Label.text = str_

func MouseEnteredBtn(btn:Button)->void:
	selectedBtn = btn

func MouseExitBtn()->void:
	selectedBtn = null

func VirtualLeftClick():
	var mousePos := get_viewport().get_mouse_position()
	var press = InputEventMouseButton.new()
	press.set_button_index(MOUSE_BUTTON_LEFT)
	press.set_position(mousePos)
	press.set_pressed(true)
	Input.parse_input_event(press)
	var release = InputEventMouseButton.new()
	release.set_button_index(MOUSE_BUTTON_LEFT)
	release.set_position(mousePos)
	release.set_pressed(false)
	Input.parse_input_event(release)

func HideMouseCircle()->void:
	$CanvasLayer/TextureProgressBar.hide()

func ShowMouseCircle()->void:
	$CanvasLayer/TextureProgressBar.show()
