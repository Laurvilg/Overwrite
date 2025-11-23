extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $anim
@onready var hit_right: Area2D = $ColAtaque2/HitRight
@onready var hit_left: Area2D  = $ColAtaque2/HitLeft
@onready var hit_up: Area2D    = $ColAtaque2/HitUp
@onready var hit_down: Area2D  = $ColAtaque2/HitDown
@onready var hurtbox: Area2D   = $Hurtbox

var is_dead := false
var speed := 200.0  #Aqui se modifica la velocidad del personaje, LAS DEMAS COSAS AFECTAN AL ATAQUE Y MOVIMIENTO WASD (NO TOCAR)
var last_direction := "down"
var atacar := false

func _enable_hitbox(dir: String, enabled: bool) -> void:
	# apaga todo
	hit_right.monitoring = false
	hit_left.monitoring  = false
	hit_up.monitoring    = false
	hit_down.monitoring  = false
	# enciende uno
	if enabled:
		match dir:
			"right": hit_right.monitoring = true
			"left":  hit_left.monitoring  = true
			"up":    hit_up.monitoring    = true
			"down":  hit_down.monitoring  = true

func _physics_process(delta):
	if is_dead:
		return  # detiene todo si el jugador está muerto
	if !atacar:
		get_input()
		if Input.is_action_just_pressed("atacar"):
			atacar = true
			attack() # <- lanza el ataque una vez
		move_and_slide()

func attack() -> void:
	velocity = Vector2.ZERO
	var anim_name: String = "attack_" + last_direction
	_enable_hitbox(last_direction, true)   # ← ENCENDER hitbox
	if anim.sprite_frames.has_animation(anim_name):
		anim.sprite_frames.set_animation_loop(anim_name, false)
		anim.frame = 0
		anim.play(anim_name)
		await anim.animation_finished
	else:
		printerr("No existe la animación: ", anim_name)
	_enable_hitbox(last_direction, false)  # ← APAGAR hitbox
	atacar = false

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
	if abs(input_direction.x) > abs(input_direction.y):
		last_direction = "right" if input_direction.x > 0 else "left"
	else:
		last_direction = "down" if input_direction.y > 0 else "up"
	update_animation("run")
	velocity = input_direction * speed

func update_animation(state):
	anim.play(state + "_" + last_direction)

func _on_hit_area_entered(area: Area2D) -> void:
	# debug: ¿está llegando?
	print("hit area:", area.name)
	if area.is_in_group("enemy_hurtbox"):
		var enemy := area.get_parent()  # o area.owner según tu escena
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(1)
			print("💥 daño enviado a:", enemy.name)

# --- Recibir daño del enemigo (PASO 3) ---
var hp := 100
var invulnerable := false
var i_frames := 1.0

func take_damage(amount: int) -> void:
	if invulnerable or is_dead:
		return

	hp -= amount
	if hp < 0: hp = 0
	print("💥 Player recibió", amount, "de daño. HP:", hp)
	
	var attacker = get_tree().get_first_node_in_group("enemy")
	if attacker:
		var direction = (global_position - attacker.global_position).normalized()
		global_position += direction * 16  # Ajusta la fuerza según tu juego
	# Anim de daño direccional si existe
	var dmg_name := "daño_" + last_direction
	if anim.sprite_frames.has_animation(dmg_name):
		anim.sprite_frames.set_animation_loop(dmg_name, false)
		anim.frame = 0
		anim.play(dmg_name)

	# i-frames visuales
	invulnerable = true
	anim.modulate = Color(1, 0.6, 0.6)
	await get_tree().create_timer(i_frames).timeout
	anim.modulate = Color(1, 1, 1)
	invulnerable = false

	if hp <= 0 and not is_dead:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	atacar = false

	# Apaga hurtbox e hitboxes para que no entren más golpes
	if is_instance_valid(hurtbox):
		hurtbox.monitoring = false
	_enable_hitbox(last_direction, false)

	# Anim de muerte (ajusta el nombre si usas otra)
	var death_name := "muerte"
	if anim.sprite_frames.has_animation(death_name):
		anim.sprite_frames.set_animation_loop(death_name, false)
		anim.frame = 0
		anim.play(death_name)
		await anim.animation_finished
	
	SceneTransitions.change_scene_to_file("res://inicio/again.tscn")
	print("💀 Player ha muerto")
	# despues muestra pantalla de muerte y reiniciods


func _on_lupa_button_pressed() -> void:
	AudioManager.SFXPlayer.stream = preload("res://inicio/audio/button-305770.mp3")
	AudioManager.SFXPlayer.play()
	SceneTransitions.change_scene_to_file("res://inicio/quehacer2.tscn")
	
