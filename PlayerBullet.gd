extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $Sprite3D.material_override.albedo_color.a
    $Sprite3D.material_override = $Sprite3D.material_override.duplicate()
    $Sprite3D2.material_override = $Sprite3D2.material_override.duplicate()
    $Sprite3D3.material_override = $Sprite3D3.material_override.duplicate()
    pass # Replace with function body.


var velocity = Vector3.FORWARD
#var radians_per_second = PI/2.0*2

#var linear_decay = 0.9
var spin_decay = 0.9

var life_time = 2.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    for _body in get_overlapping_bodies():
        var body : Node = _body
        if body.has_method("kill"):
            body.kill()
        if body.has_signal("kill"):
            body.emit_signal("kill")
            print("found signal")
        life_time = min(life_time, -1.0)
    
    var nearest_dist = 5.0
    var nearest_enemy = null
    for enemy in get_tree().get_nodes_in_group("Enemy"):
        if enemy.dead:
            continue
        var enemy_dir : Vector3 = enemy.global_transform.origin - global_transform.origin
        if velocity.normalized().dot(enemy_dir.normalized()) < 0.7:
            continue
        var angle_to = enemy_dir.angle_to(velocity)
        angle_to = 1.0 - angle_to
        var dist = enemy_dir.length()
        if dist * angle_to < nearest_dist:
            nearest_enemy = enemy
            nearest_dist = dist
    
    if nearest_enemy:
        var enemy_dir : Vector3 = nearest_enemy.global_transform.origin - global_transform.origin
        var want_vel : Vector3 = enemy_dir.normalized() * velocity.length()
        #var cross = velocity.normalized().cross(enemy_dir.normalized())
        var angle : float = velocity.angle_to(enemy_dir)
        var turn_rate = deg2rad(360.0)
        var max_angle = turn_rate * delta
        
        if angle <= max_angle:
            velocity = want_vel
        else:
            velocity = velocity.normalized().slerp(want_vel.normalized(), max_angle/angle) * velocity.length()
    
    
    life_time -= delta
    if life_time <= 0.0:
        $Sprite3D.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        $Sprite3D2.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        $Sprite3D3.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
        if life_time < -1.0:
            queue_free()
    
    rotation = Transform.IDENTITY.looking_at(velocity, Vector3.UP).basis.get_euler()
    rotation_degrees.y += 90
    
    global_transform.origin += velocity*delta
