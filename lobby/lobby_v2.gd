extends Control

var mp1 : MatchaRoom
var timer: float 
var multiplayer_not_set: bool
var players_online = []
var my_id: int
var looking_for_match: bool
var op_id: int
var match_confirmed: bool
var status: int = 0
var op_data
var room_leader:bool
@export var main_menu: Node

signal match_ready()
signal back
signal cards_received(cards, turn)

func _on_peer_joined(_id, peer):
	print("(1) Peer connected: ", _id)
	players_online.append(_id)
	if !multiplayer_not_set:
		multiplayer_not_set = true
		my_id = multiplayer.get_unique_id()
	
func _on_peer_left(_id, peer):
	print("(1) Peer left: ", _id)
	players_online.erase(_id)

func _process(delta: float) -> void:
	if looking_for_match:
		if status == 0:
			status = 1
			mp1 = MatchaRoom.create_mesh_room({ "identifier": "tlhu-lobby" })
			mp1.peer_joined.connect(_on_peer_joined)
			mp1.peer_left.connect(_on_peer_left)
			mp1.connection_estabilished.connect(_on_connetion_estabilished)
			mp1.disconnected.connect(_on_disconnected)
		elif status == 2:
			timer += delta
			if timer > 1:
				timer = 0
				rpc_looking_for_match.rpc()
		
@rpc("any_peer","call_remote","unreliable")
func rpc_looking_for_match():
	if looking_for_match:
		looking_for_match = false
		var sender:int = multiplayer.get_remote_sender_id()
		my_id = multiplayer.get_unique_id()
		op_id = sender
		#print(str(my_id), " received from ", str(sender))
		rpc_confirm_match.rpc_id(op_id, my_id, main_menu.user_data)
		
@rpc("any_peer","call_remote","reliable")
func rpc_confirm_match(_op_id, _op_data):
	if not match_confirmed:
		looking_for_match = false
		op_data = _op_data
		match_confirmed = true
		var sender: int = multiplayer.get_remote_sender_id()
		my_id = multiplayer.get_unique_id()
		op_id = sender
		#print(str(my_id), " received from ", str(sender))
		rpc_confirm_match.rpc_id(op_id, my_id, main_menu.user_data)
		
		if my_id > _op_id:
			room_leader = true
		else:
			room_leader = false
			
		match_ready.emit()

func _on_connetion_estabilished():
	status = 2
	multiplayer.multiplayer_peer = mp1

func _on_disconnected():
	status = 0
