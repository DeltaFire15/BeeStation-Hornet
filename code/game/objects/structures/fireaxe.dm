/obj/structure/fireaxecabinet
	name = "fire axe cabinet"
	desc = "There is a small label that reads \"For Emergency use only\" along with details for safe use of the axe. As if."
	icon = 'icons/obj/wallmounts.dmi'
	icon_state = "fireaxe"
	anchored = TRUE
	density = FALSE
	armor_type = /datum/armor/structure_fireaxecabinet
	max_integrity = 150
	integrity_failure = 0.33
	layer = ABOVE_WINDOW_LAYER
	var/locked = TRUE
	var/open = FALSE
	var/obj/item/fireaxe/fireaxe

MAPPING_DIRECTIONAL_HELPERS(/obj/structure/fireaxecabinet, 32)


/datum/armor/structure_fireaxecabinet
	melee = 50
	bullet = 20
	energy = 100
	bomb = 10
	rad = 100
	fire = 90
	acid = 50

/obj/structure/fireaxecabinet/Initialize(mapload)
	. = ..()
	fireaxe = new
	update_appearance()

/obj/structure/fireaxecabinet/Destroy()
	if(fireaxe)
		QDEL_NULL(fireaxe)
	return ..()

/obj/structure/fireaxecabinet/attackby(obj/item/I, mob/living/user, params)
	if(iscyborg(user) || I.tool_behaviour == TOOL_MULTITOOL)
		toggle_lock(user)
	else if(I.tool_behaviour == TOOL_WELDER && !user.combat_mode && !broken)
		if(atom_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=2))
				return

			to_chat(user, span_notice("You begin repairing [src]."))
			if(I.use_tool(src, user, 40, volume=50, amount=2))
				atom_integrity = max_integrity
				update_appearance()
				to_chat(user, span_notice("You repair [src]."))
		else
			to_chat(user, span_warning("[src] is already in good condition!"))
		return
	else if(istype(I, /obj/item/stack/sheet/glass) && broken)
		var/obj/item/stack/sheet/glass/G = I
		if(G.get_amount() < 2)
			to_chat(user, span_warning("You need two glass sheets to fix [src]!"))
			return
		to_chat(user, span_notice("You start fixing [src]..."))
		if(do_after(user, 20, target = src) && G.use(2))
			broken = 0
			atom_integrity = max_integrity
			update_appearance()
	else if(open || broken)
		if(istype(I, /obj/item/fireaxe) && !fireaxe)
			var/obj/item/fireaxe/F = I
			if(F && ISWIELDED(F))
				to_chat(user, span_warning("Unwield the [F.name] first."))
				return
			if(!user.transferItemToLoc(F, src))
				return
			fireaxe = F
			to_chat(user, span_notice("You place the [F.name] back in the [name]."))
			update_appearance()
			return
		else if(!broken)
			toggle_open()
	else
		return ..()

/obj/structure/fireaxecabinet/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(broken)
				playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 90, 1)
			else
				playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)

/obj/structure/fireaxecabinet/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	if(open)
		return
	. = ..()
	if(.)
		update_appearance()

/obj/structure/fireaxecabinet/atom_break(damage_flag)
	. = ..()
	if(!broken && !(flags_1 & NODECONSTRUCT_1))
		update_appearance()
		broken = TRUE
		playsound(src, 'sound/effects/glassbr3.ogg', 100, TRUE)
		new /obj/item/shard(loc)
		new /obj/item/shard(loc)

/obj/structure/fireaxecabinet/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(fireaxe && loc)
			fireaxe.forceMove(loc)
			fireaxe = null
		new /obj/item/stack/sheet/iron(loc, 2)
	qdel(src)

/obj/structure/fireaxecabinet/blob_act(obj/structure/blob/B)
	if(fireaxe)
		fireaxe.forceMove(loc)
		fireaxe = null
	qdel(src)

/obj/structure/fireaxecabinet/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(open || broken)
		if(fireaxe)
			user.put_in_hands(fireaxe)
			fireaxe = null
			to_chat(user, span_notice("You take the fire axe from the [name]."))
			add_fingerprint(user)
			update_appearance()
			return
	if(locked)
		to_chat(user, span_warning("The [name] won't budge!"))
		return
	else
		open = !open
		update_appearance()
		return

/obj/structure/fireaxecabinet/attack_paw(mob/living/user)
	return attack_hand(user)

/obj/structure/fireaxecabinet/attack_silicon(mob/user)
	toggle_lock(user)
	return

/obj/structure/fireaxecabinet/attack_tk(mob/user)
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	if(locked)
		to_chat(user, span_warning("The [name] won't budge!"))
		return
	open = !open
	update_icon()

/obj/structure/fireaxecabinet/update_icon()
	cut_overlays()
	if(fireaxe)
		add_overlay("axe")
	if(!open)
		var/hp_percent = atom_integrity/max_integrity * 100
		if(broken)
			add_overlay("glass4")
		else
			switch(hp_percent)
				if(-INFINITY to 40)
					add_overlay("glass3")
				if(40 to 60)
					add_overlay("glass2")
				if(60 to 80)
					add_overlay("glass1")
				if(80 to INFINITY)
					add_overlay("glass")
		if(locked)
			add_overlay("locked")
		else
			add_overlay("unlocked")
	else
		add_overlay("glass_raised")

/obj/structure/fireaxecabinet/proc/toggle_lock(mob/user)
	to_chat(user, span_notice(" Resetting circuitry..."))
	playsound(src, 'sound/machines/locktoggle.ogg', 50, 1)
	if(do_after(user, 20, target = src))
		to_chat(user, span_notice("You [locked ? "disable" : "re-enable"] the locking modules."))
		locked = !locked
		update_appearance()

/obj/structure/fireaxecabinet/verb/toggle_open()
	set name = "Open/Close"
	set category = "Object"
	set src in oview(1)

	if(locked)
		to_chat(usr, span_warning("The [name] won't budge!"))
		return
	else
		open = !open
		update_appearance()
		return
