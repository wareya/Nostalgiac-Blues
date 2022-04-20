extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"



var mats = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    $Model/AnimationPlayer.get_animation("Idle").loop = true
    $Model/AnimationPlayer.play("Idle")
    
    for _submodel in get_node("Model/Armature/Skeleton").get_children():
        var submodel : MeshInstance = _submodel
        submodel.mesh = submodel.mesh.duplicate()
        for surface in range(submodel.mesh.get_surface_count()):
            var mat : SpatialMaterial = submodel.mesh.surface_get_material(surface)
            if mat in mats:
                continue
            
            var newmat = Manager.make_shattery_mat(mat)
            submodel.set_surface_material(surface, newmat)
            mats[newmat] = null


var velocity = Vector3()
var speed = 3.5

var gravity = 10

var dead = false
var death_anim = 0.0

func reset_pose():
    for bone_id in $Model/Armature/Skeleton.get_bone_count():
        $Model/Armature/Skeleton.set_bone_pose(bone_id, Transform.IDENTITY)

var health = 1.0

func kill():
    if dead:
        return
    $Model/AnimationPlayer.stop()
    reset_pose()
    dead = true
    death_anim = 0.0
    EmitterFactory.emit("enemydeath", self)
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Manager.input_mode != "gameplay":
        return
    
    if dead:
        $CollisionShape.disabled = true
        death_anim += delta
        for _mat in mats.keys():
            var mat : ShaderMaterial = _mat
            mat.set_shader_param("shatterment", death_anim)
            mat.set_shader_param("scale", $Model.scale)
        if death_anim > 3.0:
            queue_free()
        return
    
    for i in get_slide_count():
        var collision : KinematicCollision = get_slide_collision(i)
        var body = collision.collider
        if body and body.has_method("damage"):
            var dealt = body.damage(1)
            if dealt:
                dead = true
                break
    
    var player : Spatial = Manager.find_player()
    var dist_diff = Vector3()
    if player:
        dist_diff = player.global_transform.origin - global_transform.origin
    #dist_diff.y = 0
    if velocity.length() < speed*0.8 and dist_diff.length() > 7.0:
        player = null
    
    var player_height_diff = 0.0
    
    if player:
        var player_dir : Vector3 = player.global_transform.origin - global_transform.origin
        player_height_diff = player_dir.y
        player_dir.y = 0
        var want_vel : Vector3 = player_dir.normalized() * speed
        #var cross = velocity.normalized().cross(player_dir.normalized())
        var v2 = velocity
        v2.y = 0
        if v2.length() < 0.1:
            v2 = Vector3.BACK
        #print(v2)
        var angle : float = v2.angle_to(player_dir)
        var turn_rate = deg2rad(360.0)
        var max_angle = turn_rate * delta
        
        if angle <= max_angle:
            v2 = want_vel
        else:
            v2 = v2.normalized().slerp(want_vel.normalized(), max_angle/angle) * v2.length()
        
        v2 = v2.normalized() * speed
        
        velocity.x = v2.x
        velocity.z = v2.z
            
    #var dir = dist_diff.normalized()
    
    #velocity.x = dir.x * speed
    #velocity.z = dir.z * speed
    
    var vert_speed = 1.0
    
    var raycast_distance = ($RayCast.get_collision_point() - $RayCast.global_transform.origin).length()
    #print(raycast_distance)
    if raycast_distance > 1.0 and player_height_diff < 1.0:
        velocity.y = lerp(velocity.y, -vert_speed, 1.0 - pow(0.0001, delta))
    else:
        velocity.y = lerp(velocity.y, vert_speed, 1.0 - pow(0.0001, delta))
    
    var new_velocity = move_and_slide(velocity, Vector3.UP, false, 4, 0.785398, false)
    velocity.y = new_velocity.y
    
    var v2 = velocity
    v2.y = 0
    if v2.length_squared() > 0.1:
        rotation.y = Vector3.BACK.signed_angle_to(v2, Vector3.UP)
    
    
    #rotation.y
    pass
