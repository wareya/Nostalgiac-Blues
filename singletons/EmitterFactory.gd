extends Node

var sounds = {
"shot": preload("res://sfx/shot.wav"),
"enemydeath": preload("res://sfx/faraway.wav"),
"healthrestore": preload("res://sfx/healthrestore.wav"),
"destroyed": preload("res://sfx/destroyed.wav"),
"hurt": preload("res://sfx/playerhurt.wav"),
"damagedealt": preload("res://sfx/hurteffect2.wav"),
"breakeffect": preload("res://sfx/breakeffect2.wav"),
"bulletpuff": preload("res://sfx/bulletpuff.wav"),
"footleft": preload("res://sfx/footleft.wav"),
"footright": preload("res://sfx/footright.wav"),
"slashsound": preload("res://sfx/slashsound.wav"),
"landingsound": preload("res://sfx/landingsound.wav"),
"jumpsound": preload("res://sfx/jumpsound.wav"),
"startbleep": preload("res://sfx/startbleep.wav"),
"betterbullet": preload("res://sfx/betterbullet.wav"),
"blurp": preload("res://sfx/blurp.wav"),
"cirnodeath": preload("res://sfx/cirnodeatheffect.wav"),
}

var loud_mode = false

class Emitter3D extends AudioStreamPlayer3D:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, arg_position, channel):
        parent.add_child(self)
        transform.origin = arg_position
        var abs_position = global_transform.origin
        parent.remove_child(self)
        parent.get_tree().get_root().add_child(self)
        global_transform.origin = abs_position
        
        stream = sound
        bus = channel
        
        attenuation_model = ATTENUATION_INVERSE_SQUARE_DISTANCE
        max_db = -3
        unit_db = 18
        if EmitterFactory.loud_mode:
            unit_db *= 4.0
        unit_size = 4
        
        attenuation_filter_cutoff_hz = 22000.0
        attenuation_filter_db = -0.001
        
        play()
        ready = true
        return self


class Emitter extends AudioStreamPlayer:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, channel):
        parent.add_child(self)
        
        stream = sound
        bus = channel
        
        volume_db = -3
        play()
        ready = true
        return self

func emit(sound, parent = null, arg_position = Vector3(), channel = "SFX"):
    var stream = null
    if sound in sounds:
        stream = sounds[sound]
    elif sound is AudioStream:
        stream = sound
    if parent:
        return Emitter3D.new().emit(parent, stream, arg_position, channel)
    else:
        return Emitter.new().emit(self, stream, channel)
