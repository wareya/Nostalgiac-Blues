extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    var touched = {}
    for child in get_children():
        if child is GeometryInstance:
            var inst : GeometryInstance = child
            pass
        if child is Spatial:
            for child2 in child.get_children():
                if child2 is MeshInstance:
                    var mesh : Mesh = child2.mesh
                    for surface in range(mesh.get_surface_count()):
                        var mat : SpatialMaterial = mesh.surface_get_material(surface)
                        if mat in touched:
                            continue
                        touched[mat] = null
                        mat.params_cull_mode = SpatialMaterial.CULL_BACK
                        mat.distance_fade_max_distance = 2.0
                        mat.distance_fade_mode = SpatialMaterial.DISTANCE_FADE_PIXEL_DITHER
                        #mat.next_pass = next2
                
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
