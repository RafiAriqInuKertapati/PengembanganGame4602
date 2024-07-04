extends CharacterBody2D

class_name Enemy

@export var speed := 50
@export var gravity := 900
@export var jump_force := 400
@export var jump_interval := 2.0  # Interval lompat dalam detik

var facing := 1
var time_since_last_jump := 0.0

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.x = facing * speed
	$Sprite2D.flip_h = velocity.x > 0

	# Logika untuk melompat
	time_since_last_jump += delta
	if time_since_last_jump >= jump_interval and is_on_floor():
		velocity.y = -jump_force
		time_since_last_jump = 0.0

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider().name == "Player":	
			collision.get_collider().hurt()
		if collision.get_normal().x != 0:
			facing = sign(collision.get_normal().x)
			velocity.y = -100

	if position.y > 10000:
		queue_free()

func take_damage() -> void:
	$HitSound.play()
	$AnimationPlayer.play("death")
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()
