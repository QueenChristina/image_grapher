extends Node2D

onready var x_axis = $xAxis
onready var y_axis = $yAxis
#get parameters from user
onready var input_eq = $UI/equationInput
onready var input_labels = $UI/labelInput
onready var input_colors = $UI/colorPick/colors
onready var input_visibility = $UI/show
onready var input_file = $UI/upload
onready var ui = $UI
#file
onready var popup_tile = $selectImg

#graph tile image
var tile_img = preload("res://icon.png")
var delta_x_img = 1
#samples points at each delta_x to plot a line curve from min_x to max_x. 
var delta_x = 0.1

#equation must be a function y = "something with x"
var equation = Expression.new()

#stores nodes of line2Ds with label lines
var label_lines_x = []
var label_lines_y = []
#stores graph line
var graph
var graph_tiles = []

#stores the colors of the label lines
var color_label_lines =  Color("dce3e8")
var color_graph_line =  Color(0.6, 0.7, 0.9)
var color_axis = Color("a5b4ff")

#graph window scale size, number of subdivisions across screen is abs(max) + abs(min)
var max_x = 10
var min_x = -10
var max_y = 10
var min_y = -10

#sum of min and max x and y for calculation purposes
var tot_x = abs(max_x) + abs(min_x)
var tot_y = abs(max_y) + abs(min_y)

#how to label subdivide/scale labels on axis. Default is unit squares
#when allowing user to input, make sure it is positive and not 0
var step_x = 1.0
var step_y = 1.0
#real window step amount (pixels) per unit graph
var real_step_x
var real_step_y

#stores location in real window coordinates of origin
var origin_x = 0
var origin_y = 0

#speed factors of zooming and panning. Smaller is slower
#to do: change factor depending on size window (min/max x) 
#because speed should be relative to window size (right now speed is constant regardless window size)
var speed_pan = 0.3
var speed_zoom = 0.9

var is_mouse_in_ui = false
var is_color_picking = false

func _ready():
	draw_axis()
	connect_to_input()
	
	#graph curve cosmetics
	graph = Line2D.new()
	self.add_child(graph)
	#cosmetic changes
	graph.width = 2
	graph.default_color = color_graph_line
	graph.z_index = 0
		
	#default equation for now
	equation.parse("x", ["x"])

func _input(event):
	#also make sure mouse is on map and NOT a UI ex. not color picking
	if !is_mouse_in_ui and !is_color_picking:
		if Input.is_action_pressed("mouse_right") and event is InputEventMouseMotion:
			#Zooming in with special control depending on direction mouse
			var change_pos = speed_zoom*event.relative.normalized()
			max_x += change_pos.x
			min_x -= change_pos.x
			max_y += change_pos.y
			min_y -= change_pos.y
			#print("The new min x: " + str(min_x) + " max " + str(max_x))
			#only redraw every so often, and not every change
			call_deferred("draw_axis")
			call_deferred("draw_graph")
		elif Input.is_action_pressed("mouse_left") and event is InputEventMouseMotion:
			#panning
			var change_pos = speed_pan*event.relative.normalized()
			max_x -= change_pos.x
			min_x -= change_pos.x
			max_y += change_pos.y
			min_y += change_pos.y
			call_deferred("draw_axis")
			call_deferred("draw_graph")
	if Input.is_action_pressed("ui_select"): #space key
		ui.visible = not ui.visible	

#connects line edits text inputs (press enter in line) to this
func connect_to_input():
	for child in ( input_labels.get_children() + input_eq.get_children() ):
		if child.get_class() == "LineEdit":
			child.connect("text_entered", self, "set_param", [child.get_name()])
			child.caret_blink = true
	for child in input_colors.get_children():
		if child.get_class() == "ColorPickerButton":
			child.connect("color_changed", self, "set_color", [child.get_name()])
			#child.connect("picker_created", self, "mouse_in_ui")
			#child.connect("popup_closed", self, "mouse_out_ui")
			child.get_popup().connect("about_to_show", self, "color_picking")
			child.get_popup().connect("popup_hide", self, "color_picked")
	for child in input_visibility.get_children():
		if child.get_class() == "CheckBox":
			child.connect("toggled", self, "set_visibility", [child.get_name()])
			
	#set to see if mouse enters/exist
	var inputs = [input_labels, input_colors, input_eq, input_visibility]
	for interface in inputs:
		for child in interface.get_children():
			child.connect("mouse_entered", self, "mouse_in_ui")
			child.connect("mouse_exited", self, "mouse_out_ui")
			
	#to connect to file upload buttons
	for button in input_file.get_children():
		button.connect("pressed", self, "open_file", [button.get_name()])
		
	#connect to file popup
	popup_tile.connect("file_selected", self, "upload_tile")
			
