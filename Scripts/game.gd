extends Control
@onready var player_2: VBoxContainer = $Player2
@onready var points_2: Label = $HBoxContainer/Points2
@onready var points_1: Label = $HBoxContainer/Points1
@onready var player_1_name: Label = $Player1/Player1
@onready var player_2_name: Label = $Player2/Player2
@onready var rank_1: Label = $Player1/Rank1
@onready var rank_2: Label = $Player2/Rank2
@export var lobby: Node
var card_scene = load("res://Scenes/card.tscn")
@onready var card_drop: GridContainer = $board/GridContainer
var selected_1: Node = null
var selected_2: Node = null
var my_turn = false
var solo = false
var turn: int = 1
var player_name: String
var pt1:int = 0
var pt2:int = 0
var leader: bool
var last_turn: bool = true
signal back
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var op_id: int = 0
var timer: float
var connection_checked: bool = false
var my_request: int
var turn_busy: bool
var cards = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if last_turn != my_turn:
		last_turn = my_turn
		if my_turn:
			animation_player.play("my_turn")
		else:
			animation_player.play("op_turn")
	if not connection_checked and visible:
		if timer <= 1:
			timer += delta
		else:
			timer = 0
			my_request = multiplayer.get_unique_id()


func _on_button_pressed() -> void:
	back.emit()
	connection_checked = false
	pass # Replace with function body.

func start_solo(_player_name, score):
	player_2.visible = false
	points_2.visible = false
	player_name = _player_name
	player_1_name.text = _player_name.split("#")[0]
	rank_1.text = str(score)
	points_1.text = str(0)
	solo = true
	my_turn = true
	reset_game()
	generate_board()
	
	
func start_multi(_player_name, score, _op_id, op_name, op_score, leader):
	reset_game()
	op_id = _op_id
	player_2.visible = true
	points_2.visible = true
	solo = false
	player_name = _player_name
	player_1_name.text = _player_name.split("#")[0]
	rank_1.text = str(score)
	player_2_name.text = str(op_name.split("#")[0])
	rank_2.text = str(op_score)
	if leader:
		var rand = randi_range(0, 1)
		if rand:
			my_turn = true
		generate_board()

func generate_board():
	var array = []
	for i in 24:
		if i < 12:
			array.append(i + 1)
		else:
			array.append(i + 1 - 12)
	array.shuffle()
	create_cards(array)
	
	if !solo:
		rpc_send_board.rpc_id(op_id, array, not my_turn)
		#lobby.send_board(array, not my_turn)
	
func create_cards(array):
	var i:int = 0
	for a in array:
		var card_instance = card_scene.instantiate()
		card_instance.id = a
		card_instance.pos = i
		card_drop.add_child(card_instance)
		card_instance.entered.connect(_on_card_hovered)
		card_instance.selected.connect(_on_card_selected)
		i += 1
	

func _on_card_hovered(node: Node) -> void:
	#print("entered ", node)
	pass # Replace with function body.


func _on_card_selected(node: Node, rpc: bool = false) -> void:
	if (my_turn || rpc) and not turn_busy:
		turn_busy = true
		if not rpc:
			rpc_flip_card.rpc_id(op_id, node.pos)
		await node.flip()
		if selected_1 == null:
			selected_1 = node
			turn_busy = false
			#turn_end()
		elif selected_2 == null:
			selected_2 = node
			check_for_match()
		
@rpc("any_peer","call_local","reliable")
func rpc_flip_card(pos: int):
	_on_card_selected(card_drop.get_child(pos), true)

func check_for_match():
	if selected_1.id == selected_2.id:
		selected_1.selectable = false
		selected_2.selectable = false
		if my_turn:
			pt1 += 1
			points_1.text = str(pt1)
		else:
			pt2 += 1
			points_2.text = str(pt2)
		if pt1 + pt2 == 12:
			var score = (snappedf(pt1/float(turn) , 0.1)*1000) + float(rank_1.text)
			var leadb = "main"
			if !solo:
				leadb = "multiplayer"
			var response = await SilentWolf.Scores.save_score(player_name, score, leadb)
			rank_1.text = str(score)
	else:
		await selected_1.flip()
		await selected_2.flip()
		if my_turn:
			turn_end()
	selected_1 = null
	selected_2 = null
	turn_busy = false

func turn_end():
	if solo:
		my_turn = true
	elif my_turn:
		my_turn = false
		rpc_turn_ended.rpc_id(op_id)
	turn += 1
	

func reset_game():
	pt1 = 0
	pt2 = 0 
	turn = 1
	selected_1 = null
	selected_2 = null
	#my_turn = false
	for child in card_drop.get_children():
		child.queue_free()
	var leaderboard = "main"
	if !solo:
		leaderboard = "multiplayer"
	var score = await SilentWolf.Scores.get_scores_by_player(player_name, 2, leaderboard)
	await get_tree().create_timer(2).timeout
	if score.player_scores.size() > 0:
		rank_1.text = str(score.player_scores[0].score)
	#rpc_send_data.rpc_id(op_id, player_1_name.text, rank_1.text)

func rpc_cards_received(array, turn):
	my_turn = turn
	create_cards(array)


func _on_lobby_op_data_received(_op_data: Variant) -> void:
	return
	player_2_name.text = str(_op_data.Name.split("#")[0])
	rank_2.text = str(_op_data.Score_multi)

func config_multiplayer(multiplayer_peer):
	op_id = 1
	
@rpc("any_peer", "call_local", "reliable")
func rpc_send_board(_board: Array, _my_turn: bool):
	cards = _board
	my_turn = _my_turn
	await get_tree().create_timer(1).timeout
	create_cards(cards)
	
@rpc("any_peer", "call_local", "reliable")
func rpc_turn_ended():
	await get_tree().create_timer(1).timeout
	my_turn = true
	turn += 1
