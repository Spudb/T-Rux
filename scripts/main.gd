extends Node

var barrel_scene = preload("res://scenes/barrel.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var vulture_scene = preload("res://scenes/vulture.tscn")
var obstacle_types := [barrel_scene, rock_scene]
var obstacles : Array
var vulture_heights := [300, 470]
var difficulty
var score : int
var speed : float
var high_score : int
var screen_size : Vector2i
var ground_height : int
var time_accumulator = 0
@onready var timer: Timer = $Timer
@onready var bg: ParallaxBackground = $Bg
var game_running : bool
var last_obs

const dino_start_pos := Vector2i(150, 485)
const cam_start_pos := Vector2i(576, 324)
const max_difficulty : int = 2
const score_modifier : int = 1
const start_speed : float = 0.3
const max_speed : float = 0.625
const speed_modifier : int = 150

func _ready():
	add_child(timer)
	timer.wait_time = 1
	timer.one_shot = false
	timer.start()
	
	screen_size = get_window().size
	ground_height = $Ground.get_node("TextureRect").texture.get_height()
	$Restart.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	score = 0
	speed = start_speed
	show_score() 
	difficulty = 0
	game_running = false
	get_tree().paused = false
	$Dino.jump_key_held = false
	
	for i in range(obstacles.size() - 1, -1, -1):
		if is_instance_valid(obstacles[i]):
			obstacles[i].queue_free()
	obstacles.clear()
	
	$Dino.position = dino_start_pos
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = cam_start_pos
	$Ground.position = Vector2i(0, 0)
	$Bg.scroll_offset = Vector2(0, 0)
	last_obs = null
	
	$HUD.get_node("StartLabel").show()
	$Restart.hide()

func _process(delta):
	if game_running:
		var movement = speed
		
		generate_obs()
		for obs in obstacles:
			obs.position.x -= movement
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		$Ground.position.x -= movement
		$Bg.scroll_offset.x -= movement * 0.8
		if $Ground.position.x <= -screen_size.x:
			$Ground.position.x = 0
		if $Bg.scroll_offset.x <= -screen_size.x:
			$Bg.scroll_offset.x = 0
		if speed < max_speed:
			speed = start_speed + (score * 0.001)
		else: 
			speed = max_speed
		adjust_difficulty()
		print(speed)
		
		time_accumulator += delta
		if time_accumulator >= 0.13:
			score += score_modifier
			time_accumulator = 0
		score += speed
		show_score()
		
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()
	var target_x = $Dino.position.x + 200
	$Camera2D.position.x = lerp($Camera2D.position.x, target_x, 0.1)

func generate_obs():
	var camera_right_edge = $Camera2D.position.x + (screen_size.x / 2)
	var min_gap = 400 + (difficulty * 50)
	var max_gap = 1200 - (difficulty * 100)
	var random_gap = randi_range(min_gap, max_gap)
	var should_spawn = false
	
	if obstacles.is_empty():
		should_spawn = true
	else:
		var rightmost_obs_x = 0
		for obs in obstacles:
			if obs.position.x > rightmost_obs_x:
				rightmost_obs_x = obs.position.x
		if rightmost_obs_x < camera_right_edge - random_gap:
			should_spawn = true
	if should_spawn:
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		if max_obs > 2:
			max_obs = 2
		var num_obs = randi() % max_obs + 1
		var min_spacing = 250 + (speed * 100) 
	
		for i in range(num_obs):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			
			var base_x_offset = randi_range(200, 500)
			var obs_x : int = camera_right_edge + base_x_offset + (i * min_spacing)
			if obs_x > camera_right_edge + screen_size.x * 0.8:
				break
			var obs_y : int = screen_size.y - ground_height - (obs_height + obs_scale.y / 2) - 156
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		if difficulty == max_difficulty:
			if (randi() % 2) == 0:
				obs = vulture_scene.instantiate()
				var obs_x : int = screen_size.x + camera_right_edge 
				var obs_y : int = vulture_heights[randi() % vulture_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	if is_instance_valid(obs):
		obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "Dino":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "Score: " + str(score)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "High Score: " + str(high_score / score_modifier)

func adjust_difficulty():
	difficulty = score / speed_modifier
	if difficulty > max_difficulty:
		difficulty = max_difficulty

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$Restart.show()
