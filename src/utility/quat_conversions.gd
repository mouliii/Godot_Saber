class_name QuatConersions
extends Resource


func GetQuatF(quatfixed:Vector4i) -> Vector4:
	var qp:float = 1 << 14;
	var val:float = 1.0 / qp; # 1 / 2^14   Q2.14
	var vec4:Vector4
	vec4.z = quatfixed.x * val
	vec4.x = quatfixed.y * val
	vec4.y = quatfixed.z * val
	vec4.w = quatfixed.w * val

	var l:float = vec4.length()
	if abs(l - 1.0) > 0.0015:
		vec4 = Vector4.ZERO
	return vec4

func GetEuler(quat:Vector4)->Vector3:
	var q := Quaternion(quat.x, quat.y, quat.z, quat.w)
	q = q.normalized()
	return q.get_euler()
