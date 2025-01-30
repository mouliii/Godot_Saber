extends Node3D

@onready var cube1 := $OLKA
@onready var cube2 := $OLKA/MeshInstance3D/KYYNAR
@onready var usb := $USBComm
var quatConverter:QuatConersions

func _ready() -> void:
	quatConverter = QuatConersions.new()
	if usb.OpenPort():
		print("Serial open!")
	else:
		print("usb fubar")


func _process(delta: float) -> void:
	if usb.ReadSerial():
		var quatfloat:Vector4
		# BOX 1
		var quatFixed := Vector4(usb.data[0],usb.data[1],usb.data[2],usb.data[3])
		quatfloat = quatConverter.GetQuatF(quatFixed)
		if quatfloat != Vector4.ZERO:
			var q := Quaternion(quatfloat.x, quatfloat.y, quatfloat.z, quatfloat.w)
			var b := Basis(q)
			b = b.rotated(Vector3.UP, PI)
			cube1.basis = b
		# BOX 2
		quatFixed = Vector4(usb.data[5],usb.data[6],usb.data[7],usb.data[8])
		quatfloat = quatConverter.GetQuatF(quatFixed)
		if quatfloat != Vector4.ZERO:
			var q := Quaternion(quatfloat.x, quatfloat.y, quatfloat.z, quatfloat.w)
			var b := Basis(q)
			cube2.basis = b
