extends Control

# スティックが動ける範囲（Background の半径）
var radius: float
# 出力ベクトル（‐1.0〜+1.0）
var stick_vector := Vector2.ZERO

@onready var bg     : TextureRect = $Background
@onready var handle : TextureRect = $Handle

func _ready():
	# 背景テクスチャの幅の半分が半径
	radius = bg.size.x * 0.5
	# ハンドルは背景の中心に
	handle.position = bg.position + (bg.size - handle.size) * 0.5

func _gui_input(event):
	# タッチ開始 or ドラッグ中
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventScreenDrag):
		_update_stick(event.position)
	# タッチ終了
	elif event is InputEventScreenTouch and not event.pressed:
		stick_vector = Vector2.ZERO
		handle.position = bg.position + (bg.size - handle.size) * 0.5

func _update_stick(local_click: Vector2) -> void:
	# local_click はこの Control のローカル座標
	# 1) 背景の左上を原点とした座標系に移す
	var p = local_click - bg.position
	# 2) 中心を (0,0) にする
	var offset = p - bg.size * 0.5
	# 3) はみ出したら clamp
	if offset.length() > radius:
		offset = offset.normalized() * radius
	# 4) -1..1 の範囲に正規化
	stick_vector = offset / radius
	# 5) handle の描画位置を更新
	handle.position = bg.position + bg.size * 0.5 + offset