#saves the drawing you made	
func save_screenshot():
	#var capture = get_viewport().get_screen_capture()
	#https://godotengine.org/qa/13967/need-to-generate-and-save-textures-to-disk
	#print(capture)
	#saving and reading files https://docs.godotengine.org/en/stable/classes/class_file.html 
	pass
		
#uploads tile image
func upload_image():
	pass
		
func open_file(name):
	match name:
		"tile": #change graph tile image
			print("tile")
			popup_tile.show()
			#freeze game until finish image selection
		"bg": #change background image
			pass
		"screen": #screenshot graph and download
			pass
			
func upload_tile(file_path):
	#https://docs.godotengine.org/en/stable/classes/class_file.html
	tile_img = load(file_path)
	draw_graph()
	
func load(file_path):
	#https://www.reddit.com/r/godot/comments/eojihj/how_to_load_images_without_importer/
	#var file = File.new()
	var image = Image.new()
	#https://godotengine.org/qa/50876/load-texture-from-file-and-assign-to-texture
	#loading works inside res:// but not outside: 
	#https://www.reddit.com/r/godot/comments/c0z076/cant_use_resourceloader_outside_res_godot_31/
	#solution: https://godotengine.org/qa/1349/find-files-in-directories?show=1349#q1349
	#https://github.com/godotengine/godot/issues/17848
	
	var err = image.load(file_path)
	if err != OK:
		# Failed
		return
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture
	
	"""
	file.open(file_path, File.READ)
	match file_path.get_extension():
		"png":
			image.load_png_from_buffer(file.get_buffer(file.get_len()))
		"jpg":
			image.load_jpg_from_buffer(file.get_buffer(file.get_len()))
	
	#image.set_data(file.get_var())
	file.close()
	image.lock()
	return image
	#load(file_path)"""
	
			
#set of functions to determine if mouse is in UI or not, determines if grid is movable	
func color_picking():
	is_color_picking = true
	
func color_picked():
	is_color_picking = false
		
func mouse_in_ui():
	is_mouse_in_ui = true
	
func mouse_out_ui():
	is_mouse_in_ui = false
	
#sets visibilty of elements of grapher
func set_visibility(_is_pressed, name):
	#pressed means we WANT to show the item
	match name:
		"graph":
			graph.visible = !graph.visible
		"axis":
			x_axis.visible = !x_axis.visible
			y_axis.visible = !y_axis.visible
		"label":
			#label grid lines are special since they are regenerated each time we change graph
			for line in (label_lines_x + label_lines_y):
				line.visible = !line.visible
		"images":
			for tile in graph_tiles:
				tile.visible = !tile.visible
			
#sets color of axis and lines
func set_color(color, name):
	#is_mouse_in_ui = true
	match name:
		"axis":
			color_axis = color
			x_axis.default_color = color
			y_axis.default_color = color
		"labels":
			color_label_lines = color
			#instead of drawing new lines, set to new color
			for line in (label_lines_x + label_lines_y):
				line.default_color = color
		"graph":
			color_graph_line = color
			graph.default_color = color
		"paper":
			#set background color
			VisualServer.set_default_clear_color(color)
	#draw_axis()
			
#sets parameters based on inputs
func set_param(amount, name):
	amount = amount.strip_edges(true, true) #strips off whitespaces from edges
	if amount == "" or amount == null:
		print("Invalid input.")
		return
	
	if name == "equation":
		#parse amount to be equation as function with respect to variable x
		var error = equation.parse(amount, ["x"])
		#evaluates equation at specified variable x
		if error != OK:
			print(equation.get_error_text())
		else:
			draw_graph()
	else:
		#amount is a number
		amount = float(amount)
		#to check: must be legit number
		#min cannot exceed max. max cannot be below min.
		match name:
			"minX":
				if amount < max_x:
					min_x = amount
				else:
					print("Invalid min_x amount")
			"maxX":
				if amount > min_x:
					max_x = amount
				else:
					print("Invalid max_x amount")
			"minY":
				if amount < max_y:
					min_y = amount
				else:
					print("Invalid min_y amount")
			"maxY":
				if amount > min_y:
					max_y = amount
				else:
					print("Invalid max_y amount")
			"stepX":
				if amount != 0:
					step_x = amount
				else: 
					print("Invalid step amount.")
			"stepY":
				if amount != 0:
					step_y = amount
				else: 
					print("Invalid step amount.")
			"deltaX":
				delta_x = amount
			"deltaXImg":
				delta_x_img = amount
		draw_axis()
		draw_graph()

