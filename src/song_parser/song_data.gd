class_name SongData
extends Resource

#region notes
# https://bsmg.wiki/mapping/map-format/info.html#summary
# https://bsmg.wiki/mapping/map-format/beatmap.html

# "header"
# song .ogg / .egg
# cover.png / jpg
# info file metadata - Info.dat
# colorscheme - default blue/red
# difficulty files

# jump dur = from spawn to hit in ms/beats
# jump dist = spawn dist in meter
# jump speed = speed in m/s [in _difficultyBeatmapSets]

# Note Jump Speed (NJS) controls the speed at which objects approach the player, in meters per second. 
# It should be the first parameter you adjust after you do the audio setup.
# Generally it is simplest to focus on reaction time, and ignore jump distance, half jump duration and spawn offset; 
# letting them be automatically calculated.

# jump dist ~23-25 range
#endregion

#region metadata
var version:String
var songName:String
var songSubName:String
var songAuthorName:String
var levelAuthorName:String
var beatsPerMinute:float
var songFilename:String
var coverImageFilename:String
var beatmapCharacteristicName:String
#var difficulties:Array[String]
var beatmapFiles:Dictionary
var numHittableNotes:int
var nAllNotes:int
#endregion

#region noteSpecs
var beatmapFileName:String
var noteMoveSpeed:float
var noteSpawnDist:float
var noteReactionTime:float = 0.75
#endregion
