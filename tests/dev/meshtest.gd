extends SceneTree
class C extends Control:
	var m: ArrayMesh
	var m2: ArrayMesh
	func _draw():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1,0.1,0.2))
		draw_mesh(m, null, Transform2D(0.0, Vector2(2,2), 0.0, Vector2(10,10)), Color(1,0,0))
		draw_set_transform(Vector2(300,10), 0, Vector2(2,2))
		draw_mesh(m, null, Transform2D.IDENTITY, Color(0,1,0))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array(), PackedVector2Array([Vector2(0,60),Vector2(100,60),Vector2(0,160)]), PackedColorArray([Color(0,0,1)]))
		draw_mesh(m2, null, Transform2D.IDENTITY, Color(1,1,0))
		draw_multiline(PackedVector2Array([Vector2(0,0),Vector2(100,100)]), Color.WHITE, 1.0/2.0)
func _init():
	var c := C.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(0,0),Vector2(100,0),Vector2(0,50)])
	c.m = ArrayMesh.new()
	c.m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var arr2 := []
	arr2.resize(Mesh.ARRAY_MAX)
	arr2[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(110,0),Vector2(110,100),Vector2(120,0),Vector2(150,100)])
	c.m2 = ArrayMesh.new()
	c.m2.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr2)
	c.size = Vector2(800,500)
	root.add_child(c)
	for i in 5: await process_frame
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/d3bdff63-a407-568b-a7df-ccd646a19633/scratchpad/shots/mt.png")
	quit()
