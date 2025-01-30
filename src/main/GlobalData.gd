extends Node

var blockSize:float = 0.707
var reactionTime:float = 1.0
var startElapsedTimeOffs := 0.2 # hienosäätö, jää muuten vähän lyheksi origosta

var playerOffsetFromCenter:float = 1.5 #meter
var offsetPos := Vector3(0,0,playerOffsetFromCenter) 
var offsetRot:float # y-euler
var playerHeightOffset := 1.0
