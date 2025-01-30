extends Node

@onready var blockNode := $"../Blocks"
var col_note_dir = preload("res://models/color_note_dir.tscn")
var col_note_circ = preload("res://models/color_note_circ.tscn")
var bomb_note = preload("res://models/test_box_bomb.tscn")

var noteSpawnList:Array[Resource]
var notes:Array[Resource]
var beatmapIndex:int = 0
# spawn const
var secondsPerBeat:float
# spawnTime = beat * secondsPerBeat - tSpawnToHit
var spawnFlag:bool = false
var nextSpawnTime:float = 0.0

var song:SongData

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if spawnFlag:
		if owner.masterTimeElapsed > nextSpawnTime:
			SpawnNotes()
			ReadNextNotes()

	var allNotes = get_tree().get_nodes_in_group("notes")
	for n in allNotes:
		n.translate(Vector3(0,0,-song.noteMoveSpeed * delta))

func CalcSongStartOffest(_song:SongData)->float:
	self.song = _song
	secondsPerBeat = 60.0 / song.beatsPerMinute
	var firstNoteTime:float = notes[0].beat * secondsPerBeat
	var offset:float = firstNoteTime - GlobalData.reactionTime
	return minf(offset, 0.0)

func Start()->void:
	# note spawn dist, speed ....
	#song.noteReactionTime = song.noteSpawnDist / song.noteMoveSpeed
	song.noteSpawnDist = song.noteMoveSpeed * GlobalData.reactionTime
	ReadNextNotes()

func Stop()->void:
	pass
	# clear?

func ReadNextNotes()->void:
	if beatmapIndex < song.nAllNotes:
		nextSpawnTime = notes[beatmapIndex].beat * secondsPerBeat - GlobalData.reactionTime
		noteSpawnList.append(notes[beatmapIndex])
		var curBeat := float(notes[beatmapIndex].beat)
		spawnFlag = true
		beatmapIndex += 1
		while beatmapIndex < song.nAllNotes:
			var nextBeat := float(notes[beatmapIndex].beat)
			if is_equal_approx(curBeat, nextBeat):
				noteSpawnList.append(notes[beatmapIndex])
				beatmapIndex += 1
			else:
				break

func SpawnNotes()->void:
	for note in noteSpawnList:
		if note is ColorNoteData:
			if note.cutDir != 8:
				var col_inst = col_note_dir.instantiate()
				col_inst.Setup(note)
				blockNode.add_child(col_inst)
				col_inst.scale = Vector3(GlobalData.blockSize,GlobalData.blockSize,GlobalData.blockSize)
				col_inst.global_position.z = -song.noteSpawnDist
				col_inst.global_position.x = note.xCoord - 2 + (GlobalData.blockSize / 2.0)
				col_inst.global_position.y = note.yCoord + (GlobalData.blockSize / 2.0)
				col_inst.add_to_group("notes")
			else:
				var col_inst = col_note_circ.instantiate()
				col_inst.Setup(note)
				blockNode.add_child(col_inst)
				col_inst.scale = Vector3(GlobalData.blockSize,GlobalData.blockSize,GlobalData.blockSize)
				col_inst.global_position.z = -song.noteSpawnDist
				col_inst.global_position.x = note.xCoord - 2 + (GlobalData.blockSize / 2.0)
				col_inst.global_position.y = note.yCoord + (GlobalData.blockSize / 2.0)
				col_inst.add_to_group("notes")

		elif note is BombNoteData:
			var bomb = bomb_note.instantiate()
			blockNode.add_child(bomb)
			bomb.scale = Vector3(GlobalData.blockSize,GlobalData.blockSize,GlobalData.blockSize)
			bomb.global_position.z = -song.noteSpawnDist
			bomb.global_position.x = note.xCoord - 2 + (GlobalData.blockSize / 2.0)
			bomb.global_position.y = note.yCoord + (GlobalData.blockSize / 2.0)
			bomb.add_to_group("notes")
			
	noteSpawnList.clear()
	spawnFlag = false
