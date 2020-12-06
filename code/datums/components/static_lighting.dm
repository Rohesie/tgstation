#define LIGHT_POWER_MULTIPLIER 240

GLOBAL_LIST_EMPTY(lighting_shadows_cache)

/datum/component/static_lighting
	///How far the light reaches, integer.
	var/range = 1
	///How much this light affects the dynamic_lumcount of turfs.
	var/lum_power = 0.5
	///Overlay effect to cut into the darkness and provide light.
	var/atom/movable/vis_obj/light_source/light_object
	///Lazy list to track the turfs being affected by our light, to determine their visibility.
	var/list/turf/affected_turfs
	///With ranges higher than 1, this lighting system is turf-to-turf based and if the light source is not on a turf, then it's not emitting light.
	var/atom/light_holder
	///For light sources that can be turned on and off.
	var/static_lighting_flags = NONE


/datum/component/static_lighting/Initialize(_range, _power, _color, starts_on)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	var/atom/atom_parent = parent
	if(atom_parent.light_system != STATIC_LIGHT)
		stack_trace("[type] added to [parent], with [atom_parent.light_system] value for the light_system var. Use [STATIC_LIGHT] instead.")
		return COMPONENT_INCOMPATIBLE

	. = ..()

	light_object = new()

	if(!isnull(_range))
		atom_parent.set_light_range(_range)
	if(!isnull(_power))
		atom_parent.set_light_power(_power)
	if(!isnull(_color))
		atom_parent.set_light_color(_color)
	if(!isnull(starts_on))
		atom_parent.set_light_on(starts_on)


/datum/component/static_lighting/RegisterWithParent()
	. = ..()
	if(ismovable(parent) && range > 1) //This should not be true by default, but someone might redefine the default value of range for some reason.
		RegisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_POST_AFTERSHUTTLEMOVE), .proc/on_parent_moved)
	var/atom/atom_parent = parent
	set_range(parent, atom_parent.light_range)
	set_power(parent, atom_parent.light_power)
	set_color(parent, atom_parent.light_color)
	RegisterSignal(parent, COMSIG_ATOM_SET_LIGHT_SYSTEM, .proc/on_system_change)
	RegisterSignal(parent, COMSIG_ATOM_SET_LIGHT_RANGE, .proc/set_range)
	RegisterSignal(parent, COMSIG_ATOM_SET_LIGHT_POWER, .proc/set_power)
	RegisterSignal(parent, COMSIG_ATOM_SET_LIGHT_COLOR, .proc/set_color)
	RegisterSignal(parent, COMSIG_ATOM_SET_LIGHT_ON, .proc/on_toggle)
	if(atom_parent.light_on)
		turn_on()


/datum/component/static_lighting/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_ATOM_SET_LIGHT_SYSTEM,
		COMSIG_ATOM_SET_LIGHT_RANGE,
		COMSIG_ATOM_SET_LIGHT_POWER,
		COMSIG_ATOM_SET_LIGHT_COLOR,
		COMSIG_ATOM_SET_LIGHT_ON,
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOVABLE_POST_AFTERSHUTTLEMOVE,
		))
	if(static_lighting_flags & LIGHTING_ON)
		turn_off()
	set_light_holder(null)
	return ..()


/datum/component/static_lighting/Destroy()
	set_light_holder(null)
	qdel(light_object, force = TRUE)
	light_object = null
	return ..()


///Handles a lighting system change.
/datum/component/static_lighting/proc/on_system_change(atom/source, new_system)
	SIGNAL_HANDLER
	qdel(src)


///Clears the affected_turfs lazylist, removing from its contents the effects of being near the light.
/datum/component/static_lighting/proc/clean_old_turfs()
	for(var/t in affected_turfs)
		var/turf/lit_turf = t
		lit_turf.dynamic_lumcount -= lum_power
		UnregisterSignal(lit_turf, COMSIG_TURF_POST_SET_DIRECTIONAL_OPACITY)
	affected_turfs = null


///Populates the affected_turfs lazylist, adding to its contents the effects of being near the light.
/datum/component/static_lighting/proc/get_new_turfs()
	if(!light_holder || range <= 1)
		return
	. = list()
	for(var/turf/lit_turf in oview(range - 1, light_holder))
		lit_turf.dynamic_lumcount += lum_power
		LAZYADD(affected_turfs, lit_turf)
		RegisterSignal(lit_turf, COMSIG_TURF_POST_SET_DIRECTIONAL_OPACITY, .proc/on_turf_directional_opacity_change)
		if(IS_OPAQUE_TURF(lit_turf))
			. += lit_turf


///Clears the old affected turfs and populates the new ones.
/datum/component/static_lighting/proc/make_luminosity_update()
	clean_old_turfs()
	if(!(static_lighting_flags & LIGHTING_ON) || !light_holder)
		return
	. = get_new_turfs()
	var/list/shadows = list()
	for(var/t in .)
		var/turf/blocker = t
		var/x_offset = blocker.x - light_holder.x
		var/y_offset = blocker.y - light_holder.y
		if(range >= 6 && abs(x_offset) >= range - 1 && abs(x_offset) == abs(y_offset))
			continue //Large ranges skip making shadows for the corner edges, which are already obscured by the base image.
		var/shadow_key = "[x_offset]_[y_offset]_[range]"
		var/image/cast_shadow = GLOB.lighting_shadows_cache[shadow_key]
		if(!cast_shadow)
			GLOB.lighting_shadows_cache[shadow_key] = cast_shadow = image(light_object.icon, icon_state = "[x_offset]_[y_offset]", layer = LIGHTING_SHADOW_LAYER)
		shadows += cast_shadow
	light_object.overlays = shadows


