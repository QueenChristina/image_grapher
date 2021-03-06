extends Node2D

onready var x_axis = $xAxis
onready var y_axis = $yAxis
#get parameters from user
onready var input_eq = $UI/equationInput
onready var input_labels = $UI/labelInput
onready var input_colors = $UI/colors

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
var color_label_lines =  Color(0.9, 0.95, 0.98)
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

#connects line edits text inputs (press enter in line) to this
func connect_to_input():
	for child in ( input_labels.get_children() + input_eq.get_children() ):
		if child.get_class() == "LineEdit":
			child.connect("text_entered", self, "set_param", [child.get_name()])
	for child in input_colors.get_children():
		if child.get_class() == "ColorPickerButton":
			child.connect("color_changed", self, "set_color", [child.get_name()])		
			
#sets color of axis and lines
func set_color(color, name):
	print(name)
	print(color)
	match name:
		"axis":
			color_axis = color
		"labels":
			color_label_lines = color
		"graph":
			color_graph_line = color
			graph.default_color = color
	draw_axis()
			
#sets parameters based on inputs
func set_param(amount, name):
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
				min_x = amount
			"maxX":
				max_x = amount
			"minY":
				min_y = amount
			"maxY":
				max_y = amount
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
		draw_axis() #recalculate origin position first
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
		self.add_child(new_line)
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
		new_line.add_point(Vector2(get_viewport_rect().size.x, convert_to_window_y(graph_y/step_y)))
		#add line to array to keep track of
		label_lines_y.append(new_line)
	
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
