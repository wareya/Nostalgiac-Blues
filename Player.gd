extends QuakelikeBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $Model/AnimationPlayer.get_animation("Walk").loop = true
    $Model/AnimationPlayer.get_animation("Idle").loop = true
    $Model/AnimationPlayer.get_animation("Air").loop = true
    
    var cirno_parts_visible = false
    var alice_parts_visible = true
    
    # hide cirno parts
    $Model/Armature/Skeleton/bowtie.visible = cirno_parts_visible
    $Model/Armature/Skeleton/dress.visible = cirno_parts_visible
    $Model/Armature/Skeleton/hair.visible = cirno_parts_visible
    $Model/Armature/Skeleton/ribbon.visible = cirno_parts_visible
    # show alice parts
    $"Model/Armature/Skeleton/bow alice".visible = alice_parts_visible
    $"Model/Armature/Skeleton/dress alice".visible = alice_parts_visible
    $"Model/Armature/Skeleton/hair alice".visible = alice_parts_visible
    $"Model/Armature/Skeleton/ribbon alice".visible = alice_parts_visible
    
    var next = ShaderMaterial.new()
    next.shader = preload("res://OutlineShader2.tres")
    next.render_priority = 125
    var next2 = ShaderMaterial.new()
    next2.shader = preload("res://OutlineShader.tres")
    next2.render_priority = 120
    var next3 = ShaderMaterial.new()
    next3.shader = preload("res://OutlineShader3.tres")
    next3.render_priority = 121
    next.next_pass = next2
    next2.next_pass = next3
    
    var touched = {}
    for _submodel in $Model/Armature/Skeleton.get_children():
        var submodel : MeshInstance = _submodel
        for surface in range(submodel.mesh.get_surface_count()):
            var mat : Material = submodel.mesh.surface_get_material(surface)
            if mat in touched:
                continue
            touched[mat] = null
            mat.next_pass = next
    
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.

var velocity = Vector3()
var heading = Vector2.DOWN

func get_anim_control_rate():
    if $Model/AnimationPlayer.is_playing():
        if $Model/AnimationPlayer.current_animation == "ArmSwing":
            return 0.15
    return 1.0
    

func current_anim_is_forced():
    if $Model/AnimationPlayer.is_playing():
        if $Model/AnimationPlayer.current_animation == "ArmSwing":
            return true
    return false

func play_anim(anim : String, rate = 1.0, blend = -1):
    if current_anim_is_forced():
        return
    if $Model/AnimationPlayer.current_animation != anim:
        $Model/AnimationPlayer.play(anim, blend * rate, 1.0)
    $Model/AnimationPlayer.playback_speed = rate


var jump_velocity = 10.0

var gravity = 25.0

var time_alive = 0.0
var land_time = -10.0
var land_anim_length = 0.35

var last_offset_angle = 0.0

