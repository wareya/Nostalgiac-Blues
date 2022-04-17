tool
extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _set_model(m):
    model_file = m
    reset_children()
    
func _get_model():
    return model_file

export (PackedScene) var model_file : PackedScene = preload("res://3d/shp/pot.glb") setget _set_model, _get_model
export var destructible = false
export (PackedScene) var contents : PackedScene

var collision : PhysicsBody

var mats = {}

func reset_children():
    for child in get_children():
        child.queue_free()
    
    model = model_file.instance()
    add_child(model)
    
    var holder = find_node("Skeleton", true, false)
    if !holder:
        holder = model
    
    if destructible:
        for _submodel in holder.get_children():
            if not _submodel is MeshInstance:
                continue
            var submodel : MeshInstance = _submodel
            submodel.mesh = submodel.mesh.duplicate()
            for surface in range(submodel.mesh.get_surface_count()):
                var mat : SpatialMaterial = submodel.mesh.surface_get_material(surface)
                if mat in mats:
                    continue
                
                var newmat = Manager.make_shattery_mat(mat)
                submodel.set_surface_material(surface, newmat)
                mats[newmat] = null
    
    collision = model.find_node("static_collision", true, false)
    if destructible and collision:
        collision.add_user_signal("kill")
        collision.connect("kill", self, "kill")
        collision.set_collision_layer_bit(3, true)
    

var hits = 5
var model = null
# Called when the node enters the scene tree for the first time.
func _ready():
    reset_children()

var dead = false
var death_anim = 0.0

func kill():
    if !destructible:
        return
    if dead:
        return
    #if $Model/AnimationPlayer:
    #    $Model/AnimationPlayer.stop()
    dead = true
    death_anim = 0.0
    EmitterFactory.emit("breakeffect")
    
    var content : Spatial = contents.instance()
    get_parent().add_child(content)
    content.global_transform.origin = global_transform.origin
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if dead:
        for owner in collision.get_shape_owners():
            collision.shape_owner_set_disabled(owner, true)
        death_anim += delta
        for _mat in mats.keys():
            var mat : ShaderMaterial = _mat
            mat.set_shader_param("shatterment", death_anim)
        if death_anim > 3.0:
            queue_free()
        return
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
