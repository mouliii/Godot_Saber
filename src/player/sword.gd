extends Area3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func Setup(leftHand:bool)->void:
	if leftHand:
		set_collision_layer_value(5, true)
		$sword/Cylinder.set_instance_shader_parameter("baseColor", Color.RED)
	else:
		set_collision_layer_value(6, true)
		$sword/Cylinder.set_instance_shader_parameter("baseColor", Color.BLUE)
