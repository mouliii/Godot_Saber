extends Node3D

@export var mouseSens := 0.002
@export var vel := 1.0
@onready var pivot := $PivotPoint
@export var camTarget:Node3D
@export var DEBUG_MODE:bool = false
var gameStarted := false

func _unhandled_input(event: InputEvent) -> void:
	if !gameStarted or DEBUG_MODE:
		if event is InputEventMouseMotion:
			var relX = -event.relative.x * mouseSens
			var relY = -event.relative.y * mouseSens
			rotate_y(relX)
			pivot.rotate_x(relY)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !camTarget or DEBUG_MODE:
		var input := Input.get_vector("left","right","forward","backward")
		var direction = (pivot.transform.basis * Vector3(input.x, 0, input.y)).normalized()
		translate(direction * delta * vel)
	else:
		global_position = camTarget.global_position
