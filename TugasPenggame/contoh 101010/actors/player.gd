extends CharacterBody2D

class_name Player

@export var gravity := 750
@export var run_speed := 150
@export var sprint_speed := 300
@export var slow_speed := 75
@export var jump_speed := -300
@export var max_jumps := 2
@export var double_jump_factor := 1.5 
@export var climb_speed := 50

var jump_count := 0
var is_sprinting := false
var sprint_timer := 0.0

var is_on_ladder := false
var is_invulnerable := false
var invulnerability_timer := 0.0
var is_flying := false
var flying_timer := 0.0  # Tambahkan variabel flying_timer
var is_ghost_mode := false  # Tambahkan variabel untuk melacak Ghost Mode

enum PlayerState {IDLE, RUN, JUMP, CLIMB, HURT, DEAD, SPRINT, INVULNERABILITY, FLYING, GHOST}

var state := PlayerState.IDLE

signal life_changed
signal died

var life := 5: set = set_life

func set_life(value: int) -> void:
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(PlayerState.DEAD)

func _ready() -> void:
	change_state(PlayerState.IDLE)
	
func _physics_process(delta: float) -> void:
	if state != PlayerState.CLIMB and not is_flying and not is_ghost_mode: # Tambahkan pengecekan is_flying dan is_ghost_mode
		velocity.y += gravity * delta
	get_input(delta)
	
	move_and_slide()

	if state == PlayerState.JUMP and is_on_floor():
		change_state(PlayerState.IDLE)
		jump_count = 0
		$Dust.emitting = true
		
	if state == PlayerState.JUMP and velocity.y > 0:
		$AnimationPlayer.play("jump_down")
		
	if state == PlayerState.HURT:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider().is_in_group("danger") and not is_invulnerable:
			hurt()
		if collision.get_collider().is_in_group("enemies"):
			if position.y < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				if not is_invulnerable:
					hurt()
	
	if is_sprinting:
		sprint_timer -= delta
		if sprint_timer <= 0:
			is_sprinting = false

	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false

	if is_flying:
		flying_timer -= delta
		if flying_timer <= 0:
			is_flying = false
			change_state(PlayerState.IDLE)
			gravity = 750

func change_state(new_state: PlayerState) -> void:
	state = new_state
	match state:
		PlayerState.IDLE:
			$AnimationPlayer.play("idle")
		PlayerState.RUN:
			$AnimationPlayer.play("run")
		PlayerState.HURT:
			$HurtSound.play()
			$AnimationPlayer.play("hurt")
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			if not is_invulnerable:
				life -= 1
			await get_tree().create_timer(0.5).timeout
			change_state(PlayerState.IDLE)
		PlayerState.JUMP:
			$JumpSound.play()
			$AnimationPlayer.play("jump_up")
			jump_count = 1
		PlayerState.CLIMB:
			$AnimationPlayer.play("climb")
		PlayerState.DEAD:
			died.emit()
			hide()
		PlayerState.FLYING:
			$AnimationPlayer.play("fly")

func get_input(delta: float) -> void:
	if state == PlayerState.HURT:
		return
		
	var right := Input.is_action_pressed("right")
	var left := Input.is_action_pressed("left")
	var jump := Input.is_action_just_pressed("jump")
	var sprint := Input.is_key_pressed(KEY_K)
	var hyper_speed := Input.is_key_pressed(KEY_H)
	var invulnerability := Input.is_key_pressed(KEY_U)
	var slow := Input.is_key_pressed(KEY_O)
	var cheat_life := Input.is_key_pressed(KEY_M)
	var fly := Input.is_key_pressed(KEY_F)
	var ghost_on := Input.is_key_pressed(KEY_N)
	var ghost_off := Input.is_key_pressed(KEY_B)
	
	var up := Input.is_action_pressed("ui_up")  
	var down := Input.is_action_pressed("ui_down")  

	# Logic buat cheat life
	if cheat_life and life == 1:
		life += 1

	# Logic buat terbang
	if fly and not is_flying:
		is_flying = true
		flying_timer = 5.0  # Set timer untuk mode terbang
		change_state(PlayerState.FLYING)
		gravity = 0
	elif fly and is_flying:
		is_flying = false
		change_state(PlayerState.IDLE)
		gravity = 750

	# Logic buat ghost mode
	if ghost_on and not is_ghost_mode:
		is_ghost_mode = true
		$CollisionShape2D.disabled = true  # Menonaktifkan collision
	elif ghost_off and is_ghost_mode:
		is_ghost_mode = false
		$CollisionShape2D.disabled = false  # Mengaktifkan kembali collision

	if sprint and not is_sprinting:
		is_sprinting = true
		sprint_timer = 2.0 

	if invulnerability and not is_invulnerable:
		is_invulnerable = true
		invulnerability_timer = 5.0

	velocity.x = 0
	var speed := run_speed
	
	if slow:
		speed = slow_speed
	
	if right:
		velocity.x += sprint_speed if is_sprinting else speed
		if hyper_speed:
			velocity.x *= 2
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= sprint_speed if is_sprinting else speed
		if hyper_speed:
			velocity.x *= 2
		$Sprite2D.flip_h = true
	if jump and state == PlayerState.JUMP and jump_count < max_jumps and jump_count > 0:
		$JumpSound.play()
		$AnimationPlayer.play("jump_up")
		velocity.y = jump_speed / double_jump_factor
		jump_count += 1

	if jump and is_on_floor():
		change_state(PlayerState.JUMP)
		velocity.y = jump_speed

	if state == PlayerState.IDLE and velocity.x != 0:
		change_state(PlayerState.RUN)

	if state == PlayerState.RUN and velocity.x == 0:
		change_state(PlayerState.IDLE)

	if state in [PlayerState.IDLE, PlayerState.RUN] and not is_on_floor():
		change_state(PlayerState.JUMP)
		
	if up and state != PlayerState.CLIMB and is_on_ladder:
		change_state(PlayerState.CLIMB)
		
	if state == PlayerState.CLIMB:
		if up:
			velocity.y = -climb_speed
			$AnimationPlayer.play("climb")
		elif down:
			velocity.y = climb_speed
			$AnimationPlayer.play("climb")
		else:
			velocity.y = 0
			$AnimationPlayer.stop()

			if Input.is_action_just_released("ui_down"):
				change_state(PlayerState.IDLE)
	
	if state == PlayerState.CLIMB and not is_on_ladder:
		change_state(PlayerState.IDLE)

	if is_flying:
		if up:
			velocity.y = -run_speed
		elif down:
			velocity.y = run_speed
		else:
			velocity.y = 0

func reset(_position: Vector2):
	position = _position
	show()
	change_state(PlayerState.IDLE)
	life = 5

func hurt() -> void:
	if state != PlayerState.HURT:
		change_state(PlayerState.HURT)
