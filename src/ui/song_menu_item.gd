extends Panel

var path:String

func _ready() -> void:
	$Button.pressed.connect(Clicked)

func Setup(band:String, song:String, texture:Texture, songPath:String)->void:
	$Song0/VBoxContainer/Band.text = band
	$Song0/VBoxContainer/Song.text = song
	$Song0/TextureRect.texture = texture
	path = songPath

func Clicked()->void:
	GlobalSignals.SONG_SELECTED.emit(path)
