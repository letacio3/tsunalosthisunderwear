extends Sprite2D
var time: float
var inverse: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not inverse:
		time += delta
	elif inverse:
		time -= delta
	if time >= 5:
		inverse = true
	elif time <= -5:
		inverse = false
		
	if material != null:
		material.set_shader_parameter("speed",time*0.002)
		material.set_shader_parameter("t",time)
	pass
	
func test():
	pass


func _on_lobby_back() -> void:
	pass # Replace with function body.
