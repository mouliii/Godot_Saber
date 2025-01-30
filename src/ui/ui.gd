extends CanvasLayer

func _ready() -> void:
	var vscroll = $SongMenu/ScrollContainer.get_v_scroll_bar() as VScrollBar
	vscroll.custom_minimum_size.x = 30
	%DifficultySelector.item_selected.connect(SetDifficulty)
	$SongMenu/RightSide/VBoxContainer/Buttons/StartButton.pressed.connect(StartGame)
	$CalibMenu/VBoxContainer2/BackBtn.pressed.connect(BackToMainMenu)
	$SongMenu/RightSide/VBoxContainer/Buttons/BackButton.pressed.connect(BackToMainMenu)
	# main menu ###### ENTERED #########
	$MainMenu/VBoxContainer/SongListBtn.mouse_entered.connect(MouseEntered.bind($MainMenu/VBoxContainer/SongListBtn))
	$MainMenu/VBoxContainer/CalibBtn.mouse_entered.connect(MouseEntered.bind($MainMenu/VBoxContainer/CalibBtn))
	$MainMenu/VBoxContainer/QuitBtn.mouse_entered.connect(MouseEntered.bind($MainMenu/VBoxContainer/QuitBtn))
	# calib menu
	$CalibMenu/VBoxContainer2/Button.mouse_entered.connect(MouseEntered.bind($CalibMenu/VBoxContainer2/Button))
	$CalibMenu/VBoxContainer2/BackBtn.mouse_entered.connect(MouseEntered.bind($CalibMenu/VBoxContainer2/BackBtn))
	# song menu
	$SongMenu/RightSide/VBoxContainer/Buttons/BackButton.mouse_entered.connect(MouseEntered.bind($SongMenu/RightSide/VBoxContainer/Buttons/BackButton))
	$SongMenu/RightSide/VBoxContainer/Buttons/StartButton.mouse_entered.connect(MouseEntered.bind($SongMenu/RightSide/VBoxContainer/Buttons/StartButton))
	# main menu ######### EXITED ########
	$MainMenu/VBoxContainer/SongListBtn.mouse_exited.connect(MouseExited)
	$MainMenu/VBoxContainer/CalibBtn.mouse_exited.connect(MouseExited)
	$MainMenu/VBoxContainer/QuitBtn.mouse_exited.connect(MouseExited)
	# calib menu
	$CalibMenu/VBoxContainer2/Button.mouse_exited.connect(MouseExited)
	$CalibMenu/VBoxContainer2/BackBtn.mouse_exited.connect(MouseExited)
	# song menu
	$SongMenu/RightSide/VBoxContainer/Buttons/BackButton.mouse_exited.connect(MouseExited)
	$SongMenu/RightSide/VBoxContainer/Buttons/StartButton.mouse_exited.connect(MouseExited)

func SetDifficulty(id:int)->void:
	var text:String = %DifficultySelector.get_item_text(id)
	GlobalSignals.DIFFICULTY_SELECTED.emit(text)

func StartGame()->void:
	GlobalSignals.START_GAME.emit()
	

func _on_song_list_btn_pressed() -> void:
	$MainMenu.hide()
	$SongMenu.show()


func _on_calib_btn_pressed() -> void:
	$MainMenu.hide()
	$CalibMenu.show()


func BackToMainMenu() -> void:
	$SongMenu.hide()
	$CalibMenu.hide()
	$MainMenu.show()

func MouseEntered(btn:Button)->void:
	GlobalSignals.BUTTON_SELECTED.emit(btn)

func MouseExited()->void:
	GlobalSignals.BUTTON_DESELECTED.emit()
