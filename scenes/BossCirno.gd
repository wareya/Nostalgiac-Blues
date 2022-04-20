extends QuakelikeBody

var cirno_parts_visible = true
var alice_parts_visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
    $HP.visible = false
    $AudioStreamPlayer2D.attenuation_filter_db = -0.001
    #$Aimer/Grimoire/AnimationPlayer.get_animation("Idle").loop = true
    #$Aimer/Grimoire/AnimationPlayer.play("Idle")
    
    $Model/AnimationPlayer.get_animation("Walk").loop = true
    $Model/AnimationPlayer.get_animation("Idle").loop = true
    $Model/AnimationPlayer.get_animation("Air").loop = true
    $Model/AnimationPlayer.get_animation("Float").loop = true
    
    # special parts
    $"Model/Armature/Skeleton/dead eyes".visible = false
    $"Model/Armature/Skeleton/crossed eyes".visible = false
    
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
    
    play_anim("Float", 0.5, 0.2)
    
    custom_move_and_slide(0.016, Vector3.DOWN)
    
    for _submodel in $Model/Armature/Skeleton.get_children():
        var submodel : MeshInstance = _submodel
        for surface in range(submodel.mesh.get_surface_count()):
            var mat : Material = submodel.mesh.surface_get_material(surface)
            if mat in mats:
                mats[mat].push_back(surface)
            else:
                mats[mat] = [submodel, surface]
    
    pass # Replace with function body.

var mats = {}

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

var block_anims = false

func play_anim_queued(anim : String, rate = 1.0, blend = -1):
    if block_anims:
        return
    if current_anim_is_forced():
        return
    if $Model/AnimationPlayer.current_animation != anim:
        $Model/AnimationPlayer.queue(anim, blend * rate, rate)

func play_anim(anim : String, rate = 1.0, blend = -1):
    if block_anims:
        return
    if current_anim_is_forced():
        return
    if $Model/AnimationPlayer.current_animation != anim:
        $Model/AnimationPlayer.play(anim, blend * rate, 1.0)
        #AnimationPlayer.new().seek()
        $Model/AnimationPlayer.seek(0.0, true)
    $Model/AnimationPlayer.playback_speed = rate


var bullet_scene = preload("res://scenes/Bullet.tscn")

var pattern_1_breakpoint = 400.0
var pattern_2_breakpoint = 200.0

var dead = false
var health_max = 600.0
var health = health_max

var destination = Vector3()

signal flight_complete
func fly_to(other : Spatial):
    destination = other.global_transform.origin

func clear_bullets():
    for bullet in get_tree().get_nodes_in_group("EnemyBullet"):
        bullet.life_time = 0.0

func add_bullet(reference : Spatial):
    var bullet = bullet_scene.instance()
    get_parent().add_child(bullet)
    bullet.global_transform.origin = reference.global_transform.origin
    bullet.disable_world_collision()
    
    bullet.speed = 5.0
    bullet.linear_decay = 1.0
    bullet.spin_decay = 0.2
    bullet.life_time = 6.0
    bullet.radians_per_second = 0.0
    
    return bullet
    

var pattern_1_running = false
var pattern_1_ran = false
func pattern_1():
    pattern_1_running = true
    
    if true:
        for _i in range(2):
            for i in range(20):
                for j in range(3):
                    var rad = deg2rad(i*14.0 + j*120.0)
                    var arc = Vector3(sin(rad), 0.0, cos(rad))
                    var bullet = add_bullet(self)
                    bullet.global_transform.origin += arc
                    bullet.direction = arc.rotated(Vector3.UP, -PI*0.5)
                    bullet.direction.y -= 0.1
                    bullet.radians_per_second = -PI*1.5
                $AudioStreamPlayer2D.play()
                yield(get_tree().create_timer(0.1), "timeout")
                if dead: return
            yield(get_tree().create_timer(1.0), "timeout")
            if dead: return
        
        if health <= pattern_1_breakpoint:
            clear_bullets()
            yield(get_tree().create_timer(1.0), "timeout")
            pattern_1_running = false
            return
        
        fly_to(side_hoodoo_top)
        yield(self, "flight_complete")
        if dead: return
        for _i in range(2):
            for i in range(14):
                for j in range(6):
                    var rad = deg2rad(i*14.0 + j*60.0)
                    var arc = Vector3(sin(rad), 0.0, cos(rad))
                    var bullet = add_bullet(self)
                    bullet.global_transform.origin += arc
                    bullet.direction = arc.rotated(Vector3.UP, PI*0.5)
                    bullet.direction.y -= 0.1
                    bullet.radians_per_second = -PI*2.0
                $AudioStreamPlayer2D.play()
                yield(get_tree().create_timer(0.2), "timeout")
                if dead: return
            yield(get_tree().create_timer(1.0), "timeout")
            if dead: return
        
        if health <= pattern_1_breakpoint:
            clear_bullets()
            yield(get_tree().create_timer(1.0), "timeout")
            pattern_1_running = false
            return
    
    fly_to(center_hoodoo_top)
    yield(self, "flight_complete")
    if dead: return
    for _i in range(1):
        var bullets = {}
        for i in range(12):
            for j in range(8):
                var rad = deg2rad(i*20.0 + j*45.0)
                var arc = Vector3(sin(rad), 0.0, cos(rad))
                var bullet = add_bullet(self)
                bullet.global_transform.origin += arc * (1.0 + (i%4)*0.5)
                bullet.speed *= (1.0 + (i%2)*0.2)
                bullet.direction = arc.rotated(Vector3.UP, PI*0.5)
                bullet.linear_decay = pow(1.1, i%4 + 1)
                bullet.direction.y -= 0.06
                bullet.radians_per_second = -PI*2.0 * lerp(1.0, 1.4, (i%4)/3.0)
                bullet.paused = true
                bullets[bullet] = null
            $AudioStreamPlayer2D.play()
            yield(get_tree().create_timer(0.2), "timeout")
            if dead: return
            if i%4 == 3:
                for bullet in bullets:
                    bullet.paused = false
                bullets = {}
                EmitterFactory.emit("blurp", self)
                yield(get_tree().create_timer(1.0), "timeout")
                if dead: return
        yield(get_tree().create_timer(1.0), "timeout")
        if dead: return
    
    pattern_1_running = false


