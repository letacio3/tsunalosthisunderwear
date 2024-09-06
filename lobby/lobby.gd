extends Control

@export var main_menu: Node
@onready var _room_list: ItemList = $Rooms/room_list
var _lobby := MatchaLobby.new({ "identifier": "TLHU" })
var _selected_room
var my_room: MatchaRoom
#var size: = 0
var timer:float = 0.0
var room_leader: bool
var peers_in_room: Array[int]
var my_room_dict: Dictionary
signal match_ready(my_peer)
signal back
signal cards_received(cards, turn)
signal op_data_received(op_data)
@onready var rooms: Control = $Rooms
@onready var current_room: Control = $current_room
@onready var ui: Panel = $UI
@onready var back_button: Button = $Back
@onready var chat_history: RichTextLabel = $UI/chat_history
@onready var room_name_edit: TextEdit = $Rooms/room_name_edit

func _init():
	#OS.request_permissions()
	_lobby.joined_room.connect(self._on_joined_room)
	_lobby.left_room.connect(self._on_left_room)
	_lobby.room_created.connect(self._on_room_created)
	_lobby.room_updated.connect(self._on_room_updated)
	_lobby.room_closed.connect(self._on_room_closed)
	_lobby.connected_to_lobby.connect(self._on_lobby_ok)
	_lobby.disconnected_from_lobby.connect(self._on_lobby_disconnected)
#func _ready():
#	lobby.create_room({ "name": "Penis" })

# Private methods
func _process(delta: float) -> void:
		timer += delta
		if timer >= 2:
			timer = 0
func _on_joined_room(room: MatchaRoom):
	room.peer_joined.connect(self._on_peer_joined_room)
	room.peer_left.connect(self._on_peer_left_room)
	my_room = room
	$Rooms/room_join_btn.disabled = true
	$Rooms/room_create_btn.disabled = true
	chat_history.text = "You joined the room: %s\n" % [room.id]
	$current_room/room_leave_btn.disabled = false
	#var webrtc_multiplayer := WebRTCMultiplayerPeer.new()
	#webrtc_multiplayer.initialize()

	# Add the WebRTCMultiplayer to the multiplayer system.
	#get_tree().set_multiplayer(webrtc_multiplayer)
	multiplayer.multiplayer_peer = room
	

func _on_left_room(_room: MatchaRoom):
	my_room = null
	chat_history.text += "You left the room\n"
	$current_room/room_leave_btn.disabled = true
	$Rooms/room_join_btn.disabled = false
	$Rooms/room_create_btn.disabled = false

func _on_room_created(room: Dictionary) -> void:
	var room_name = "Unnamed room (%s)" % [room.id]
	if "name" in room.meta and room.meta.name != "":
		room_name = room.meta.name
	
	var index := _room_list.add_item(room_name)
	_room_list.set_item_metadata(index, room)
	var meta = _room_list.get_item_metadata(index)
	

func _on_room_updated(room: Dictionary) -> void:
	for i in _room_list.item_count:
		var list_room = _room_list.get_item_metadata(i)
		if list_room != null:
			if list_room.id == room.id: 
				if room.meta.players >= room.meta.max_players:
					_room_list.remove_item(i)
					if _lobby._current_room != null:
						if _lobby._current_room.id == room.id:
							match_ready.emit(_lobby._current_room)#, \
							#_lobby._current_room._connected_peers.keys()[0])
							var leader = is_room_leader()
							emit_event("send_player_data", [main_menu.user_data])
				else:
					_room_list.set_item_metadata(i, room)
					_room_list.set_item_text(i, room.meta.name)
			

		

func _on_room_closed(room: Dictionary) -> void:
	for i in _room_list.item_count:
		var list_room = _room_list.get_item_metadata(i)
		if list_room.id != room.id: continue
		_room_list.remove_item(i)
		return

