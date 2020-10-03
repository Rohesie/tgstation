SUBSYSTEM_DEF(icon_smooth)
	name = "Icon Smoothing"
	init_order = INIT_ORDER_ICON_SMOOTHING
	wait = 1
	priority = FIRE_PRIOTITY_SMOOTHING
	flags = SS_TICKER

	///Blueprints assemble an image of what pipes/manifolds/wires look like on initialization, and thus should be taken after everything's been smoothed
	var/list/blueprint_queue = list()
	var/list/smooth_queue = list()
	var/list/deferred = list()

	var/list/obj/screen/filterfrill/frills = list()
	///List of "opaque" frills, they dont get affected by transparency effects
	var/list/obj/screen/filterfrill/frills_opaque = list()
	var/list/atoms_with_frills = list(
		/turf/closed/wall
		)

/datum/controller/subsystem/icon_smooth/fire()
	var/list/cached = smooth_queue
	while(length(cached))
		var/atom/smoothing_atom = cached[length(cached)]
		cached.len--
		if(QDELETED(smoothing_atom) || !(smoothing_atom.smoothing_flags & SMOOTH_QUEUED))
			continue
		if(smoothing_atom.flags_1 & INITIALIZED_1)
			smoothing_atom.smooth_icon()
		else
			deferred += smoothing_atom
		if (MC_TICK_CHECK)
			return

	if (!cached.len)
		if (deferred.len)
			smooth_queue = deferred
			deferred = cached
		else
			can_fire = FALSE

/datum/controller/subsystem/icon_smooth/Initialize()
	var/list/initialized_frills = list()

	for(var/_typepath as anything in atoms_with_frills)
		var/turf/typepath = _typepath

		//initial() allows to access the inital values of typepaths, neat stuff
		var/key = "[initial(typepath.icon)]_[initial(typepath.base_icon_state)]"

		//Multiple typepaths can be using the same icon file, theres no point in making 50 million frills for the same icon
		if(key in initialized_frills)
			continue

		//All combinations of EAST AND WEST
		//Easiest way to map out all 4 junctions for the frills
		var/list/bitflagdirections = list(0,4,8,12)
		for(var/junction in bitflagdirections)
			var/obj/screen/filterfrill/frill = new(null, initial(typepath.icon), "[initial(typepath.base_icon_state)]-frill-[junction]")
			frills["[key]_[junction]"] = frill

		//All combinations of NORTH, EAST, WEST, NORTHEAST and NORTHWEST
		var/list/bitflagdirectionsopaque = list(/*1, */5, 9, 13, 21, 29, 137, 141, 157)
		for(var/junction in bitflagdirectionsopaque)
			var/obj/screen/filterfrill/frill = new(null, initial(typepath.icon), "[initial(typepath.base_icon_state)]-frill-[junction]")
			frill.plane = GAME_PLANE
			frill.layer = FRILL_LAYER
			frill.pixel_y = 32
			frill.render_target = ""
			frills_opaque["[key]_[junction]"] = frill

		initialized_frills[key] = TRUE

	//Dont need that list anymore, we can dispose of it
	atoms_with_frills = null

	//We send out the frills to everyone, im not sure if this is required as its also added to the screen in show_hud()
	// but this is a rather cheap operation and its better doing this than debugging why frills are invisible
	for(var/_client in GLOB.clients)
		var/client/client = _client
		for(var/frillname in frills)
			client.screen += frills[frillname]


	smooth_zlevel(1, TRUE)
	smooth_zlevel(2, TRUE)

	var/list/queue = smooth_queue
	smooth_queue = list()

	while(length(queue))
		var/atom/smoothing_atom = queue[length(queue)]
		queue.len--
		if(QDELETED(smoothing_atom) || !(smoothing_atom.smoothing_flags & SMOOTH_QUEUED) || smoothing_atom.z <= 2)
			continue
		smoothing_atom.smooth_icon()
		CHECK_TICK

	queue = blueprint_queue
	blueprint_queue = list()

	for(var/item in queue)
		var/atom/movable/movable_item = item
		if(!isturf(movable_item.loc))
			continue
		var/turf/item_loc = movable_item.loc
		item_loc.add_blueprints(movable_item)

	return ..()


/datum/controller/subsystem/icon_smooth/proc/add_to_queue(atom/thing)
	if(thing.smoothing_flags & SMOOTH_QUEUED)
		return
	thing.smoothing_flags |= SMOOTH_QUEUED
	smooth_queue += thing
	if(!can_fire)
		can_fire = TRUE

/datum/controller/subsystem/icon_smooth/proc/remove_from_queues(atom/thing)
	thing.smoothing_flags &= ~SMOOTH_QUEUED
	smooth_queue -= thing
	blueprint_queue -= thing
	deferred -= thing