var pattern_2_running = false
var pattern_2_ran = false
func pattern_2():
    pattern_2_running = true
    
    fly_to(center_hoodoo_top)
    yield(self, "flight_complete")
    if dead: return
    
    if true:
        if true:
            clear_bullets()
            for _i in range(4):
                for i in range(15):
                    for j in range(8):
                        var rad = deg2rad(i*7.0 + j*45.0)
                        var arc = Vector3(sin(rad), 0.0, cos(rad))
                        var bullet = add_bullet(self)
                        bullet.global_transform.origin += arc
                        bullet.direction = arc.rotated(Vector3.UP, -PI*0.5)
                        bullet.direction.y -= 0.1
                        bullet.radians_per_second = -PI*1.0
                        bullet.life_time = 3.0
                        if j%2 == 0:
                            bullet.radians_per_second *= 1.2
                            bullet.speed *= 1.2
                        if _i == 1:
                            bullet.speed *= 1.2
                    $AudioStreamPlayer2D.play()
                    yield(get_tree().create_timer(0.12), "timeout")
                    if dead: return
                yield(get_tree().create_timer(0.5), "timeout")
                if dead: return
                
                if _i == 1:
                    fly_to(ground_refpoint)
                    yield(self, "flight_complete")
            
            if health <= pattern_2_breakpoint:
                clear_bullets()
                yield(get_tree().create_timer(1.0), "timeout")
                pattern_2_running = false
                return
            
        fly_to(mushroom_top)
        yield(self, "flight_complete")
        if dead: return
        
        clear_bullets()
        for _i in range(3):
            var bullets = {}
            for i in range(14):
                var b2 = add_bullet(self)
                b2.direction = Manager.find_player().global_transform.origin - global_transform.origin
                b2.direction = b2.direction.normalized()
                for j in range(6):
                    var rad = deg2rad(i*14.0 + j*60.0)
                    var arc = Vector3(sin(rad), 0.0, cos(rad))
                    var bullet = add_bullet(self)
                    bullet.global_transform.origin += arc
                    bullet.direction = arc.rotated(Vector3.UP, PI*0.5)
                    bullet.speed = 2.5
                    bullet.direction.y -= 0.1
                    bullet.radians_per_second = 0.0#-PI*2.0
                    bullets[bullet] = null
                $AudioStreamPlayer2D.play()
                yield(get_tree().create_timer(0.1), "timeout")
                if dead: return
            yield(get_tree().create_timer(0.2), "timeout")
            if dead: return
            for bullet in bullets.keys():
                bullet.paused = true
            yield(get_tree().create_timer(0.5), "timeout")
            if dead: return
            for bullet in bullets.keys():
                bullet.paused = false
                bullet.speed = 10.0
                bullet.linear_decay = 0.75
                bullet.radians_per_second = -4.0
                bullet.spin_decay = 1.4
            EmitterFactory.emit("blurp", self)
            yield(get_tree().create_timer(0.2), "timeout")
            if dead: return
            for bullet in bullets.keys():
                bullet.linear_decay = 1.4
                bullet.spin_decay = 0.5
                bullet.radians_per_second = -bullet.radians_per_second
            yield(get_tree().create_timer(0.8), "timeout")
            if dead: return
            bullets = {}
            
        
        if health <= pattern_2_breakpoint:
            clear_bullets()
            yield(get_tree().create_timer(1.0), "timeout")
            pattern_2_running = false
            return
    
    fly_to(center_hoodoo_top)
    yield(self, "flight_complete")
    if dead: return
    
    clear_bullets()
    for _i in range(1):
        var bullets = {}
        for i in range(15):
            for j in range(8):
                var rad = deg2rad(i*20.0 + j*45.0) * (1.0 if j%2 == 0 else -1.0)
                var arc = Vector3(sin(rad), 0.0, cos(rad))
                var bullet = add_bullet(self)
                bullet.global_transform.origin += arc * lerp(1.0, 1.5, j/7.0)
                bullet.speed *= (1.0 + (j%2)*0.5)
                bullet.direction = arc.rotated(Vector3.UP, PI*0.5)
                bullet.linear_decay = pow(1.1, i%5 + 1)
                bullet.direction.y -= 0.06
                bullet.radians_per_second = PI * lerp(1.0, 1.4, (i%4)/3.0)
                bullet.paused = true
                bullets[bullet] = null
            $AudioStreamPlayer2D.play()
            yield(get_tree().create_timer(0.15), "timeout")
            if dead: return
            if i%5 == 4:
                for bullet in bullets:
                    bullet.paused = false
                bullets = {}
                EmitterFactory.emit("blurp", self)
                yield(get_tree().create_timer(1.0), "timeout")
                if dead: return
        yield(get_tree().create_timer(1.0), "timeout")
        if dead: return
    
    pattern_2_running = false


