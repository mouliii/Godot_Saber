extends Node3D

# https://bsmg.wiki/mapping/map-format/info.html#summary
# https://bsmg.wiki/mapping/map-format/beatmap.html

# https://bsmg.wiki/mapping/map-format/lightshow.html#basic-events

@export_dir var songsDir
@onready var usbComm:USBComm = $USBComm
@onready var kinect:KinectWrapper = $KinectWrapper
@onready var blockHandler := $BlockHandler
@onready var player := $Player
#region song
var chosenSong:String
var chosenDifficulty:String
var song:SongData
var parser:SongParser
var quatConverter:QuatConersions
#endregion
#region controllers
var isKinectConnected := false
var isLeftHandConnected := false
var isRightHandConnected := false
#endregion
#region game_states
enum GAME_STATE {MENU, GAME}
var gameState = GAME_STATE.MENU
var masterTimeElapsed:float
#endregion

func _ready() -> void:
	if usbComm.OpenPort():
		print("Serial open!")
	GlobalSignals.SONG_SELECTED.connect(SetSelectedSong)
	GlobalSignals.DIFFICULTY_SELECTED.connect(SetSongDifficulty)
	GlobalSignals.START_GAME.connect(StartGame)
	$AudioStreamPlayer.finished.connect(OnSongEnd)
	song = SongData.new()
	parser = SongParser.new()
	quatConverter = QuatConersions.new()
	masterTimeElapsed = GlobalData.startElapsedTimeOffs
	PopulateSongsList()
	# TODO mappi 
	get_node("map/Enclosure").get_active_material(0).emission_texture = load("res://models/textures/enclosure_emission.png")
	$KinectConnect.start(1.0)

func _input(event: InputEvent) -> void:
	if gameState == GAME_STATE.GAME:
		if event is InputEventKey and event.is_pressed():
			if event.keycode == KEY_ESCAPE and not event.echo:
				OnSongEnd()

func _exit_tree() -> void:
	pass

func _process(delta: float) -> void:
	if gameState == GAME_STATE.GAME:
		# error check - kinect -> pause
		masterTimeElapsed += delta
	elif gameState == GAME_STATE.MENU:
		pass
	usbComm.ReadSerial()
	var quatfloat:Vector4
	var quatFixed := Vector4(usbComm.data[0],usbComm.data[1],usbComm.data[2],usbComm.data[3])
	quatfloat = quatConverter.GetQuatF(quatFixed)
	#print(quatfloat.length())
	#var euler = quatConverter.GetEuler(quatfloat)
	if quatfloat != Vector4.ZERO:
	#print(quatfloat.length())
		var q := Quaternion(quatfloat.x, quatfloat.y, quatfloat.z, quatfloat.w)
		var b := Basis(q)
		$Node/Box.basis = b
		#print(quatfloat)
	#print(rad_to_deg(euler.x), "\t", rad_to_deg(euler.y), "\t", rad_to_deg(euler.z))
	#print(quatFixed)
	$map/Rinkula.rotation.z += 0.15 * delta
	if kinect.IsOnline():
		var imgTex:ImageTexture = kinect.GetDepthFrame()
		#print(imgTex.get_image().get_data())
		$CanvasLayer/Sprite2D.material.set_shader_parameter("tex",imgTex)

func PopulateSongsList()->void:
	var songsInst = load("res://src/ui/song_menu_item.tscn")
	var dirAccess = DirAccess.open(songsDir)
	var folderName:String
	if dirAccess:
		dirAccess.list_dir_begin()
		folderName = dirAccess.get_next()
		while folderName != "":
			var beatmapPath:String = songsDir + "/" + folderName
			parser.GetMetaData(song, beatmapPath)
			var newSong = songsInst.instantiate()
			var bandName:String = song.songAuthorName
			var bandSong:String = song.songName
			var tex:Texture = load(beatmapPath + "/" + song.coverImageFilename)
			newSong.Setup(bandName, bandSong, tex, beatmapPath)
			%AllSongs.add_child(newSong)
			folderName = dirAccess.get_next()
	else:
		print(DirAccess.get_open_error())

func SetSelectedSong(path:String)->void:
	parser.GetMetaData(song, path)
	chosenSong = path
	%SelectedSongCover.texture = load(path + "/" + song.coverImageFilename)
	%DifficultySelector.clear()
	#for i in song.difficulties:
	for i in song.beatmapFiles.keys():
		%DifficultySelector.add_item(i)
	GlobalSignals.DIFFICULTY_SELECTED.emit(%DifficultySelector.get_item_text(0))
	StartPlayingAudio(path)

func SetSongDifficulty(diff:String)->void:
	chosenDifficulty = diff

func StartGame()->void:
	$CanvasLayer/SongMenu.hide()
	$AudioStreamPlayer.stop()
	parser.GetNoteData(song, blockHandler.notes, chosenSong, chosenDifficulty)
	var startOffset:float = blockHandler.CalcSongStartOffest(song)
	StartPlayingAudio(chosenSong, startOffset)
	#var time_delay = (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) / 1000000.0
	#await get_tree().create_timer(time_delay).timeout
	blockHandler.Start()
	gameState = GAME_STATE.GAME
	player.state = player.STATE.PLAYING
	var kinectMouse := $Kinect_Mouse
	kinectMouse.state = kinectMouse.STATE.NOT_IN_USE
	$CamController.gameStarted = true
	kinectMouse.HideMouseCircle()

# delay not in use
func StartPlayingAudio(path:String, _delay:float = 0.0)->void:
	var audio := AudioStreamOggVorbis.load_from_file(path + "/" + song.songFilename)
	$AudioStreamPlayer.stream = audio
	#await get_tree().create_timer(delay).timeout
	$AudioStreamPlayer.play()

func _on_kinect_connect_timeout() -> void:
	if kinect.InitKinect():
		print("kinect online")
		GlobalSignals.KINECT_ONLINE.emit(kinect)
	else:
		$KinectConnect.start(1.0)

func OnSongEnd()->void:
	gameState = GAME_STATE.MENU
	player.state = player.STATE.NO_CONTROL
	var kinectMouse := $Kinect_Mouse
	kinectMouse.state = kinectMouse.STATE.IDLE
	$CamController.gameStarted = false
	masterTimeElapsed = GlobalData.startElapsedTimeOffs
	kinectMouse.ShowMouseCircle()
	$CanvasLayer/SongMenu.show()
	$AudioStreamPlayer.stop() # for in game [esc] stop game
