class_name SongParser
extends Resource


var songData:SongData
var blockData:Array[Resource]
var infoJson:Dictionary

enum SONG_VERSION {VER2 = 0, VER3 = 1, VER4 = 2, ERROR = -1}

func GetMetaData(song:SongData, path:String)->bool:
	song.beatmapFiles = {} # clear
	ParseInfoDat(path)
	var version := GetVersion(infoJson)
	if version == SONG_VERSION.VER2:
		ParseMetaDataV2(song)
		return true
	# metadata ei ver3 ?
	elif version == SONG_VERSION.VER4:
		ParseMetaDataV4()
		return true
	return false

func ParseInfoDat(path:String)->bool:
	var infoPath:String
	if FileAccess.file_exists(path + "/Info.dat"):
		infoPath = path + "/Info.dat"
	elif FileAccess.file_exists(path + "/info.dat"):
		infoPath = path + "/info.dat"
	else:
		print("info.dat file not exsist!")
		return false
	var json = JSON.new()
	var jsonStr := FileAccess.get_file_as_string(infoPath)
	var status = json.parse(jsonStr)
	if status != OK:
		print("failed to open Info.dat")
		var line := json.get_error_line()
		var msg := json.get_error_message()
		print("line: ",line," error msg: ", msg)
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		print("Info.dat is not dictionary")
		return false
	infoJson = json.data.duplicate()
	return true

func ParseMetaDataV2(song:SongData)->void:
	song.version = infoJson["_version"]
	song.songName = infoJson["_songName"]
	song.songSubName = infoJson["_songSubName"]
	song.songAuthorName = infoJson["_songAuthorName"]
	song.levelAuthorName = infoJson["_levelAuthorName"]
	song.beatsPerMinute = infoJson["_beatsPerMinute"]
	song.songFilename = infoJson["_songFilename"]
	song.coverImageFilename = infoJson["_coverImageFilename"]

	var beatmapSets = infoJson["_difficultyBeatmapSets"]
	for i in beatmapSets:
		song.beatmapCharacteristicName = i["_beatmapCharacteristicName"]
		var diffs = i["_difficultyBeatmaps"]
		for j in diffs:
			if j.has("_difficulty"):
				var dict:Dictionary = \
				{
						"beatmapFile" : j["_beatmapFilename"],
						"noteVelocity" : j["_noteJumpMovementSpeed"]
				}
				song.beatmapFiles[j["_difficulty"]] = dict
				#song.difficulties.append(j["_difficulty"])
		break

func ParseMetaDataV4()->void:
	pass



func GetNoteData(song:SongData, blocks:Array[Resource], path:String, difficulty:String)->bool:
	blocks.clear() # resizes to 0
#region difficlty_file_check
	var diffPath:String = path + "/" + song.beatmapFiles[difficulty]["beatmapFile"]
	var json = JSON.new()
	var jsonStr := FileAccess.get_file_as_string(diffPath)
	var status = json.parse(jsonStr)
	if status != OK:
		print("failed to open diff.dat")
		var line := json.get_error_line()
		var msg := json.get_error_message()
		print("line: ",line," error msg: ", msg)
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		print("diff.dat is not dictionary")
		return false
#endregion
	var version := GetVersion(json.data)
	if version == SONG_VERSION.VER2:
		ParseNoteV2(song, blocks, json.data, difficulty)
		return true
	elif version == SONG_VERSION.VER3:
		ParseNoteV3(song, blocks, json.data, difficulty)
		return true
	elif version == SONG_VERSION.VER4:
		ParseNoteV4()
		return true
	return false

func ParseNoteV2(song:SongData, blocks:Array[Resource], diffiDict:Dictionary, difficulty:String):
	song.noteMoveSpeed = song.beatmapFiles[difficulty]["noteVelocity"]
	song.beatmapFileName = song.beatmapFiles[difficulty]["beatmapFile"]
	var nHittableNotes := 0
	var nAllNotes := 0
	for note in diffiDict["_notes"]:
		var typeInt = int(note["_type"]) # type is float for some resaon? [_type: 0]
		match typeInt:
			0:
				var redNote = ColorNoteData.new()
				redNote.cutDir = note["_cutDirection"]
				redNote.xCoord = note["_lineIndex"]
				redNote.yCoord = note["_lineLayer"]
				redNote.beat = note["_time"]
				redNote.color = 0
				blocks.append(redNote)
				#blocks[nAllNotes] = redNote
				nHittableNotes += 1
				nAllNotes += 1
			1:
				var blueNote = ColorNoteData.new()
				blueNote.cutDir = note["_cutDirection"]
				blueNote.xCoord = note["_lineIndex"]
				blueNote.yCoord = note["_lineLayer"]
				blueNote.beat = note["_time"]
				blueNote.color = 1
				blocks.append(blueNote)
				#blocks[nAllNotes] = blueNote
				nHittableNotes += 1
				nAllNotes += 1
			3:
				var bombNote = BombNoteData.new()
				bombNote.beat = note["_time"]
				bombNote.xCoord = note["_lineIndex"]
				bombNote.yCoord = note["_lineLayer"]
				blocks.append(bombNote)
				#blocks[nAllNotes] = bombNote
				nAllNotes += 1
			_:
				print("invalid note type ver2")
	song.numHittableNotes = nHittableNotes
	song.nAllNotes = nAllNotes

	#obstacles (walls)
	for obs in diffiDict["_obstacles"]:
		pass
	
	# test
	for event in diffiDict["_events"]:
		if event["_type"] == 14:
			print(event["_value"])
		if event["_type"] == 15:
			print(event["_value"])
	
	return true

func ParseNoteV3(song:SongData, blocks:Array[Resource], diffiDict:Dictionary, difficulty:String):
	song.noteMoveSpeed = song.beatmapFiles[difficulty]["noteVelocity"]
	song.beatmapFileName = song.beatmapFiles[difficulty]["beatmapFile"]
	var nHittableNotes := 0
	var nAllNotes := 0
	for note in diffiDict["colorNotes"]:
		var col_note = ColorNoteData.new()
		col_note.cutDir = note["d"]
		col_note.xCoord = note["x"]
		col_note.yCoord = note["y"]
		col_note.color = note["c"]
		col_note.beat = note["b"]
		blocks.append(col_note)
		nHittableNotes += 1
		nAllNotes += 1
	song.numHittableNotes = nHittableNotes
	song.nAllNotes = nAllNotes
	
	for bomb in diffiDict["bombNotes"]:
		pass

	#obstacles (walls)
	for obs in diffiDict["obstacles"]:
		pass
	return true

func ParseNoteV4():
	pass



func GetVersion(file:Dictionary)->SONG_VERSION:
	if file.has("_version"):
		return SONG_VERSION.VER2
	#v3?
	elif file.has("version"):
		if file["version"].begins_with("3"):
			return SONG_VERSION.VER3
		return SONG_VERSION.VER4
	return SONG_VERSION.ERROR
	
