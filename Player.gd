extends QuakelikeBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var mats = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    $Aimer/Grimoire/AnimationPlayer.get_animation("Idle").loop = true
    $Aimer/Grimoire/AnimationPlayer.play("Idle")
    
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
    
    for _submodel in $Model/Armature/Skeleton.get_children():
        var submodel : MeshInstance = _submodel
        for surface in range(submodel.mesh.get_surface_count()):
            var mat : Material = submodel.mesh.surface_get_material(surface)
            if mat in mats:
                continue
            mats[mat] = null
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

onready var old_origin = transform.origin

var bullet_time_amount = 6.0/60.0
var bullet_timer = bullet_time_amount
var bullets_fired = 0.0

# (x-0.25)*(1/0.75) / (1 - 0.25/0.75)
func deadzone_clamp(x : float, lower : float, upper : float):
    return clamp((x-lower)/upper / (1.0 - lower/upper), 0.0, 1.0)

var joy_device = 0

func get_axis_deadzoned(axis, deadzone_lower = 0.1, deadzone_upper = 0.9):
    var r = Input.get_joy_axis(joy_device, axis)
    r = sign(r) * deadzone_clamp(abs(r), deadzone_lower, deadzone_upper)
    return r

func radial_deadzonify_vec(v : Vector2, deadzone_lower = 0.1, deadzone_upper = 0.9):
    var extent = v.length()
    extent = deadzone_clamp(extent, deadzone_lower, deadzone_upper)
    return v.normalized() * extent


var health_max = 5
var health = 3

func restore_health(points):
    health = clamp(health+abs(points), 0, health_max)

var iframes = 0.0
var max_iframes = 2.0

func damage(points):
    if iframes > 0.0:
        return false
    EmitterFactory.emit("hurt")
    iframes = max_iframes
    health = clamp(health-abs(points), 0, health_max)
    return true

func _process(delta):
    time_alive += delta
    gravity = 25.0
    jump_velocity = 10.0
    
    if iframes > 0.0:
        iframes -= delta
    if iframes > 0.5:
        $Model.visible = fmod(time_alive, 0.2) < 0.1
    else:
        $Model.visible = true
    
    if !Input.is_action_pressed("focus"):
        $FocusLight.light_color = Color("#c4e1f6")
        $FocusLight.light_energy = 1.0
    else:
        $FocusLight.light_color = Color("#d22bb4")
        $FocusLight.light_energy = 2.0
    
    var wishdir : Vector3 = Vector3()
    if Input.is_action_pressed("ui_left"):
        wishdir.x -= 1
    elif Input.is_action_pressed("ui_right"):
        wishdir.x += 1
    if Input.is_action_pressed("ui_up"):
        wishdir.z -= 1
    elif Input.is_action_pressed("ui_down"):
        wishdir.z += 1
    
    wishdir.x += get_axis_deadzoned(0)
    wishdir.z += get_axis_deadzoned(1)
    
    if wishdir.length_squared() > 1:
        wishdir = wishdir.normalized()
    
    var on_floor = floor_collision != null# or hit_a_floor
    
    var jump = Input.is_action_just_pressed("jump")
    var attack = Input.is_action_just_pressed("attack")
    var shoot = Input.is_action_pressed("shot")
    
    if bullet_timer > 0.0:
        bullet_timer -= delta
    
    var shot_velocity_inheritance = 0.5
    while bullet_timer <= 0.0:
        if shoot:
            var inst = preload("res://PlayerBullet.tscn").instance()
            get_parent_spatial().add_child(inst)
            inst.global_transform.origin = $Aimer/Grimoire.global_transform.origin
            #var dir = ($Aimer/Grimoire.global_transform.origin - global_transform.origin)
            var dir = Vector3(sin($Aimer.rotation.y), 0, cos($Aimer.rotation.y))
            dir.y = 0.0
            inst.velocity = dir.normalized() * 25.0
            inst.velocity += velocity * Vector3(1, 0, 1) * shot_velocity_inheritance
            inst.rotate_y($Aimer.rotation.y + PI/2)
            EmitterFactory.emit("shot")
            $Aimer/AnimationPlayer.play("Shrink")
            $Aimer/AnimationPlayer.seek(0.0)
            bullet_timer += bullet_time_amount
            bullets_fired += 1.0
        else:
            bullet_timer = 0.0
            break
    
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
    if groundvel_v2.length() > 0.1:
        var chase_lookdir = Vector2(wishdir.x, wishdir.z)
        if chase_lookdir.length() > 0.1:
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
            
            var hvel = Vector2(velocity.x, velocity.z)
            
            #print(heading.dot(hvel))
            if heading.dot(hvel) < 0.0:
                $Model/AnimationPlayer.play_backwards($Model/AnimationPlayer.current_animation)
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
    
    old_origin = transform.origin

