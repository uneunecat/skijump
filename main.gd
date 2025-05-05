extends Node2D

# --- 定数 ---
const SAVE_PATH = "user://save.cfg"
const WIND_MIN_STRENGTH = 10.0  # 最小風力
const WIND_MAX_STRENGTH = 50.0  # 最大風力

# --- スコア関連 ---
var score = 0
var high_score = 0

# --- 風関連 ---
var wind_dir = 1               # 1:追い風, -1:向かい風
var wind_strength = 0.0        # 現在の風力
var _wind_elapsed_unscaled = 0.0
var _wind_interval = 0.0       # 次の切り替えまでのリアル秒数

# --- 雪関連 ---
@onready var snow_particles: CPUParticles2D = $SnowParticles

# --- start関連 ---
@onready var start_button     : Button = $CanvasLayer/StartButton
var game_started = false

func _ready():
	start_button.pressed.connect(_on_StartButton_pressed)
	randomize()
	_load_high_score()
	_update_labels()
	$CanvasLayer/GameOverUI.visible = false
	_connect_gameover_buttons()
	_randomize_wind()
	_set_next_interval()

func _process(delta):
	_update_wind(delta)

# --- 高速化した関数群 ---

func _load_high_score():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("score", "high_score", 0)

func _connect_gameover_buttons():
	var gui = $CanvasLayer/GameOverUI
	gui.get_node("RetryButton").connect("pressed", Callable(self, "_on_RetryButton_pressed"))
	gui.get_node("TitleButton").connect("pressed", Callable(self, "_on_TitleButton_pressed"))

func _randomize_wind():
	wind_dir = (1 if randi() % 2 == 0 else -1)
	wind_strength = randf_range(WIND_MIN_STRENGTH, WIND_MAX_STRENGTH)
	var arrow = "→" if wind_dir > 0 else "←"
	$CanvasLayer/WindLabel.text = "Wind: %s %d" % [arrow, int(wind_strength)]
	$CanvasLayer/WindIcon.flip_h = wind_dir < 0
	_update_snow_direction()

func _set_next_interval():
	_wind_elapsed_unscaled = 0.0
	_wind_interval = randf_range(0.5, 1.0)

func _update_wind(delta):
	var unscaled = delta / Engine.time_scale
	_wind_elapsed_unscaled += unscaled
	if _wind_elapsed_unscaled >= _wind_interval:
		_randomize_wind()
		_set_next_interval()

func _update_snow_direction():
	# 現在の下方向重力（Y成分）を取り出し
	var base_y = snow_particles.gravity.y
	# 風力に応じた水平成分を計算
	var horiz = wind_dir * wind_strength * 10
	# 重力ベクトルを更新（X が水平、Y が垂直）
	snow_particles.gravity = Vector2(horiz, base_y)

func show_game_over():
	get_tree().paused = true
	$CanvasLayer/GameOverUI.visible = true
	$CanvasLayer/GameOverUI.get_node("RetryButton").process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer/GameOverUI.get_node("TitleButton").process_mode = Node.PROCESS_MODE_ALWAYS

func add_score(points):
	score += points
	if score > high_score:
		high_score = score
		var cfg = ConfigFile.new()
		cfg.set_value("score", "high_score", high_score)
		cfg.save(SAVE_PATH)
	_update_labels()

func _update_labels():
	$CanvasLayer/ScoreLabel.text     = "Score: %d" % score
	$CanvasLayer/HighScoreLabel.text = "High Score: %d" % high_score

func _on_RetryButton_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_TitleButton_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title.tscn")

func _on_StartButton_pressed() -> void:
	# ボタンを隠して即スタート！
	start_button.visible = false
	game_started = true
	# もし Player に通知したいなら：
	var player = get_node("Player") as CharacterBody2D
	player.main_scene = self  