func _on_peer_joined_room(_rpc_id: int, peer: MatchaPeer):
	peers_in_room.append(_rpc_id)
	chat_history.text += "Peer joined the room (id: %s)\n" % [peer.id]
	peer.on_event("chat", self._on_peer_chat.bind(peer))
	peer.on_event("cards_generated", self._on_cards_generated)
	peer.on_event("test", self._on_test)
	peer.on_event("send_player_data", self._on_op_data_received)
	
	if is_room_leader():
		my_room_dict.meta.players += 1
		_lobby.update_room(my_room_dict.meta)

func _on_peer_left_room(_rpc_id: int, peer: MatchaPeer):
	chat_history.text += "Peer left the room (id: %s)\n" % [peer.id]
	_lobby.leave_room()

# UI Callbacks
func _on_room_create_btn_pressed() -> void:
	if _lobby.current_room != null: return
	_lobby.create_room({ "name": $Rooms/room_name_edit.text,
						"players": 1,
						"max_players": 2})

func _on_room_list_item_selected(index: int):
	if _lobby.current_room != null: return
	_selected_room = _room_list.get_item_metadata(index)
	$Rooms/room_join_btn.disabled = false

func _on_room_list_empty_clicked(_at_position, _mouse_button_index):
	if _lobby.current_room != null: return
	_room_list.deselect_all()
	_selected_room = null
	$Rooms/room_join_btn.disabled = true

func _on_room_leave_btn_pressed():
	if _lobby.current_room == null: return
	_lobby.leave_room()

func _on_room_join_btn_pressed():
	if _lobby.current_room != null: return
	if _selected_room == null: return
	_lobby.join_room(_selected_room.id)

func _on_peer_chat(message: String, peer: MatchaPeer) -> void:
	#$UI/chat_history.text = ""
	$UI/chat_history.text += "\n%s: %s" % [peer.id, message]
	#my_room[peer.id].set_message(message)
	
func _on_line_edit_text_submitted(new_text) -> void:
	if new_text == "": return
	emit_event("chat", [new_text])


func _on_chat_send_pressed() -> void:
	_on_line_edit_text_submitted($UI/chat_input.text)
	
func emit_event(event_name: String, args: Array = []):
	my_room.send_event(event_name, args)
	self_event(event_name, args)
	
func self_event(event_name: String, args: Array = []):
	if event_name == "chat":
		$UI/chat_input.text = ""
		#$UI/chat_history.text = ""
		$UI/chat_history.text += "\n%s (Me): %s" % [_lobby._lobby.peer_id, args[0]]
	
func is_room_leader():
	my_room_dict = {}
	for room in _lobby.room_list:
		if room.id == _lobby._current_room.id:
			my_room_dict = room
			break
	room_leader = (_lobby.current_room.type == "server")
	return room_leader


func _on_back_pressed() -> void:
	back.emit()

func show_chat():
	hide()
	rooms.visible = false
	#current_room.visible = true
	return
	ui.visible = true
	back_button.visible = false

func show_lobby():
	show()
	
	my_room = null
	#var size: = 0= 
	room_leader= false
	peers_in_room.clear()
	my_room_dict = {}
	rooms.visible = true
	#current_room.visible = false
	ui.visible = false
	back_button.visible = true

func set_room_name(name):
	room_name_edit.text = name.split("#")[0] + "'s Room"

func send_board(array, your_turn):
	emit_event("cards_generated", [array])
	emit_event("test", [array])

func _on_test(data):
	print(data)
	
func _on_cards_generated(cards) -> void:
	if !is_room_leader():
		emit_event("send_player_data", [main_menu.user_data])
		cards_received.emit(cards)

func _on_op_data_received(op_data) -> void:
	op_data_received.emit(op_data)

@rpc("any_peer")
func rpc_test(msg):
	print(multiplayer.get_remote_sender_id(), multiplayer.get_unique_id())
	
	print(msg)
	pass

func _on_lobby_ok():
	print("lobby ok!")
	multiplayer.multiplayer_peer = _lobby._lobby

func _on_lobby_disconnected():
	print("lobby disconnected")
