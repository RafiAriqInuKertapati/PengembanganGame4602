extends MarginContainer

class_name HUD


@onready var life_counter = $HBoxContainer/LifeCounter.get_children()
@onready var score_label = $HBoxContainer/Score

var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var msec: int = 0

func _ready():
	print("LifeCounter found: ", $HBoxContainer/Timer/LifeCounter)
	print("Score found: ", $HBoxContainer/Score)
	print("limitedTime: ", $Timer/limitedTime)

func update_life(value: int):
	for heart in life_counter.size():
		life_counter[heart].visible = value > heart
		
func update_score(value: int):
	$HBoxContainer/Score.text = str(value)
	
func _process(delta) -> void:
	time += delta
	msec = fmod(time, 1) * 60
	seconds = fmod (time, 60)
	minutes = fmod (time, 3600) / 60
	$Timer/limitedTime.text = "%02d." % minutes
	$Timer/limitedTime2.text = "%02d." % seconds 
	$Timer/limitedTime3.text = "%02d" % msec
	
func stop() -> void:
	set_process(false)
	
func get_time_formatted() -> String:
	return "%02d.%02d.%02d" % [minutes, seconds, msec]
