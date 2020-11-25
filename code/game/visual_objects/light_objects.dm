/atom/movable/vis_obj/light_source
	icon = 'icons/effects/light_overlays/light_range_1.dmi'
	icon_state = "base"
	plane = LIGHTING_PLANE
	layer = LIGHTING_BASE_LAYER
	//We want no TILE_BOUND for this object. We draw shadows with overlays in order to deal with the issue this incurs in.
	appearance_flags = KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_LIGHTING
	pixel_x = -WORLD_ICON_SIZE * 2
	pixel_y = -WORLD_ICON_SIZE * 2
	glide_size = WORLD_ICON_SIZE
	blend_mode = BLEND_ADD
	anchored = TRUE
	alpha = 180
	vis_flags = NONE


/atom/movable/vis_obj/lighting_mask
	name = ""
	icon = 'icons/effects/light_overlays/light_32.dmi'
	icon_state = "light"
	layer = O_LIGHTING_VISUAL_LAYER
	plane = O_LIGHTING_VISUAL_PLANE
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	vis_flags = NONE


/atom/movable/vis_obj/lighting_cone_mask
	name = ""
	icon = 'icons/effects/light_overlays/light_cone.dmi'
	icon_state = "light"
	layer = O_LIGHTING_VISUAL_LAYER
	plane = O_LIGHTING_VISUAL_PLANE
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = NONE
	alpha = 110
