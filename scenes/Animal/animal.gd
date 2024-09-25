extends RigidBody2D

enum ANIMAL_STATE { READY, DRAG, RELEASE}

const DRAG_LIMIT_MAX: Vector2 = Vector2(0, 60)
const DRAG_LIMIT_MIN: Vector2 = Vector2(-60, 0)
const IMPULSE_MULT: float = 20.0
const IMPULSE_MAX: float = 1200.0

var _start: Vector2 = Vector2.ZERO
var _drag_start: Vector2 = Vector2.ZERO
var _dragged_vector: Vector2 = Vector2.ZERO
var _last_dragged_vector: Vector2 = Vector2.ZERO
var _state: ANIMAL_STATE = ANIMAL_STATE.READY
var _arrow_scale_x: float = 0.0
var _last_colision_count: int = 0

@onready var label = $Label
@onready var strech_sound = $StrechSound
@onready var arrow = $Arrow
@onready var launch_sound = $LaunchSound
@onready var kick_sound = $KickSound

# Called when the node enters the scene tree for the first time.
func _ready():
	_arrow_scale_x = arrow.scale.x
	arrow.hide()
	_start = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	update(delta)
	label.text = "%s\n" % ANIMAL_STATE.keys()[_state]
	label.text += "%.1f,%.1f" % [_dragged_vector.x, _dragged_vector.y]
	
func get_impluse():
	return _dragged_vector * -1 * IMPULSE_MULT
	
func set_release():
	arrow.hide()
	freeze = false
	apply_central_impulse(get_impluse())
	launch_sound.play()
	SignalManager.on_attempt_made.emit()
	
func set_drag():
	_drag_start = get_global_mouse_position()
	arrow.show()
	
	
func set_new_state(new_state: ANIMAL_STATE):
	_state = new_state
	if _state == ANIMAL_STATE.RELEASE:
		set_release()
	elif _state == ANIMAL_STATE.DRAG:
		set_drag()
	
func detect_release():
	if _state == ANIMAL_STATE.DRAG:
		if Input.is_action_just_released("drag") == true:
			set_new_state(ANIMAL_STATE.RELEASE)
			return true
	return false
	
func scale_arrow():
	var imp_len = get_impluse().length()
	var perc = imp_len / IMPULSE_MAX
	arrow.scale.x = (_arrow_scale_x * perc) + _arrow_scale_x
	arrow.rotation = (_start - position).angle()
	
	
func play_strech_sound():
	if (_last_dragged_vector - _dragged_vector).length() > 0:
		if strech_sound.playing == false:
			strech_sound.play()
	
func get_dragged_vector(gmp: Vector2):
	return gmp - _drag_start
	
func drag_in_limit():
	_last_dragged_vector = _dragged_vector
	
	_dragged_vector.x = clampf(
		_dragged_vector.x,
		DRAG_LIMIT_MIN.x,
		DRAG_LIMIT_MAX.x
	)
	_dragged_vector.y = clampf(
		_dragged_vector.y,
		DRAG_LIMIT_MIN.y,
		DRAG_LIMIT_MAX.y
	)
	position = _start + _dragged_vector
	
func update_drag():
	
	if detect_release() == true:
		return 
	
	var gmp = get_global_mouse_position()
	_dragged_vector = get_dragged_vector(gmp)
	play_strech_sound()
	drag_in_limit()
	scale_arrow()

func update_flight():
	play_colision()
	
func play_colision():
	if 	(_last_colision_count == 0 and
		get_contact_count() > 0 and 
		kick_sound.playing == false):
			kick_sound.play()
	_last_colision_count = get_contact_count()


func update(delta: float):
	match _state:
		ANIMAL_STATE.DRAG:
			update_drag()
		ANIMAL_STATE.RELEASE:
			update_flight()
	
func die():
	SignalManager.on_animal_died.emit()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	die()


func _on_input_event(viewport, event, shape_idx):
	if _state == ANIMAL_STATE.READY and event.is_action_pressed("drag"):
		set_new_state(ANIMAL_STATE.DRAG)	


func _on_sleeping_state_changed():
	if sleeping == true:
		var cb = get_colliding_bodies()
		if cb.size() > 0:
			cb[0].die()
		call_deferred("die")
