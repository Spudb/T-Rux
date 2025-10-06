extends CharacterBody2D

const gravity : int = 4200
const jump_speed : int = -1800
var jump_key_held : bool = false
var was_on_floor : bool = false

func _physics_process(delta):
	velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_key_held = true
	if Input.is_action_just_released("ui_accept"):
		jump_key_held = false
	var is_on_floor_now = is_on_floor()
	if is_on_floor_now and not was_on_floor:
		if jump_key_held:
			velocity.y = jump_speed
			$JumpinSound.play()
	if is_on_floor_now:
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCo.disabled = false
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = jump_speed
				$JumpinSound.play()
			elif Input.is_action_pressed("ui_down"):
				$AnimatedSprite2D.play("duck")
				$RunCo.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")
	was_on_floor = is_on_floor_now
	move_and_slide()
