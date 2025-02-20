extends Control

var colors = [Color.AQUA, Color.BLUE, Color.GREEN, Color.RED, Color.YELLOW]
var colors_size = colors.size()
#            tek_r_max
#            |  xy  xy  xy  xy
var tile1 = [1, 11, 12, 13, 14]
var tile2 = [4, 11, 12, 13, 23]
var tile3 = [0, 11, 12, 22, 21]
var tile4 = [4, 21, 11, 12, 13]
var tile5 = [4, 11, 12, 13, 22]
var tile6 = [2, 11, 21, 22, 32]
var tile7 = [2, 12, 22, 21, 31]
var tiles = [tile1, tile2, tile3, tile4, tile5, tile6, tile7]
var tiles_size = tiles.size()

var tek_score: int = 0 : set = set_score
var tek_x: int = 0
var tek_y: int = 0
var tek_r: int = 0
var tek_r_max: int = 0
var maybe_nodes: Array = [
	[null, null, null, null],
	[null, null, null, null],
	[null, null, null, null],
	[null, null, null, null]
]
var mutex: Mutex
var tek_nodes: Array = [
	[null, null, null, null],
	[null, null, null, null],
	[null, null, null, null],
	[null, null, null, null]
]

const start_x = -160
const start_y = -270

const max_rows = 13
const max_cols = 8

const def_x = 3
const def_y = 0

const def_size = 40

@onready var timer = $Timer
@onready var game_over = $GameOver
@onready var tiles_cube = $Tiles/Cube
@onready var control_tiles = $Tiles
@onready var score = $Score

var bits: Array = [ # 13x8
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
]

var ignore_ = false

func _ready() -> void:
	mutex = Mutex.new()
	new_game()

func _physics_process(_delta: float) -> void:
	if ignore_:
		return
	if game_over.visible:
		if Input.is_action_pressed("ui_text_newline"):
			new_game()
		return
	if Input.is_action_pressed("ui_up"):
		rotate_tile()
		return
	var old_x = tek_x
	var _x = tek_x
	if Input.is_action_pressed("ui_left"):
		_x -= 1
		if _x < 0:
			_x = 0
	if Input.is_action_pressed("ui_right"):
		_x += 1
		if _x > (max_cols - 1):
			_x = max_cols - 1
	var old_y = tek_y
	var _y = tek_y
	if Input.is_action_pressed("quick_down"):
		ignore_ = true
		timer.stop()
		var find_ground = _y
		for _q in range(_y, max_rows):
			find_ground = _q
			if !check_tile_y(_q):
				break
		for _q in range(_y, find_ground):
			tek_y = _q
			show_tile()
		await get_tree().create_timer(0.5).timeout
		timer.start()
		new_tile()
		ignore_ = false
		return
	if Input.is_action_pressed("ui_down"):
		_y += 1
		if _y > (max_rows - 1):
			_y = max_rows - 1
	if old_x != _x or old_y != _y:
		if check_tile_x(_x):
			tek_x = _x
		if check_tile_y(_y):
			tek_y = _y
		else:
			new_tile()
			return
		show_tile()

func set_score(new_score) -> void:
	tek_score = new_score
	score.text = str(tek_score)

func new_game() -> void:
	game_over.visible = false
	tek_score = 0

	for ix in range(max_cols):
		for iy in range(max_rows):
			if bits[iy][ix]:
				var node = bits[iy][ix]
				bits[iy][ix] = null
				node.visible = false
				control_tiles.remove_child(node)
				node.queue_free()

	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				var node = tek_nodes[iy][ix]
				node.visible = false
				tek_nodes[iy][ix] = null
				control_tiles.remove_child(node)
				node.queue_free()
	mutex.unlock()

	new_tile()

	timer.start()

func end_game() -> void:
	timer.stop()
	game_over.visible = true

func get_color_for_new_tile() -> Color:
	return colors[randi_range(1, colors_size) - 1]

func get_new_figure_for_tile() -> Array:
	return tiles[randi_range(1, tiles_size) - 1]

func new_tile() -> void:
	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				bits[iy + tek_y][ix + tek_x] = tek_nodes[iy][ix]
				tek_nodes[iy][ix] = null

	find_and_delete_full_lines()

	tek_x = def_x
	tek_y = def_y
	var tek_color = get_color_for_new_tile()
	var tile0 = get_new_figure_for_tile()
	tek_r = 0
	tek_r_max = tile0[0]
	for i in range(1, 5):
		var x = tile0[i] / 10 - 1
		var y = tile0[i] % 10 - 1
		var node = tiles_cube.duplicate()
		node.color = tek_color
		node.visible = true
		control_tiles.add_child(node)
		tek_nodes[y][x] = node
	mutex.unlock()

	show_tile()

	if !check_tile(tek_x, tek_y):
		end_game()

func get_full_line() -> int:
	for iy in range(max_rows, 0, -1):
		var result = 0
		for ix in range(max_cols):
			if bits[iy - 1][ix] != null:
				result += 1
		if result == max_cols:
			return iy
	return 0

