extends RigidBody2D

enum ANIMAL_STATE { READY, DRAG, RELEASE}

var _state: ANIMAL_STATE = ANIMAL_STATE.READY

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	update(delta)
	

func update_drag():
	var gmp = get_global_mouse_position()
	position = gmp



func update(delta: float):
	pass
	
	
	

func die():
	SignalManager.on_animal_died.emit()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	die()


func _on_input_event(viewport, event, shape_idx):
	pass # Replace with function body.
