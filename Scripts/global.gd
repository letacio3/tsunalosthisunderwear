extends Node
var unix_local_timezone_offset:float
var local_timezone_offset_string: String
var main: Node2D
var request: HTTPRequest = HTTPRequest.new()
var audio: bool = true
var volume: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	get_timezone()
	add_child(request)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func utc_to_Local(date:Dictionary):
	var dict = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict(date) + unix_local_timezone_offset)
	if dict["minute"] == 59:
		dict["hour"]+=1
		dict["minute"] = 0
		dict["second"] = 0
	return dict 
		
func local_to_utc(date:Dictionary):
	var dict = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict(date) - unix_local_timezone_offset)
	if dict["minute"] == 59:
		dict["hour"]+=1
		dict["minute"] = 0
		dict["second"] = 0 
	return dict

func get_timezone():
	var unix_system = Time.get_unix_time_from_system()
	var unix_timezone = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system(false))
	unix_local_timezone_offset = unix_timezone - unix_system 
	local_timezone_offset_string = Time.get_offset_string_from_offset_minutes(int(unix_local_timezone_offset/60))
	
func get_text_after_string(from:String,find:String):
	var id_position: int = from.rfind(find)
	var substring: String = from.substr(id_position + find.length())
	var newline_position: int = substring.find("\n")
	if newline_position != -1:
		substring = substring.substr(0, newline_position)
	return substring
func array_to_string(input: Array):
	var output:String
	for i in input:
		output += str(i) + "\n"
	return output
	
func read_json(path):
	var file = FileAccess.open(path,FileAccess.READ)
	var dict = {}
	if file != null:
		var json = JSON.new()
		var string2 = file.get_as_text()
		var error = json.parse(string2)
		dict = json.get_data()
	return dict
	
func save_dict_to_json(dict_to_save: Dictionary, file_path: String) -> void:
	var json_string := JSON.stringify(dict_to_save) # Convert the dictionary to a JSON string
	var file := FileAccess.open(file_path,FileAccess.WRITE) # Create a new File object
	file.store_string(json_string) # Write the JSON string to the file
	file.close() # Close the file

func download_image_from_url(url, path):
	request.download_file = path
	request.request(url, [], HTTPClient.METHOD_GET)
