id = "puzzle"
-------------------------------- DEBUG OPTIONS ------------------------------------

-- If you have some debugging to do, set the chosen stat as 1 or the chosen value --

	First_Room_Number=270			-- Determines on which floor you start when starting a new game
	
	-----------------------------------------------------------------------------------
local test = require("test")
base={}
function trigger_events(idd)
	mode.trigger_events(id, idd)
end
function is_subset(subset, superset)
    -- Check if all elements of the subset are in the superset
    for value in all(subset) do
        if not tbl_has(superset, value) then
            return false
        end
    end
    
    return true
end

tuto_intro=true
function start()	
	mode.set_id(id)
	mode.loadSAVE(id)
	base = mode.base
	if tuto_intro and not DEV then
		tuto_intro=false
		init_vig({1,2,3},start)	
		return
	end
	base.gain={}
	base.surrender=nil
	init_game()
	mode.lvl=START_LVL or 1
	new_level()
	mode.in_cine=true
	mode.no_shotgun=true
	mode.hide_cards=true
	trigger_events(mode.lvl)
end

function get_board_size()
	if mode.lvl ==1 then
		return 8,5
	elseif mode.lvl == 2 then
		-- avoid crash for small board
		if #base.gain > 0 then
			mode.tbase = base.gain
			base.gain = {}
		end
		
		return 3,8
	elseif mode.lvl ==8 or mode.lvl == 9 or mode.lvl == 10 or mode.lvl ==11 then
		return 10,10
	else
		-- restore gain from small board
		if #mode.tbase > 0 then
			base.gain = mode.tbase
			mode.tbase = {}
		end 
		
		return 8,8
	end

end

function get_start_square()
	local function destination()
		for v in all(mode.destination) do
			if mode.px == v[1] then
				if mode.py ==v[2] then
					local sq= gsq(v[3],v[4])
					mode.destination = {}
					return sq
				end
			end
		end
	end

	if mode.lvl == 1 then
		mode.destination = {}
		music("lvl1",2, true)
		return gsq(3,2)
	elseif mode.lvl == 2 then
		mode.destination = {}
		music("lvl2",2, true)
		return gsq(1,6)
	elseif mode.lvl ==3 then
		mode.destination = {}
		music("lvl3",2, true)
		return gsq(2,4)
	elseif mode.lvl ==4 then
		mode.destination = {}
		music("lvl4",2, true)
		return gsq(7,7)
	elseif mode.lvl ==5 then
		mode.destination = {}
		return gsq(7,7)
	elseif mode.lvl ==6 then
		mode.destination = {}
		return gsq(7,7)
	elseif mode.lvl == 7 then
		mode.destination = {}
		return gsq(1,2)
	elseif mode.lvl ==8 then
		mode.destination = {}
		return gsq(2,9)
	elseif mode.lvl == 9 then
		mode.destination = {}
		return gsq(4,3)
	elseif mode.lvl == 10 then
		mode.destination = {}
		return gsq(5,9)
	elseif mode.lvl == 11 then
		mode.destination = {}
		return gsq(2,0)
	elseif First_Room_Number and mode.lvl == First_Room_Number then
		mode.destination = {}
		return gsq(4,7)
	else
		return destination()
	end
end