var mouse_in_screen = false
func _notification(what):
    match what:
        MainLoop.NOTIFICATION_WM_MOUSE_EXIT:
            mouse_in_screen = false
        MainLoop.NOTIFICATION_WM_MOUSE_ENTER:
            mouse_in_screen = true

static func angle_to_angle(from, to):
    return fposmod(to-from + PI, PI*2) - PI

var mouse_control_enabled = false

var last_offset_angle = 0.0
var last_mouse_angle = 0.0
var last_mouse_angle_intent = 0.0
var last_mouse_position = Vector2()
func handle_graphical_heading(delta):
    var vp = get_viewport()
    
    var mouse_heading = ((vp.get_mouse_position() - vp.size*0.5 * Vector2(1.0, 0.85)) * Vector2(0.85, 1.0)).normalized()
    var turn_rate_modifier = 1.0
    var using_stick_control = false
    var stick_control = Vector2()
    stick_control.x += get_axis_deadzoned(2, 0.0, 1.0)
    stick_control.y += get_axis_deadzoned(3, 0.0, 1.0)
    stick_control = radial_deadzonify_vec(stick_control, 0.25)
    
    if last_mouse_position != vp.get_mouse_position():
        mouse_control_enabled = true
    last_mouse_position = vp.get_mouse_position()
    
    if stick_control.length() > 0.25:
        turn_rate_modifier = stick_control.length()
        mouse_heading = stick_control
        using_stick_control = true
        mouse_control_enabled = false
    
    if !(mouse_control_enabled and mouse_in_screen) and !using_stick_control:
        mouse_heading = Vector2(sin($Aimer.rotation.y), cos($Aimer.rotation.y))
    #mouse_heading = mouse_heading#Vector2(mouse_heading.y, mouse_heading.x)
    
    #var offset_angle = sin(time_alive*2.0)*PI/4.0
    var offset_angle = mouse_heading.angle_to(heading)
    if !mouse_in_screen and !using_stick_control:
        offset_angle += sin(time_alive)*0.5
    
    var focusing = Input.is_action_pressed("focus")
    if using_stick_control:
        focusing = false
    
    var mouse_angle = 0.0
    if focusing:
        mouse_angle = last_mouse_angle_intent
    elif mouse_in_screen or using_stick_control:
        mouse_angle = -mouse_heading.angle() + PI/2.0
        last_mouse_angle_intent = mouse_angle
    else:
        mouse_angle = -heading.angle() + PI/2.0
        last_mouse_angle_intent = mouse_angle
    
    if using_stick_control or (focusing and !mouse_control_enabled):
        var angdiff = angle_to_angle(mouse_angle, last_mouse_angle)
        if angdiff < PI/8.0:
            turn_rate_modifier *= 0.5
    
    if abs(last_mouse_angle - mouse_angle) < PI:
        mouse_angle = lerp(last_mouse_angle, mouse_angle, 1.0 - pow(0.0001, delta*2*turn_rate_modifier))
    elif last_mouse_angle > mouse_angle:
        mouse_angle = lerp(last_mouse_angle - PI*2, mouse_angle, 1.0 - pow(0.0001, delta*2*turn_rate_modifier))
    else:
        mouse_angle = lerp(last_mouse_angle + PI*2, mouse_angle, 1.0 - pow(0.0001, delta*2*turn_rate_modifier))
    last_mouse_angle = mouse_angle
    
    $Aimer.rotation.y = mouse_angle
    
    var position_diff = (transform.origin - old_origin)/delta
    
    $Aimer.transform.origin = lerp($Aimer.transform.origin, -position_diff * 0.03, 1.0 - pow(0.0001, delta*2))
    
    var book_distance = $Aimer/Grimoire.transform.origin.z
    var book_distance_target = $Aimer/RayCast.cast_to.z
    if $Aimer/RayCast.is_colliding():
        var distance = ($Aimer/RayCast.get_collision_point() - $Aimer/RayCast.global_transform.origin).length()
        book_distance_target = distance
        if distance < book_distance:
            $Aimer/Grimoire.transform.origin.z = distance
    $Aimer/Grimoire.transform.origin.z = lerp($Aimer/Grimoire.transform.origin.z, book_distance_target, 1.0 - pow(0.001, delta))
    
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
    
    