#draws x and y axis at y = 0, x = 0 based on graph window size
func draw_axis():
	#clears current line
	x_axis.clear_points()
	y_axis.clear_points()
	
	calc_origin()
	
	#draw y_axis
	y_axis.add_point(Vector2(0, origin_y))
	y_axis.add_point(Vector2(get_viewport_rect().size.x, origin_y))
	
	#draw x_axis
	x_axis.add_point(Vector2(origin_x, 0))
	x_axis.add_point(Vector2(origin_x, get_viewport_rect().size.y))
	
	#changes color new line
	x_axis.default_color = color_axis
	y_axis.default_color = color_axis
	
	draw_labels()
	
#find real window location of origin
func calc_origin():
	#calculate position where x = 0 and y = 0
	origin_x = -1 * float(min_x) / (max_x - min_x) * get_viewport_rect().size.x
	origin_y = float(max_y) / (max_y - min_y) * get_viewport_rect().size.y
	
#draws graph scale lines
func draw_labels():
	#clear previous lines
	for line in (label_lines_x + label_lines_y):
		line.queue_free()
	label_lines_x = []
	label_lines_y = []

	calc_subdiv()
	#draw lines for x, i = 0 is origin
	for i in range(min_x*(1/float(step_x)) - 1, max_x*(1/float(step_x)) + 1):
		var graph_x = float(i)*step_x
		var new_line = Line2D.new()
		self.add_child(new_line)	#suggested call_deffered as repeated change makes parent busy
		#cosmetic changes. TO DO: make every nth line darker with modulus, and label graph_x.
		new_line.width = 2
		new_line.default_color = color_label_lines
		new_line.z_index = -1
		#draw scale lines parallel to y-axis
		new_line.add_point(Vector2(convert_to_window_x(graph_x), 0))
		new_line.add_point(Vector2(convert_to_window_x(graph_x), get_viewport_rect().size.y))
		#add line to array to keep track of
		label_lines_x.append(new_line)
	
	#draw lines for y
	for i in range(min_y*(1/float(step_y)) - 1, max_y*(1/float(step_y)) + 1):
		var graph_y= float(i)*step_y
		var new_line = Line2D.new()
		self.add_child(new_line)
		#cosmetic changes
		new_line.width = 2
		new_line.default_color = color_label_lines
		new_line.z_index = -1
		#draw scale lines parralel to x-axis
		new_line.add_point(Vector2(0, convert_to_window_y(graph_y)))
		new_line.add_point(Vector2(get_viewport_rect().size.x, convert_to_window_y(graph_y)))
		#add line to array to keep track of
		label_lines_y.append(new_line)
		
	#if label lines are not meant to be visible
	if (not input_visibility.get_node("label").pressed): 
		for line in (label_lines_x + label_lines_y):
			line.visible = false
	
#calculates window real_step_x and real_step_y given graph step size and window size
func calc_subdiv():
	var dif_x = abs(max_x - min_x) #number subdivisions is dif / step and 1/(subdiv) is scale
	var dif_y = abs(max_y - min_y)
	
	#calculating the amount in x, y for each graph unit step of x in terms of actual window size
	real_step_x = ( 1.0 / dif_x ) * get_viewport_rect().size.x
	real_step_y = ( 1.0 / dif_y ) * get_viewport_rect().size.y
	
#plots the graph
func draw_graph():
	#clear graph to redraw
	graph.points = []
	for tile in graph_tiles:
		tile.queue_free()
	graph_tiles = []
	
	#i = 0 is origin. I draw that extra bit beyond window to ends aren't cut off
	#(1) Draw the graph curve
	for i in range(min_x*(float(1/delta_x)) - 1, max_x*(float(1/delta_x)) + 1):
		var graph_x = float(i)*delta_x
		var graph_y = equation.execute([graph_x])
		if !equation.has_execute_failed():
			graph.add_point(Vector2(convert_to_window_x(graph_x), convert_to_window_y(graph_y)))
	
	#(2) Draw the image tiles		
	for i in range(min_x*(float(1/delta_x_img)) - 1, max_x*(float(1/delta_x_img)) + 1):
		var graph_x = float(i)*delta_x_img
		var graph_y = equation.execute([graph_x])
		if !equation.has_execute_failed():
			draw_tile(Vector2(convert_to_window_x(graph_x), convert_to_window_y(graph_y)))
		
func draw_tile(position):
	var tile = Sprite.new()
	self.add_child(tile)
	
	tile.texture = tile_img
	tile.position = position
	
	#setting to  hide images
	if not input_visibility.get_node("images").pressed:
		tile.visible = false
	
	graph_tiles.append(tile)
		
#convert between graph_x and real window pos_x:
func convert_to_window_x(graph_x):
	#calc_subdiv()
	var real_x = real_step_x*graph_x + origin_x
	return real_x
	
#convert between graph_y and real window pos_y:
func convert_to_window_y(graph_y):
	#calc_subdiv()
	var real_y = -real_step_y*graph_y + origin_y
	return real_y
