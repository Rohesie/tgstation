//Nuclear particle projectile - a deadly side effect of fusion
/obj/projectile/energy/nuclear_particle
	name = "nuclear particle"
	icon_state = "nuclear_particle"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	flag = RAD
	irradiate = 5000
	speed = 0.4
	hitsound = 'sound/weapons/emitter2.ogg'
	impact_type = /obj/effect/projectile/impact/xray
	light_system = MOVABLE_LIGHT
	light_range = 4
	light_power = 3
	var/static/list/particle_colors = list(
		"red" = "#FF0000",
		"blue" = "#00FF00",
		"green" = "#0000FF",
		"yellow" = "#FFFF00",
		"cyan" = "#00FFFF",
		"purple" = "#FF00FF"
	)

/obj/projectile/energy/nuclear_particle/Initialize()
	. = ..()
	//Random color time!
	var/our_color = pick(particle_colors)
	add_atom_colour(particle_colors[our_color], FIXED_COLOUR_PRIORITY)
	set_light_color(particle_colors[our_color])

/atom/proc/fire_nuclear_particle(angle = rand(0,360)) //used by fusion to fire random nuclear particles. Fires one particle in a random direction.
	var/obj/projectile/energy/nuclear_particle/P = new /obj/projectile/energy/nuclear_particle(src)
	P.fire(angle)