function on_piece_move(e)
	local function trigger_quality(square)
		local trig_quality= {true, false}
		if square.trigger and square.nums then
			for i = 1, #square.trigger, 1 do
				local count_ev = (square.trigger[i]=="kingkill" or square.trigger[i]=="pawnkill" 
				or square.trigger[i]=="queenkill" or square.trigger[i]=="knightkill" 
				or square.trigger[i]=="rookkill" or square.trigger[i]=="bishopkill"
				or square.trigger[i]=="kingkillglobal" or square.trigger[i]=="pawnkillglobal" 
				or square.trigger[i]=="queenkillglobal" or square.trigger[i]=="knightkillglobal" 
				or square.trigger[i]=="rookkillglobal" or square.trigger[i]=="bishopkillglobal")
				and mode.count_event().room[square.trigger[i]] or mode.count_event()[square.trigger[i]]
				if square.nums[1][i] ~= "nil" then
					if square.compare[1][i] == "lt" then
						if count_ev and count_ev >= square.nums[1][i]then
							trig_quality[1] = false
							break
						end
					elseif square.compare[1][i] == "gt" then
						if count_ev and count_ev <= square.nums[1][i] then
							trig_quality[1] = false
							break
						end
					elseif square.compare[1][i] == "le" then
						if count_ev and count_ev > square.nums[1][i] then
							trig_quality[1] = false
							break
						end
					elseif square.compare[1][i] == "ge" then
						if count_ev and count_ev < square.nums[1][i] then
							trig_quality[1] = false
							break
						end
					else
						if count_ev and count_ev ~= square.nums[1][i] then
							trig_quality[1] = false
							break
						end
					end
				end
			end
		end

		if square.no_trig and square.nums then
			for i = 1, #square.no_trig, 1 do
				local count_noev = (square.no_trig[i]=="kingkill" or square.no_trig[i]=="pawnkill" 
				or square.no_trig[i]=="queenkill" or square.no_trig[i]=="knightkill" 
				or square.no_trig[i]=="rookkill" or square.no_trig[i]=="bishopkill"
				or square.no_trig[i]=="kingkillglobal" or square.no_trig[i]=="pawnkillglobal" 
				or square.no_trig[i]=="queenkillglobal" or square.no_trig[i]=="knightkillglobal" 
				or square.no_trig[i]=="rookkillglobal" or square.no_trig[i]=="bishopkillglobal") 
				and mode.count_event().room[square.no_trig[i]] or mode.count_event()[square.no_trig[i]]

				if square.nums[2][i] ~= "nil" then
					if square.compare[2][i] == "lt" then
						if count_noev and count_noev >= square.nums[2][i] then
							trig_quality[2] = true
							break
						end
					elseif square.compare[2][i] == "gt" then
						if count_noev and count_noev <= square.nums[2][i] then
							trig_quality[2] = true
							break
						end
					elseif square.compare[2][i] == "le" then
						if count_noev and count_noev > square.nums[2][i] then
							trig_quality[2] = true
							break
						end
					elseif square.compare[2][i] == "ge" then
						if count_noev and count_noev < square.nums[2][i] then
							trig_quality[2] = true
							break
						end
					else
						if count_noev and count_noev ~= square.nums[2][i] then
							trig_quality[2] = true
							break
						end
					end
				end
			end
		end
		
		return trig_quality
	end
	if e == hero then
		if (not e.sq.trigger or
		is_subset(e.sq.trigger, mode.room_history()) and trigger_quality(e.sq)[1]
		and (#e.sq.no_trig==0 or not is_subset(e.sq.no_trig, mode.room_history()) or trigger_quality(e.sq)[2]))
		and e.sq.event and #e.sq.event~= 0 then
			if not e.sq.repeatable then
				for ev in all(e.sq.event) do
					trigger_events(ev)
				end
			else
				trigger_events(e.sq.event[1])
			end
			if e.sq.repeatable then
				if e.sq.repeatable=="deplete" then
					deli(e.sq.event[1],1)
				elseif e.sq.repeatable=="tough" and #e.sq.event>1 then
					deli(e.sq.event[1],1)
				elseif e.sq.repeatable=="recycle" then
					add(e.sq.event,e.sq.event[1])
					deli(e.sq.event[1],1)
				elseif e.sq.repeatable=="shuffle" then
					shuffle(e.sq.event)							
				end
			end
			e.sq.prelude = nil
		end
		if e.sq.prelude and #e.sq.prelude ~= 0 then
			trigger_events(e.sq.prelude[1])
			if not e.sq.repeatable then
				for pre in all(e.sq.prelude) do
					trigger_events(pre)
				end
			else
				trigger_events(e.sq.prelude[1])
			end
			if e.sq.repeatable then
				if e.sq.repeatable=="deplete" then
					deli(e.sq.prelude[1],1)
				elseif e.sq.repeatable=="tough" and #e.sq.prelude>1 then
					deli(e.sq.prelude[1],1)
				elseif e.sq.repeatable=="recycle" then
					add(e.sq.prelude,e.sq.prelude[1])
					deli(e.sq.prelude[1],1)
				elseif e.sq.repeatable=="shuffle" then
					shuffle(e.sq.prelude)	
				end
			end
		end
	end

end

function on_empty()
	-- mode.room_history("empty")
	return true
end
function on_king_death()
	sfx("mission")
	music("boss_B")
	mode.room_history("kingkill")	
	mode.room_history("kingkillglobal")	
	if not hero.clp then
		if mode.lvl == 4 then
			trigger_events("4_solved")
			trigger_events("move_1")
		elseif mode.lvl ==5 then
			trigger_events("5_solved")
			trigger_events("move_1")
		end
	end
	return true
end
function on_bishop_death()
	mode.room_history("bishopkill")
	mode.room_history("bishopkillglobal")
	return true
end
function on_knight_death()
	mode.room_history("knightkill")
	mode.room_history("knightkillglobal")
	return true
end
function on_rook_death()
	mode.room_history("rookkill")
	mode.room_history("rookkillglobal")
	return true
end
function on_pawn_death()
	mode.room_history("pawnkill")
	mode.room_history("pawnkillglobal")
	return true
end
function on_queen_death()
	mode.room_history("queenkill")
	mode.room_history("queenkillglobal")
	return true
end
function on_hero_death()
	mode.clear_allies()
	mode.del_entity()
	if TEMPO <15 then
        mode.base.TEMPO =1
    elseif TEMPO >=15 then
        mode.base.TEMPO =-1
    end
	if mode.lvl ==1 or mode.lvl ==7 then
		mode.clear_history()

		gameover()
	else
		local function puzzle_end()
			for i = #mode.room_history(), 1, -1 do
				if not (sub(mode.room_history()[i],-7,-1) =="_solved") and not (sub(mode.room_history()[i],-7,-1) =="_unlock") then
					mode.del_room_history(mode.room_history()[i])
				end
			end
			remove_soul_slot()
			add_soul_slot()
			new_level()
			trigger_events(mode.lvl)
		end
		end_level(puzzle_end)	
	end
end
function on_boss_death()
	mode.room_history("bosskill")
	-- END GAME
	music("ending_A",0)
	fade_to(-4,30,outro)
end
function outro()
	local v={4,5}	
	
	init_vig(v,init_menu)
end
function draw_inter()
	spritesheet("tutorial")
	sspr(208,0,320,182,0,0)
	spritesheet("gfx")
end