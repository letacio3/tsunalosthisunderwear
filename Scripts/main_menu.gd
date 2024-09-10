extends Control

@export var leaderboards: Control
@export var game: Control
@export var lobby: Control
@export var about: Control
var lobby_scene = load("res://lobby/lobby.tscn")
var user_data = {
	"Name": "",
	"Score_solo": 0,
	"Score_multi": 0,
	"Data": {}
}
var op_data = {
	"Name": "",
	"Score_solo": 0,
	"Score_multi": 0,
	"Data": {}
}
var ask_name: bool
var menu_scene = load("res://Scenes/menu.tscn")
@onready var ask_name_node: Panel = $"../AskName"
var logged: bool = false
@onready var input_name: TextEdit = $"../AskName/Panel/TextEdit"
var user_path = "user://user.json"
@onready var error: Label = $"../AskName/Panel/error"
@onready var line_2d: Line2D = $"../Audio/Line2D"
var leader: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SilentWolf.configure({
	"api_key": "n8JG9uXum42veuioLW01Hao9bkE28GCm5YD2oM21",
	"game_id": "TsunaLostHisUnderwear",
	"log_level": 1
	})
	SilentWolf.Auth.sw_registration_complete.connect(_on_registration_complete)
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	SilentWolf.Scores.sw_get_player_scores_complete.connect(_on_get_solo_scores)
	if FileAccess.file_exists(user_path):
		user_data = Global.read_json(user_path)
	else:
		Global.save_dict_to_json(user_data, user_path)
	
	if user_data.Name == "":
		ask_name = true
	else:
		SilentWolf.Auth.login_player(user_data.Name, "nopassSSss1")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_leaderboards_pressed() -> void:
	leaderboards.open()
	hide()
	
func _on_play_pressed() -> void:
	game.show()
	game.start_solo(user_data.Name, user_data.Score_solo)
	hide()
	
func _on_leaderboards_back() -> void:
	leaderboards.hide()
	show()

func _on_game_back() -> void:
	#OS.create_instance([])
	#get_tree().quit()
	#get_parent().queue_free()
	#return
	lobby.match_confirmed = false
	game.hide()
	show()
	rpc_disconnected_from_lobby.rpc_id(game.op_id)
	
func _on_lobby_match_ready() -> void:
	game.show()
	game.reset_game()
	game.start_multi(user_data.Name, user_data.Score_multi, lobby.op_id,\
					lobby.op_data.Name, lobby.op_data.Score_multi, lobby.room_leader)
	#lobby.hide()
	
func _on_lobby_back() -> void:
	#lobby.show_lobby()
	#lobby.hide()
	show()

func _on_about_pressed() -> void:
	about.show()
	hide()
	pass # Replace with function body.

func _on_multi_pressed() -> void:	
	#lobby.show_lobby()
	lobby.looking_for_match = true
	hide()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Intro":
		if ask_name:
			ask_name_node.visible = true

func _on_name_pressed() -> void:
	user_data.Name = input_name.text +"#" + Time.get_datetime_string_from_system()
	Global.save_dict_to_json(user_data, user_path)
	SilentWolf.Auth.register_player(user_data.Name, "nomail@dadada.com", "nopassSSss1", "nopassSSss1")
	pass # Replace with function body.


func _on_registration_complete(sw_result):
	if sw_result.success:
		print("Registration succeeded!")
		ask_name_node.visible = false
	else:
		error.text = sw_result.error

func _on_login_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		print("Login succeeded!")
		print("logged in as: " + str(SilentWolf.Auth.logged_in_player))
		logged = true
		await SilentWolf.Players.get_player_data(user_data.Name)
		print("Player data: " + str(SilentWolf.Players.player_data))
		user_data.Data = SilentWolf.Players.player_data
		var score = await SilentWolf.Scores.get_scores_by_player(user_data.Name, 10, "main")
		Global.save_dict_to_json(user_data, user_path)
		#lobby.set_room_name(user_data.Name)
	else:
		error.text = sw_result.error
		SilentWolf.Auth.register_player(user_data.Name, "nomail@dadada.com", "nopassSSss1", "nopassSSss1")

func save_data():
	SilentWolf.Players.post_player_data(user_data.Name, user_data.Data)
	Global.save_dict_to_json(user_data, user_path)
	
func save_score():
	SilentWolf.Scores.persist_score(user_data.Name, user_data.Score)
	Global.save_dict_to_json(user_data, user_path)


func _on_about_back() -> void:
	about.hide()
	show()


func _on_audio_pressed() -> void:
	Global.audio = not Global.audio
	line_2d.visible = not Global.audio
	AudioServer.set_bus_mute(0, not Global.audio)


func _on_plus_pressed() -> void:
	Global.volume += 5
	if Global.volume >= 30.0:
		Global.volume = 30
	AudioServer.set_bus_volume_db(0, Global.volume)
	pass # Replace with function body.


func _on_minus_pressed() -> void:
	Global.volume -= 5
	if Global.volume <= -40:
		Global.volume = -40
	AudioServer.set_bus_volume_db(0, Global.volume)
	pass # Replace with function body.

func _on_get_solo_scores(sw_result):
	var res = sw_result
	if SilentWolf.Scores.player_scores.size() > 0:
		user_data.Score_solo = SilentWolf.Scores.player_scores[0].score
		SilentWolf.Scores.sw_get_player_scores_complete.disconnect(_on_get_solo_scores)
		SilentWolf.Scores.sw_get_player_scores_complete.connect(_on_get_multi_scores)
		await get_tree().create_timer(1).timeout
		var score = await SilentWolf.Scores.get_scores_by_player(user_data.Name, 10, "multiplayer")

func _on_get_multi_scores(sw_result):
	var res = sw_result
	if SilentWolf.Scores.player_scores.size() > 0:
		user_data.Score_multi = SilentWolf.Scores.player_scores[0].score
		SilentWolf.Scores.sw_get_player_scores_complete.disconnect(_on_get_multi_scores)
		SilentWolf.Scores.sw_get_player_scores_complete.connect(_on_get_solo_scores)
		#SilentWolf.Scores.sw_get_player_scores_complete.connect(_on_get_solo_scores)

@rpc("any_peer","call_remote","reliable")
func rpc_disconnected_from_lobby():
	if game.visible:
		_on_game_back()