var pattern_3_running = false
var pattern_3_ran = false
func pattern_3():
    pattern_3_running = true
    
    fly_to(ground_refpoint)
    yield(self, "flight_complete")
    if dead: return

    clear_bullets()
    for _i in range(1):
        for i in range(20):
            for j in range(8):
                for x in range(2):
                    var rad = deg2rad(i*7.0 + j*45.0)
                    var arc = Vector3(sin(rad), 0.0, cos(rad))
                    var bullet = add_bullet(self)
                    bullet.global_transform.origin += arc
                    bullet.direction = arc.rotated(Vector3.UP, -PI*0.5) * lerp(-1, 1, x)
                    bullet.direction.y -= 0.1
                    bullet.radians_per_second = -PI*1.0 * lerp(-1, 1, x)
                    bullet.life_time = 4.0
            
            $AudioStreamPlayer2D.play()
            yield(get_tree().create_timer(0.1), "timeout")
            if dead: return
            
            $AudioStreamPlayer2D.play()
            yield(get_tree().create_timer(0.1), "timeout")
            if dead: return
        yield(get_tree().create_timer(0.5), "timeout")
        if dead: return
        
    #if health <= pattern_3_breakpoint:
    #    pattern_3_running = false
    #    return
    
    clear_bullets()
    var player = Manager.find_player()
    for _i in range(2):
        for i in range(20):
            var b2 = add_bullet(self)
            b2.direction = player.global_transform.origin + player.velocity*Vector3(1.0, 0.0, 1.0)*0.2 - global_transform.origin
            b2.direction = b2.direction.normalized()
            b2.direction = b2.direction.rotated(Vector3.UP, rand_range(-0.1, 0.1))
            
            for j in range(6):
                var rad = deg2rad(i*14.0 + j*60.0)
                var arc = Vector3(sin(rad), 0.0, cos(rad))
                var bullet = add_bullet(self)
                bullet.global_transform.origin += arc
                bullet.direction = arc
                bullet.direction.y -= 0.1
                bullet.radians_per_second = -PI*2.0
                bullet.radians_per_second *= 1.0 if (j % 2 == 0) else -1.0
                
            $AudioStreamPlayer2D.play()
            yield(get_tree().create_timer(0.2), "timeout")
            if dead: return
        yield(get_tree().create_timer(1.0), "timeout")
        if dead: return
    
    pattern_3_running = false

onready var side_hoodoo_base : Spatial = get_parent().get_node("HoodooSideBase")
onready var side_hoodoo_top : Spatial = get_parent().get_node("HoodooSideTop")
onready var center_hoodoo_base : Spatial = get_parent().get_node("HoodooCenterBase")
onready var center_hoodoo_top : Spatial = get_parent().get_node("HoodooCenterTop")
onready var mushroom_top : Spatial = get_parent().get_node("MushroomTop")
onready var ground_refpoint : Spatial = get_parent().get_node("GroundRef")

func damage(amount = 1.0):
    health = clamp(health - amount, 0.0, health_max)
    if health <= 0.0:
        if !dead:
            EmitterFactory.emit("cirnodeath", self)
            death_moment = time_alive
            dead = true
            Engine.time_scale = 0.5
            clear_bullets()
    


