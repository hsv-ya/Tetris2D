extends Control

var colors = [Color.AQUA, Color.BLUE, Color.GREEN, Color.RED, Color.YELLOW]
var tile1 = [14, 11, 12, 13, 14]
var tile2 = [23, 11, 12, 13, 23]
var tile3 = [22, 11, 12, 22, 21]
var tile4 = [23, 21, 11, 12, 13]
var tile5 = [23, 11, 12, 13, 22]
var tiles = [tile1, tile2, tile3, tile4, tile5]

var nul_tile = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var tek_tile = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var tek_color: Color
var tek_x: int = 0
var tek_y: int = 0
var tek_w: int = 0
var tek_h: int = 0
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

const def_x = 2
const def_y = 0

const def_size = 40

@onready var timer = $Timer
@onready var game_over = $GameOver
@onready var tiles_cube = $Tiles/Cube
@onready var control_tiles = $Tiles

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

func _ready() -> void:
	new_game()

func _process(_delta: float) -> void:
#func _physics_process(_delta: float) -> void:
	if timer.is_stopped():
		if Input.is_action_pressed("ui_text_newline"):
			new_game()
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

func new_game() -> void:
	game_over.visible = false

	for ix in range(0, max_cols):
		for iy in range(0, max_rows):
			if bits[iy][ix]:
				var node = bits[iy][ix]
				bits[iy][ix] = null
				control_tiles.remove_child(node)
				node.queue_free()

	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_nodes[ix][iy]:
				var node = tek_nodes[ix][iy]
				tek_nodes[ix][iy] = null
				control_tiles.remove_child(node)
				node.queue_free()

	new_tile()

	timer.start()

func end_game() -> void:
	timer.stop()
	game_over.visible = true

func new_tile() -> void:
	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_tile[ix][iy]:
				bits[iy + tek_y][ix + tek_x] = tek_nodes[ix][iy]
				tek_nodes[ix][iy] = null
			tek_tile[ix][iy] = 0

	tek_x = def_x
	tek_y = def_y
	tek_color = colors[randi() % 5]
	var tile0 = tiles[randi() % 5]
	tek_w = tile0[0] % 10
	tek_h = tile0[0] / 10
	tek_tile = nul_tile.duplicate()
	for i in range(1, 5):
		var x = tile0[i] / 10 - 1
		var y = tile0[i] % 10 - 1
		tek_tile[x][y] = 1
		var node = tiles_cube.duplicate()
		node.color = tek_color
		node.visible = true
		control_tiles.add_child(node)
		tek_nodes[x][y] = node

	show_tile()

	if !check_tile(tek_x, tek_y):
		end_game()

func show_tile() -> void:
	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_tile[ix][iy]:
				tek_nodes[ix][iy].position.x = start_x + def_size * (ix + tek_x)
				tek_nodes[ix][iy].position.y = start_y + def_size * (iy + tek_y)

func check_tile_x(new_x) -> bool:
	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_tile[ix][iy]:
				if (ix + new_x) >= max_cols: return false
				if bits[iy + tek_y][ix + new_x] != null: return false
	return true

func check_tile_y(new_y) -> bool:
	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_tile[ix][iy]:
				if (iy + new_y) >= max_rows: return false
				if bits[iy + new_y][ix + tek_x] != null: return false
	return true

func check_tile(new_x, new_y) -> bool:
	for ix in range(0, 4):
		for iy in range(0, 4):
			if tek_tile[ix][iy]:
				if (ix + new_x) >= max_cols: return false
				if (iy + new_y) >= max_rows: return false
				if bits[iy + new_y][ix + new_x] != null: return false
	return true

func _on_timer_timeout() -> void:
	if !check_tile_y(tek_y + 1):
		new_tile()
		return
	tek_y += 1
	show_tile()