func _process(delta):
    time_alive += delta
    gravity = 25.0
    jump_velocity = 10.0
    
    var wishdir : Vector3 = Vector3()
    if Input.is_action_pressed("ui_left"):
        wishdir.x -= 1
    elif Input.is_action_pressed("ui_right"):
        wishdir.x += 1
    if Input.is_action_pressed("ui_up"):
        wishdir.z -= 1
    elif Input.is_action_pressed("ui_down"):
        wishdir.z += 1
    
    if wishdir.length_squared() > 0:
        wishdir = wishdir.normalized()
    
    var on_floor = floor_collision != null# or hit_a_floor
    
    var jump = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("m2")
    
    var attack = Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("m1")
    
    if jump and on_floor:
        velocity.y = jump_velocity
        floor_collision = null
        on_floor = false
        play_anim("Jump", 1.0, 0.05)
    
    if attack:
        play_anim("ArmSwing", 1.0, 0.033)
    
    var accel = 100.0
    var friction = 0.000001
    var maxspeed = 6.0
    
    var groundvel = velocity
    groundvel.y = 0
    
    
    var accel_modifier = 1.0
    if hit_a_wall and !on_floor:
        accel_modifier = 0.25
    
    accel_modifier *= get_anim_control_rate()
    
    groundvel += wishdir*delta*accel*accel_modifier
    
    if on_floor:
        groundvel.x *= pow(friction, delta)
        groundvel.z *= pow(friction, delta)
    else:
        groundvel.x *= pow(friction, delta*0.25)
        groundvel.z *= pow(friction, delta*0.25)
    
    if groundvel.length_squared() > maxspeed * maxspeed:
        groundvel = groundvel.normalized()
        groundvel *= maxspeed
    
    var groundvel_v2 = Vector2(groundvel.x, groundvel.z)
    if groundvel_v2.length_squared() > 0.1:
        var chase_lookdir = Vector2(wishdir.x, wishdir.z)
        if chase_lookdir.length_squared() > 0.1:
            chase_lookdir = chase_lookdir.normalized()
            var angle_rate = 360.0*3.0 / 180.0 * PI * delta # turn rate per frame
            var dot = chase_lookdir.dot(heading)
            var anim_rate_mod = get_anim_control_rate()
            angle_rate *= anim_rate_mod
            if anim_rate_mod == 1.0 and dot > 0.7:
                angle_rate /= 3.0
            var angle_diff = heading.angle_to(chase_lookdir)
            if angle_diff < -PI*0.99:
                angle_diff += PI*2
            if angle_diff < angle_rate and angle_diff > -angle_rate:
                heading = chase_lookdir
            else:
                heading = heading.rotated(angle_rate * sign(angle_diff))
        
        var rate = groundvel_v2.length() * 0.25
        if on_floor:
            if time_alive - land_time > land_anim_length * 0.5:
                play_anim("Walk", max(0.5, rate), 0.2)
            else:
                play_anim("Walk", max(0.5, rate), 0.4)
    else:
        if on_floor and time_alive - land_time > land_anim_length:
            play_anim("Idle", 0.25, 0.2)
        pass
    
    if !on_floor and (velocity.y < 0 or !$Model/AnimationPlayer.is_playing()):
        play_anim("Air", 0.5, 0.2)
    
    var model_rotation = heading.angle()
    
    $Model.rotation.y = -model_rotation + PI/2
    
    velocity.x = groundvel.x
    velocity.z = groundvel.z
    
    var applied_gravity = -gravity
    if on_floor:
        applied_gravity *= 0.01
    
    velocity.y += applied_gravity*delta*0.5
    
    var old_on_floor = on_floor
    
    velocity = custom_move_and_slide(delta, velocity)
    
    on_floor = floor_collision != null# or hit_a_floor
    
    velocity.y += applied_gravity*delta*0.5
    
    if time_alive > 0.5 and on_floor and !old_on_floor:
        land_time = time_alive
        play_anim("Land", 1.0, 0.05)
        $Model/AnimationPlayer.seek(0.15)
    
    handle_graphical_heading(delta)

var mouse_in_screen = false
func _notification(what):
    match what:
        MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
            mouse_in_screen = false
        MainLoop.NOTIFICATION_WM_MOUSE_ENTER:
            mouse_in_screen = true
        
func handle_graphical_heading(delta):
    var asdf = get_viewport()
    
    var mouse_heading = (asdf.get_mouse_position() - asdf.size/2.0).normalized()
    #mouse_heading = mouse_heading#Vector2(mouse_heading.y, mouse_heading.x)
    
    #var offset_angle = sin(time_alive*2.0)*PI/4.0
    var offset_angle = mouse_heading.angle_to(heading)
    if !mouse_in_screen:
        offset_angle = sin(time_alive)*0.5
        
    var offset_angle_2 = fmod((fmod(offset_angle + PI, PI*2)+PI*2),PI*2) - PI
    
    
    #offset_angle_2 = clamp(offset_angle_2, -PI*0.75, PI*0.75)
    
    #var offset_angle_diff = offset_angle - offset_angle_2
    #heading = heading.rotated(-offset_angle_diff)
    
    offset_angle_2 = lerp(last_offset_angle, offset_angle_2, 1.0 - pow(0.0001, delta))
    
    last_offset_angle = offset_angle_2
    
    var skele : Skeleton = $Model/Armature/Skeleton
    var root = skele.find_bone("Bone")
    var leg_L = skele.find_bone("Bone_L.002")
    var leg_R = skele.find_bone("Bone_R.002")
    var lower_chest = skele.find_bone("Bone.002")
    var upper_chest = skele.find_bone("Bone.003")
    var neck = skele.find_bone("Bone.004")
    
    skele.clear_bones_global_pose_override()
    
    var offset_amount = -0.05
    var xform2 = Transform.IDENTITY.translated(Vector3.FORWARD * offset_amount)
    
    var xform3 = Transform.IDENTITY.rotated(Vector3.UP, offset_angle_2/(8.0))
    
    for target in [lower_chest, upper_chest, neck, root, leg_L, leg_R]:
        var xform : Transform = skele.get_bone_global_pose(target)
        if target == lower_chest or target == upper_chest:
            xform = xform2 * xform3 * xform * xform3 * xform2.inverse()
        elif target == leg_L or target == leg_R:
            xform = xform3.inverse() * xform
        elif target == root:
            xform = xform3 * xform
        else:
            xform = xform3 * xform * xform3
        skele.set_bone_global_pose_override(target, xform, 1.0, true)
    
    