func find_and_delete_full_lines() -> void:
	var del_line = 1
	while del_line:
		del_line = get_full_line()
		if del_line:
			tek_score += 1
			for ix in range(max_cols):
				var node = bits[del_line - 1][ix]
				bits[del_line - 1][ix] = null
				node.visible = false
				node.queue_free()
			if del_line == max_rows:
				bits.resize(max_rows - 1)
			else:
				bits.remove_at(del_line - 1)
			var new_line = []
			new_line.resize(max_cols)
			new_line.fill(null)
			bits.push_front(new_line)
			for iy in range(del_line):
				for ix in range(max_cols):
					var node = bits[iy][ix]
					if node:
						node.position.y += def_size

func rotate_tile() -> void:
	if tek_r_max == 0:
		return

	for ix in range(4):
		for iy in range(4):
			maybe_nodes[iy][ix] = null

	if tek_r_max == 1:
		mutex.lock()
		var rotates = [ [0, 1, 1, 0], [0, 2, 2, 0], [0, 3, 3, 0], [0, 0, 0, 0] ]
		for np in rotates:
			if tek_r == 0:
				maybe_nodes[np[3]][np[2]] = tek_nodes[np[1]][np[0]]
			else:
				maybe_nodes[np[1]][np[0]] = tek_nodes[np[3]][np[2]]
		if check_maybe(tek_x, tek_y, maybe_nodes):
			if tek_r == 0:
				tek_r = 90
			else:
				tek_r = 0
			for ix in range(4):
				for iy in range(4):
					tek_nodes[iy][ix] = maybe_nodes[iy][ix]
			mutex.unlock()
			show_tile()
		else:
			mutex.unlock()

	if tek_r_max == 4:
		mutex.lock()
		var rotates = [
			[0, 0, 2, 0], [1, 0, 2, 1], [2, 0, 2, 2], [2, 1, 1, 2],
			[2, 2, 0, 2], [1, 2, 0, 1], [0, 2, 0, 0], [0, 1, 1, 0],
			[1, 1, 1, 1]
		]
		for np in rotates:
			maybe_nodes[np[3]][np[2]] = tek_nodes[np[1]][np[0]]
		if check_maybe(tek_x, tek_y, maybe_nodes):
			for ix in range(3):
				for iy in range(3):
					tek_nodes[iy][ix] = maybe_nodes[iy][ix]
			mutex.unlock()
			show_tile()
		else:
			mutex.unlock()

	if tek_r_max == 2:
		mutex.lock()
		var rotates = [
			[2, 0, 0, 0], [2, 1, 1, 0], [0, 1, 1, 2], [0, 0, 0, 2],
			[1, 0, 0, 1], [1, 1, 1, 1]
		]
		for np in rotates:
			if tek_r == 0:
				maybe_nodes[np[3]][np[2]] = tek_nodes[np[1]][np[0]]
			else:
				maybe_nodes[np[1]][np[0]] = tek_nodes[np[3]][np[2]]
		if check_maybe(tek_x, tek_y, maybe_nodes):
			if tek_r == 0:
				tek_r = 90
			else:
				tek_r = 0
			for ix in range(3):
				for iy in range(3):
					tek_nodes[iy][ix] = maybe_nodes[iy][ix]
			mutex.unlock()
			show_tile()
		else:
			mutex.unlock()

func show_tile() -> void:
	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				tek_nodes[iy][ix].position.x = start_x + def_size * (ix + tek_x)
				tek_nodes[iy][ix].position.y = start_y + def_size * (iy + tek_y)
	mutex.unlock()

func check_tile_x(new_x) -> bool:
	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				if (ix + new_x) >= max_cols:
					mutex.unlock()
					return false
				if bits[iy + tek_y][ix + new_x] != null:
					mutex.unlock()
					return false
	mutex.unlock()
	return true

func check_tile_y(new_y) -> bool:
	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				if (iy + new_y) >= max_rows:
					mutex.unlock()
					return false
				if bits[iy + new_y][ix + tek_x] != null:
					mutex.unlock()
					return false
	mutex.unlock()
	return true

func check_tile(new_x, new_y) -> bool:
	mutex.lock()
	for ix in range(4):
		for iy in range(4):
			if tek_nodes[iy][ix]:
				if (ix + new_x) >= max_cols:
					mutex.unlock()
					return false
				if (iy + new_y) >= max_rows:
					mutex.unlock()
					return false
				if bits[iy + new_y][ix + new_x] != null:
					mutex.unlock()
					return false
	mutex.unlock()
	return true

func check_maybe(new_x, new_y, maybe_nodes_) -> bool:
	for ix in range(4):
		for iy in range(4):
			if maybe_nodes_[iy][ix]:
				if (ix + new_x) >= max_cols: return false
				if (iy + new_y) >= max_rows: return false
				if bits[iy + new_y][ix + new_x] != null: return false
	return true

func _on_timer_timeout() -> void:
	if ignore_:
		return
	if !check_tile(tek_x, tek_y + 1):
		new_tile()
		return
	tek_y += 1
	show_tile()