var velocity = Vector3()
var base_speed = 5.0

var time_alive = 0.0
var death_moment = 0.0
var death_surface_copying_done = false

func _process(delta):
    if Manager.input_mode != "gameplay":
        return
    
    time_alive += delta
    
    $HP.visible = true
    $HP.max_value = health_max
    $HP.value = health
    
    if time_alive < 2.0:
        return
    
    if dead:
        if time_alive - death_moment > 4.0:
            Manager.change_to("res://scenes/Ending Screen.tscn")
            Manager.get_node("BGMPlayer").stop()
            Manager.get_node("BGMPlayer").volume_db = 0.0
            Engine.time_scale = 1.0
        
        Manager.get_node("BGMPlayer").volume_db -= delta*12.0
        $Hull.disabled = true
        $Model/Armature/Skeleton.clear_bones_global_pose_override()
    
        if !death_surface_copying_done:
            death_surface_copying_done = true
            for _mat in mats.keys():
                var mat : Material = _mat
                var submodel : MeshInstance = mats[mat][0]
                var newmat = Manager.make_shattery_mat(mat)
                for i in range(1, mats[mat].size()):
                    var surface = mats[mat][i]
                    submodel.set_surface_material(surface, newmat)
                mats.erase(mat)
                mats[newmat] = null
        #$Aimer.visible = false
        # these aren't shattering for some reason i dunno why
        $"Model/Armature/Skeleton/eyes".visible = false
        $"Model/Armature/Skeleton/crossed eyes".visible = false
        $"Model/Armature/Skeleton/dead eyes".visible = false
        $"Model/Armature/Skeleton/ribbon".visible = false
        for _mat in mats.keys():
            if not _mat is ShaderMaterial:
                continue
            var mat : ShaderMaterial = _mat
            mat.set_shader_param("shatterment", time_alive - death_moment)
            mat.set_shader_param("scale", $Model.scale)
            mat.set_shader_param("gravity_amount", 0.0)
            mat.next_pass = null
        
        return
    
    
    if health > pattern_1_breakpoint or pattern_1_running:
        if !pattern_1_running:
            pattern_1()
    elif health > pattern_2_breakpoint or pattern_2_running:
        if !pattern_2_running:
            pattern_2()
    else:
        if !pattern_3_running:
            pattern_3()
    #elif health > 400.0:
    #    if !pattern_2_running:
    #        pattern_2()
    
    var height_diff = 0.0
    var speed = base_speed
    if destination:
        var dir : Vector3 = destination - global_transform.origin
        if dir.length()  < 0.5:
            destination = null
            emit_signal("flight_complete")
        else:
            height_diff = dir.y
            dir.y = 0
            var want_vel : Vector3 = dir.normalized() * speed
            #var cross = velocity.normalized().cross(player_dir.normalized())
            var v2 = velocity
            v2.y = 0
            if v2.length() < 0.1:
                v2 = Vector3.BACK
            #print(v2)
            var angle : float = v2.angle_to(dir)
            var turn_rate = deg2rad(360.0)
            var max_angle = turn_rate * delta
            
            if angle <= max_angle:
                v2 = want_vel
            else:
                v2 = v2.normalized().slerp(want_vel.normalized(), max_angle/angle) * v2.length()
            
            v2 = v2.normalized() * speed
            
            velocity.x = lerp(velocity.x, v2.x, 1.0 - pow(0.0001, delta*5.0))
            velocity.z = lerp(velocity.z, v2.z, 1.0 - pow(0.0001, delta*5.0))
    
    if !destination:
        velocity *= pow(0.0001, delta)
    
    var vert_speed = 2.0
    if height_diff < -0.2:
        velocity.y = lerp(velocity.y, -vert_speed, 1.0 - pow(0.0001, delta))
    elif height_diff > 0.2:
        velocity.y = lerp(velocity.y, vert_speed, 1.0 - pow(0.0001, delta))
    else:
        velocity.y = lerp(velocity.y, 0.0, 1.0 - pow(0.0001, delta))
    
    move_and_slide(velocity)
    
    var v2 = velocity
    v2.y = 0
    if v2.length() > 0.5:
        var angle = Vector3.BACK.signed_angle_to(v2, Vector3.UP)
        if angle-rotation.y >= PI:
            angle -= PI*2
        rotation.y = lerp(rotation.y, angle, 1.0 - pow(0.0001, delta))
        $Model.rotation_degrees.x = lerp($Model.rotation_degrees.x, v2.length() * 5.0, 1.0 - pow(0.0001, delta))
    else:
        rotation.y = lerp(rotation.y, 0.0, 1.0 - pow(0.0001, delta))
        $Model.rotation_degrees.x = lerp($Model.rotation_degrees.x, 0.0, 1.0 - pow(0.0001, delta))
