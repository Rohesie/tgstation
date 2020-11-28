/atom/movable/vis_obj
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE
	move_resist = INFINITY
	anchored = TRUE

/atom/movable/vis_obj/fire_act(exposed_temperature, exposed_volume)
	return

/atom/movable/vis_obj/acid_act()
	return FALSE

/atom/movable/vis_obj/blob_act(obj/structure/blob/B)
	return

/atom/movable/vis_obj/attack_hulk(mob/living/carbon/human/user)
	return FALSE

/atom/movable/vis_obj/experience_pressure_difference()
	return

/atom/movable/vis_obj/ex_act(severity, target)
	return

/atom/movable/vis_obj/singularity_act()
	return

/atom/movable/vis_obj/onTransitZ()
	return

/atom/movable/vis_obj/wash(clean_types)
	return

/atom/movable/vis_obj/onShuttleMove()
	return FALSE

/atom/movable/vis_obj/abstract/singularity_pull()
	return

/atom/movable/vis_obj/abstract/has_gravity(turf/T)
	return FALSE
