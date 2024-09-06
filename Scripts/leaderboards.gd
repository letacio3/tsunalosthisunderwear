extends Control
@onready var item_list: ItemList = $Panel/ItemList
@onready var tab_bar: TabBar = $Panel/TabBar
signal back
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SilentWolf.Scores.sw_get_scores_complete.connect(_on_scores_fetched)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open():
	SilentWolf.Scores.get_scores(100)
	SilentWolf.Scores.get_scores(100, "multiplayer")
	show()
	var i:int = 0
	_on_tab_bar_tab_changed(tab_bar.current_tab)
	


func _on_tab_bar_tab_changed(tab: int) -> void:
	item_list.clear()
	var target = "main"
	if tab == 1:
		target = "multiplayer"
	var i:int = 1
	if target in SilentWolf.Scores.leaderboards:
		for score in SilentWolf.Scores.leaderboards.get(target):
			item_list.add_item(str(i) + "    |    " + score.player_name.split("#")[0] + "    |    " \
			+ str(score.score))
	pass # Replace with function body.


func _on_back_pressed() -> void:
	back.emit()
	pass # Replace with function body.

func _on_scores_fetched(scores) -> void:
	_on_tab_bar_tab_changed(tab_bar.current_tab)
