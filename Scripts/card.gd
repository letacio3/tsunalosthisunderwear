extends CenterContainer

var hovering
signal entered(node: Node)
signal selected(node: Node)
@onready var border: TextureRect = $Border
@onready var card: TextureRect = $Card
var switched: bool
var id: int = 1
var selectable = true
var pos: int = 0
@onready var animation_player: AnimationPlayer = $Card/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_card_mouse_entered() -> void:
	if selectable:
		hovering = true
		entered.emit(self)
		scale = 1.05*Vector2.ONE


func _on_card_mouse_exited() -> void:
	scale = Vector2.ONE	
	hovering = false


func _on_card_gui_input(event: InputEvent) -> void:
	if event.is_action_released("click") and hovering and selectable:
		selected.emit(self)
		print("selected")
		
func switch_side() -> bool:
	if not switched:
		card.texture = load("res://Img/"+str(id)+".png")
	else:
		card.texture = load("res://Img/back.png")
	switched = not switched
	return switched

func flip() -> bool:
	animation_player.play("flip", -1, 2.0) 
	await get_tree().create_timer(0.5).timeout
	return true
