extends Area3D

# var colorData:ColorNoteData tarviiko?
# mesh.set_instance_shader_parameter("param", value)

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass

func Setup(colorNote:ColorNoteData)->void:
	var cubeRef := $color_note/Cube
	if colorNote.color == 0:
		cubeRef.set_instance_shader_parameter("albedo", Color.RED)
		set_collision_mask_value(5, true)
	else:
		cubeRef.set_instance_shader_parameter("albedo", Color.BLUE)
		set_collision_mask_value(6, true)

	match colorNote.cutDir:
		0:
			rotation.z = deg_to_rad(180)
		1:
			rotation.z = deg_to_rad(0)
		2:
			rotation.z = deg_to_rad(90)
		3:
			rotation.z = deg_to_rad(-90)
		4:
			rotation.z = deg_to_rad(135)
		5:
			rotation.z = deg_to_rad(-135)
		6:
			rotation.z = deg_to_rad(45)
		7:
			rotation.z = deg_to_rad(-45)
		8:
			pass # kuuluu mennä tänne
		_:
			print("color note cur dir fuq'd")

""" curDir
0	Up - hit from bottom to up
1	Down - hit from top to down
2	Left
3	Right
4	Up Left
5	Up Right
6	Down Left
7	Down Right
8	Any
"""