///Called to change the value of current_holder.
/datum/component/static_lighting/proc/set_light_holder(atom/new_light_holder)
	if(light_holder == new_light_holder)
		return FALSE
	. = light_holder
	light_holder = new_light_holder

	if(.) //Old holder.
		if(isturf(.))
			var/turf/old_light_holder = .
			old_light_holder.dynamic_lumcount -= lum_power
			light_object.moveToNullspace()
		else
			if(!ismovable(.))
				CRASH("set_light_holder called with improper new_light_holder type")
			var/atom/movable/old_light_holder = .
			old_light_holder.vis_contents -= light_object

	if(light_holder)
		if(isturf(light_holder))
			var/turf/turf_holder = light_holder
			turf_holder.dynamic_lumcount += lum_power
			light_object.forceMove(turf_holder)
		else
			if(!ismovable(light_holder))
				CRASH("set_light_holder called with improper new_light_holder type")
			var/atom/movable/old_light_holder = light_holder
			old_light_holder.vis_contents += light_object

	make_luminosity_update()


///Called when parent changes loc.
/datum/component/static_lighting/proc/on_parent_moved(atom/movable/source, OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	var/atom/movable/movable_parent = parent
	if(isturf(movable_parent.loc))
		set_light_holder(movable_parent.loc)
	else
		set_light_holder(null)


///Changes the range which the light reaches. 0 means no light, 6 is the maximum value.
/datum/component/static_lighting/proc/set_range(atom/source, new_range)
	SIGNAL_HANDLER
	new_range = clamp(round(new_range, 1), 0, 7)
	if(range == new_range)
		return
	. = range
	range = new_range

	if(ismovable(parent))
		if(. > 1) //old range
			if(range <= 1) //from high range to lower one
				UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_POST_AFTERSHUTTLEMOVE))
		else if(range > 1) //from short range to large one
			RegisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_POST_AFTERSHUTTLEMOVE), .proc/on_parent_moved)

	switch(range)
		if(0)
			turn_off()
			return
		if(1)
			light_object.icon = 'icons/effects/light_overlays/light_range_1.dmi'
		if(2)
			light_object.icon = 'icons/effects/light_overlays/light_range_2.dmi'
		if(3)
			light_object.icon = 'icons/effects/light_overlays/light_range_3.dmi'
		if(4)
			light_object.icon = 'icons/effects/light_overlays/light_range_4.dmi'
		if(5)
			light_object.icon = 'icons/effects/light_overlays/light_range_5.dmi'
		if(6)
			light_object.icon = 'icons/effects/light_overlays/light_range_6.dmi'
		if(7)
			light_object.icon = 'icons/effects/light_overlays/light_range_7.dmi'
		else
			stack_trace("Fatal error in the static_lighting component, someone changed the possible range values without updating the switch statement to include it. Parent for this component is [parent].")

	light_object.pixel_x = light_object.pixel_y = -(WORLD_ICON_SIZE * range)

	make_luminosity_update()


///Changes the intensity/brightness of the light by altering the visual object's alpha. If negative, produces darkness instead.
/datum/component/static_lighting/proc/set_power(atom/source, new_power)
	SIGNAL_HANDLER
	if(new_power >= 0)
		light_object.blend_mode = BLEND_ADD
		light_object.layer = LIGHTING_BASE_LAYER
	else
		light_object.blend_mode = BLEND_SUBTRACT
		light_object.layer = LIGHTING_SUBSTRACTIVE_LAYER
	set_lum_power(new_power)
	light_object.alpha = clamp(round(abs(new_power) * LIGHT_POWER_MULTIPLIER), 0, 255)


///Changes the light's color, pretty straightforward.
/datum/component/static_lighting/proc/set_color(atom/source, new_color)
	SIGNAL_HANDLER
	light_object.color = new_color


///Here we append the behavior associated to changing lum_power.
/datum/component/static_lighting/proc/set_lum_power(new_lum_power)
	if(lum_power == new_lum_power)
		return
	. = lum_power
	lum_power = new_lum_power
	var/difference = lum_power - .
	if(isturf(light_holder))
		var/turf/turf_holder = light_holder
		turf_holder.dynamic_lumcount += difference
	for(var/t in affected_turfs)
		var/turf/lit_turf = t
		lit_turf.dynamic_lumcount += difference


///Called when the light is toggled on and off.
/datum/component/static_lighting/proc/on_toggle(atom/source, new_value)
	SIGNAL_HANDLER
	if(new_value) //Truthy value input, turn on.
		turn_on()
		return
	turn_off() //Falsey value, turn off.


///Toggles the light on.
/datum/component/static_lighting/proc/turn_on()
	if(static_lighting_flags & LIGHTING_ON)
		return
	static_lighting_flags |= LIGHTING_ON

	var/atom/atom_parent = parent
	if(range == 1 || isturf(atom_parent))
		set_light_holder(atom_parent)
	else if(isturf(atom_parent.loc))
		set_light_holder(atom_parent.loc)


///Toggles the light off.
/datum/component/static_lighting/proc/turn_off()
	if(!(static_lighting_flags & LIGHTING_ON))
		return
	static_lighting_flags &= ~LIGHTING_ON
	set_light_holder(null)


///Toggles the light on and off.
/datum/component/static_lighting/proc/on_turf_directional_opacity_change(atom/source, old_opacity)
	SIGNAL_HANDLER
	make_luminosity_update()
