extends CharacterBody2D

#――――――――――――――――――
# 定数
#――――――――――――――――――
const GRAVITY         = 800
const SLIDE_FORCE     = 300
const JUMP_FORCE      = -200
const AIR_LIFT_FORCE  = 300
const AIR_SLOWMO      = 0.2
const WIND_CTRL_SPEED = 300

const LANDING_FORCE   = 800
const LANDING_SCORE   = 500
const LANDING_PENALTY = 500

const THRESHOLD       = 0.5

#――――――――――――――――――
# 状態フラグ
#――――――――――――――――――
var can_jump      = false
var can_land      = false
var in_wind       = false
var has_jumped    = false
var has_landed    = false
var is_game_over  = false

var was_in_air    = false
var jump_start_x  = 0.0

#――――――――――――――――――
# 入力ワンショット制御
#――――――――――――――――――
var _start_used   = false
var _jump_used    = false
var _land_used    = false

#――――――――――――――――――
# ノード参照用
#――――――――――――――――――
var main_scene
var joystick
var start_button
var good_label
var landing_state_label
var wind_icon

var jump_zone
var wind_zone
var landing_zone

func _ready():
	# ———— ノード取得 ————
	main_scene          = get_tree().current_scene
	joystick            = main_scene.get_node("CanvasLayer/VirtualJoystick")
	start_button        = main_scene.get_node("CanvasLayer/StartButton")
	good_label          = main_scene.get_node("CanvasLayer/GoodLabel")
	landing_state_label = main_scene.get_node("CanvasLayer/LandingStateLabel")
	wind_icon           = main_scene.get_node("CanvasLayer/WindIcon")

	jump_zone    = get_parent().get_node("JumpZone")    as Area2D
	wind_zone    = get_parent().get_node("WindZone")    as Area2D
	landing_zone = get_parent().get_node("LandingZone") as Area2D

	# ———— シグナル接続 ————
	jump_zone.body_entered.connect   (_on_jump_zone_entered)
	jump_zone.body_exited.connect    (_on_jump_zone_exited)
	wind_zone.body_entered.connect   (_on_wind_zone_entered)
	wind_zone.body_exited.connect    (_on_wind_zone_exited)
	landing_zone.body_entered.connect(_on_landing_zone_entered)
	landing_zone.body_exited.connect (_on_landing_zone_exited)

	start_button.pressed.connect(_on_start_pressed)

	# 初期化
	Engine.time_scale = 1.0
	was_in_air = false

func _on_start_pressed():
	if not main_scene.game_started and not _start_used:
		_start_used = true
		start_button.visible = false
		main_scene.game_started = true

func _perform_jump(auto=false):
	if not auto:
		velocity.y = JUMP_FORCE
	can_jump    = false
	has_jumped  = true
	Engine.time_scale = AIR_SLOWMO

func _physics_process(delta):
	# 1) 入力取得（キーボード or ジョイスティック）
	var joy    = joystick.stick_vector
	var inp_up    = Input.is_action_just_pressed("ui_up")   or joy.y < -THRESHOLD
	var inp_down  = Input.is_action_just_pressed("ui_down") or joy.y >  THRESHOLD
	var inp_left  = Input.is_action_pressed("ui_left")      or joy.x < -THRESHOLD
	var inp_right = Input.is_action_pressed("ui_right")     or joy.x >  THRESHOLD

	# 2) ゲーム開始前の待機
	if not main_scene.game_started:
		if inp_down:
			_on_start_pressed()
		return

	# 3) 重力＋スロープ滑走
	velocity.y += GRAVITY * delta
	if is_on_floor():
		var n = get_floor_normal()
		var dir = Vector2(-n.y, n.x).normalized()
		velocity.x += dir.x * SLIDE_FORCE * delta
		velocity.x = max(velocity.x, 0)
		$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, n.angle() + PI/2, 5 * delta)
	else:
		$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, 0, 5 * delta)

	# 4) 風＆揚力
	if not is_on_floor() and has_jumped:
		var against = (main_scene.wind_dir > 0 and inp_left) or (main_scene.wind_dir < 0 and inp_right)
		good_label.visible = against
		if against:
			velocity.y -= AIR_LIFT_FORCE * delta
	else:
		good_label.visible = false
		var wind_eff = main_scene.wind_dir * main_scene.wind_strength * delta
		velocity.x += wind_eff
		velocity.x = max(velocity.x, 0)

	# 5) ジャンプ判定
	if can_jump and is_on_floor():
		if inp_up and not _jump_used:
			_jump_used = true
			_perform_jump()
	else:
		_jump_used = false

	# 6) 着地入力判定
	if can_land:
		if inp_down and not _land_used:
			_land_used = true
			_on_successful_landing()
	else:
		_land_used = false

	# 7) 移動＆着地検出
	move_and_slide()
	var on_floor = is_on_floor()
	if was_in_air and on_floor and has_jumped:
		Engine.time_scale = 1.0
		has_landed = true
		main_scene.add_score(int((global_position.x - jump_start_x) * 10))
	was_in_air = not on_floor

	# 8) 画面外でゲームオーバー
	if has_landed and not is_game_over:
		var rect = get_viewport().get_visible_rect()
		if not rect.has_point(global_position):
			is_game_over = true
			main_scene.show_game_over()

func _on_successful_landing():
	Engine.time_scale = 1.0
	main_scene.add_score(LANDING_SCORE)
	velocity.y = LANDING_FORCE
	landing_state_label.text    = "Success"
	landing_state_label.visible = true
	wind_icon.visible = true
	can_land = false

#――――――――――――――――――
func _on_jump_zone_entered(body):
	if body == self:
		can_jump = true

func _on_jump_zone_exited(body):
	if body == self:
		if can_jump:
			_perform_jump(true)
		can_jump = false

func _on_wind_zone_entered(body):
	if body == self:
		in_wind = true

func _on_wind_zone_exited(body):
	if body == self:
		in_wind = false

func _on_landing_zone_entered(body):
	if body == self:
		can_land = true
		wind_icon.visible = false
		landing_state_label.text    = "Landing"
		landing_state_label.visible = true

func _on_landing_zone_exited(body):
	if body == self:
		if can_land:
			landing_state_label.text = "Failure"
			main_scene.add_score(-LANDING_PENALTY)
		can_land = false
		wind_icon.visible = true
