extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $Sprite3D.material_override = $Sprite3D.material_override.duplicate()
    $CSGSphere.material = $CSGSphere.material.duplicate()


export var speed = 5.0
export var direction = Vector3.FORWARD
export var radians_per_second = PI/2.0*2

export var linear_decay = 0.9
export var spin_decay = 0.9

export var life_time = 30000.0

var vertical_homing = false

func disable_world_collision():
    set_collision_mask_bit(0, false)
    pass

var paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Manager.input_mode != "gameplay":
        return
    
    if !paused:
        life_time -= delta
        if life_time <= 0.0:
            $Sprite3D.material_override.albedo_color.a = pow(clamp(life_time + 1.0, 0.0, 1.0), 2.0)
            var mat : SpatialMaterial = $CSGSphere.material
            mat.render_priority = 1
            mat.flags_transparent = true
            mat.params_cull_mode = SpatialMaterial.CULL_BACK
            mat.albedo_color.r = 0.5
            mat.albedo_color.g = 0.5
            mat.albedo_color.b = 0.5
            mat.albedo_color.a = clamp(life_time + 1.0, 0.0, 1.0)
            if life_time < -1.0:
                queue_free()
            return
    
    if life_time > 0.0:
        for body in get_overlapping_bodies():
            if body.has_method("damage"):
                body.damage(1)
            life_time = min(life_time, -0.5)
    
    if paused:
        return
    
    direction = direction.rotated(Vector3.UP, radians_per_second*delta*0.5)
    
    global_transform.origin += direction*speed*delta
    
    direction = direction.rotated(Vector3.UP, radians_per_second*delta*0.5)
    
    speed *= pow(linear_decay, delta)
    radians_per_second *= pow(spin_decay, delta)
    
    direction = direction.normalized()
