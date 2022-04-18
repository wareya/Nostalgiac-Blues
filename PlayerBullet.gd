extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    #$Sprite3D.material_override.albedo_color.a
    $Sprite3D.material_override = $Sprite3D.material_override.duplicate()
    $Sprite3D2.material_override = $Sprite3D2.material_override.duplicate()
    $Sprite3D3.material_override = $Sprite3D3.material_override.duplicate()
    dodge_under(null)
    pass # Replace with function body.


var velocity = Vector3.FORWARD
#var radians_per_second = PI/2.0*2

#var linear_decay = 0.9
var spin_decay = 0.9

var life_time = 0.2
var destroys_bullets = false
func make_can_destroy_bullets():
    destroys_bullets = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Manager.input_mode != "gameplay":
        return
    
    if destroys_bullets:
        for bullet in get_tree().get_nodes_in_group("EnemyBullet"):
            var dist = global_transform.origin.distance_to(bullet.global_transform.origin)
            if dist < 0.9:
                bullet.life_time = 0.0
                EmitterFactory.emit("bulletpuff", bullet)
    
    for _body in get_overlapping_bodies():
        var body : Node = _body
        var hit_something = false
        if "health" in body:
            EmitterFactory.emit("damagedealt", body)
        if body.has_method("damage"):
            hit_something = true
            body.damage()
        if body.has_method("kill"):
            hit_something = true
            body.kill()
        if body.has_signal("kill"):
            hit_something = true
            body.emit_signal("kill")
            print("found signal")
        if !hit_something:
            EmitterFactory.emit("bulletpuff", self)
        life_time = min(life_time, 0.0)
    
    var nearest_dist = 2.0
    var nearest_enemy = null
    for enemy in get_tree().get_nodes_in_group("Enemy"):
        if "dead" in enemy and enemy.dead:
            continue
        var enemy_dir : Vector3 = enemy.global_transform.origin - global_transform.origin
        
        if velocity.normalized().dot(enemy_dir.normalized()) < 0.7:
            continue
        var angle_to = enemy_dir.angle_to(velocity)
        angle_to = 1.0 - angle_to
        #enemy_dir.y *= 2.0
        var dist = enemy_dir.length()
        if dist * angle_to < nearest_dist:
            nearest_enemy = enemy
            nearest_dist = dist
    
    if nearest_enemy:
        var enemy_dir : Vector3 = nearest_enemy.global_transform.origin - global_transform.origin
        var want_vel : Vector3 = enemy_dir.normalized() * velocity.length()
        #var cross = velocity.normalized().cross(enemy_dir.normalized())
        var angle : float = velocity.angle_to(enemy_dir)
        var turn_rate = deg2rad(180.0)
        if abs(enemy_dir.y) > 1.0:
            turn_rate *= 3.0
        var max_angle = turn_rate * delta
        
        if angle <= max_angle:
            velocity = want_vel
        else:
            velocity = velocity.normalized().slerp(want_vel.normalized(), max_angle/angle) * velocity.length()
    
    dodge_under(nearest_enemy)
    
    life_time -= delta
    if life_time <= 0.0:
        $Sprite3D.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        $Sprite3D2.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        $Sprite3D3.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        
        var particles = preload("res://BulletParticles.tscn").instance()
        get_parent().add_child(particles)
        particles.global_transform.origin = global_transform.origin
        particles.emitting = true
        queue_free()
    
    rotation = Transform.IDENTITY.looking_at(velocity, Vector3.UP).basis.get_euler()
    rotation_degrees.y += 90
    
    global_transform.origin += velocity*delta
    
    dodge_under(nearest_enemy)
    

func dodge_under(nearest_enemy):
    #$RayCast.cast_to = Vector3(0, -0.35, 0)
    $RayCast.force_raycast_update()
    if !$RayCast.is_colliding():
        return
    # pointing away from surface
    var raycast_diff = $RayCast.get_collision_point() - $RayCast.global_transform.origin
    var fraction = raycast_diff.length() / $RayCast.cast_to.length()
    var rejection_dist = ($RayCast.cast_to * (1.0 - fraction)).length()
    var rejection = $RayCast.get_collision_normal() * rejection_dist
    
    global_transform.origin += rejection
