newsrf("planner/tiles.png", "customtiles")
local test = require("test.lua")

function dr_tile(id, x, y) -- draws minesweeper tiles
    local oldSp = spritesheet()
    spritesheet("customtiles")
    -- sspr(id * 16, 0, 16, 16, x, y)
    spr(id, x,y)
    spritesheet(oldSp)
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
function move_sq_condition(sq)
	local function trigger_quality(square)
		local trig_quality= {true, false}
		if square.trigger and square.nums then
			for i = 1, #square.trigger, 1 do
				local count_ev = (square.trigger[i]=="kingkill" or square.trigger[i]=="pawnkill" 
				or square.trigger[i]=="queenkill" or square.trigger[i]=="knightkill" 
				or square.trigger[i]=="rookkill" or square.trigger[i]=="bishopkill") and mode.count_event().room[square.trigger[i]] or mode.count_event()[square.trigger[i]]
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
				or square.no_trig[i]=="rookkill" or square.no_trig[i]=="bishopkill") and mode.count_event().room[square.no_trig[i]] or mode.count_event()[square.no_trig[i]]

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

    return (not sq.trigger or is_subset(sq.trigger, mode.room_history()) and trigger_quality(sq)[1] and
               (#sq.no_trig == 0 or not is_subset(sq.no_trig, mode.room_history()) or trigger_quality(sq)[2]))
end
function detach_move_event(ev)
    for v in all(ev) do
        if sub(v,1,5) == "move_" then
            return sbs(v, "move_","")
        end
    end
end
local function setEnter(sq)
    if sq.entered ~= nil then
        sq.entered = not sq.entered
        sq.enter_turn = mode.turns
    else
        sq.entered = true
        sq.enter_turn = mode.turns
    end
end

tileType = {
    phoenix = {
        dr = function(_, x, y)
            rect(x, y, x + 15, y + 15, 5)
        end,
        onEnter = function(e)
            if e ~= hero then
                wait(23, function()
                    hit(e, -2)
                end)
            end
        end
    },
    chaos = {
        dr = function(_, x, y)
            rect(x, y, x + 15, y + 15, 1)
        end,
        onLeave = function(e, sq)
            local dmg = 0
            for i = 0, 7 do
                if dsq(e.sq, i).tile_special == "chaos" and dsq(e.sq, i).p then
                    if not dsq(e.sq, i).p.bad then
                        dmg = dmg + 1
                    end
                end
            end
            if e.bad then
                wait(23, function()
                    hit(e, dmg)
                end)
            end
        end
    },
    normalize = {},
    void = {},
    moat={
        dr=function(_, x, y)
            if get_square_at(x,y) and (get_square_at(x,y).px+get_square_at(x,y).py)%2 == 0 then
                dr_tile(54, x, y)
            elseif get_square_at(x,y) and (get_square_at(x,y).px+get_square_at(x,y).py)%2 ==1 then
                dr_tile(55, x, y)
            end 
        end,
        upd = function(sq)
            sq.moat=true
        end
    },
    trap = {
        onEnter = function(e)
            if e ~= hero then
                wait(23, function()
                    if e.hp then
                        hit(e, 2)
                    end
                end)
            end
        end,
        dr = function(_, x, y)
            dr_tile(0, x, y)
        end
    },
    troll = {
        onEnter = function(e)
            if e == hero then
                wait(23, function()
                    gimme("SUGAR")
                end)
            end
        end,
        dr = function(_, x, y)
            dr_tile(1, x, y)
        end
    },
    gameover = {
        onEnter = function(e)
            if e == hero then
                wait(23, function()
                    remove_buts()
                    hero.fail = true
                    fx_detect(180, e)
                    wait(180, function()
                        xpl_king()
                    end)
                end)
            end
        end,
        dr = function(_, x, y)
            dr_tile(2, x, y)

        end,
    },
    slip = {
        onEnter = function(e, sq)
            if e == hero then
                stack.paralysis = mode.turns + 2
                sq.hasSlipped = true
                hero.awake = false
            end
        end,
        dr = function(sq, x, y)
            if sq.hasSlipped then
                dr_tile(3, x, y)
            end

        end
    },
    down = {
        dr = function(sq, x, y)
            if move_sq_condition(sq) then
                dr_tile(7, x, y)
            else
                dr_tile(6, x, y)
            end
        end
    },
    left = {
        dr = function(sq, x, y)
            if move_sq_condition(sq) then
                dr_tile(5, x, y)
            else
                dr_tile(4, x, y)
            end
        end
    },
    up = {
        dr = function(sq, x, y)
            if move_sq_condition(sq) then
                dr_tile(9, x, y)
            else
                dr_tile(8, x, y)
            end
        end
    },
    right = {
        dr = function(sq, x, y)
            if move_sq_condition(sq) then
                dr_tile(12, x, y)
            else
                dr_tile(11, x, y)
            end
        end
    },

    pc1 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if tbl_has(mode.room_history(), "pc1") then
                mode.del_room_history("pc1")
            else
                mode.room_history("pc1")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(13, x, y)
            else
                dr_tile(14, x, y)
            end
        end
    },
    pc2 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc2"] then
                mode.del_room_history("pc2")
            else
                mode.room_history("pc2")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(15, x, y)
            else
                dr_tile(16, x, y)
            end
        end
    },
    pc3 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc3"] then
                mode.del_room_history("pc3")
            else
                mode.room_history("pc3")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(17, x, y)
            else
                dr_tile(18, x, y)
            end
        end
    },
    pc4 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc4"] then
                mode.del_room_history("pc4")
            else
                mode.room_history("pc4")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(19, x, y)
            else
                dr_tile(20, x, y)
            end
        end
    },
    pc5 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc5"] then
                mode.del_room_history("pc5")
            else
                mode.room_history("pc5")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(22, x, y)
            else
                dr_tile(23, x, y)
            end
        end
    },
    pc6 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc6"] then
                mode.del_room_history("pc6")
            else
                mode.room_history("pc6")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(24, x, y)
            else
                dr_tile(25, x, y)
            end
        end
    },
    pc7 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc7"] then
                mode.del_room_history("pc7")
            else
                mode.room_history("pc7")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(26, x, y)
            else
                dr_tile(27, x, y)
            end
        end
    },
    pc8 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc8"] then
                mode.del_room_history("pc8")
            else
                mode.room_history("pc8")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(28, x, y)
            else
                dr_tile(29, x, y)
            end
        end
    },
    pc9 = {
        onEnter = function(e, sq)
            wait(15, setEnter, sq)
            if mode.room_history()["pc9"] then
                mode.del_room_history("pc9")
            else
                mode.room_history("pc9")
            end
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(30, x, y)
            else
                dr_tile(31, x, y)
            end
        end
    },
    pcexit = {
        onEnter = function(e, sq)
            local ev_room= mode.room_history()
            if mode.lvl==10 and ev_room[#ev_room-2]=="pc8" and ev_room[#ev_room-1]=="pc2" and ev_room[#ev_room]=="pc4" then
                mode.trigger_events("breached","pcFloor3")         
            elseif  mode.lvl==27 and ev_room[#ev_room-2]=="pc4" and ev_room[#ev_room-1]=="pc5" and ev_room[#ev_room]=="pc8" then
                mode.trigger_events("breached","pcFloor6")    
            elseif mode.lvl==30 and ev_room[#ev_room-2]=="pc6" and ev_room[#ev_room-1]=="pc7" and ev_room[#ev_room]=="pc2" then
                mode.trigger_events("breached","pcFloor7")       
            end
        end,
        dr = function(sq, x, y)
            dr_tile(32, x, y)
        end
    },
    vent = {
        dr = function(sq, x, y)
            dr_tile(33, x, y)
        end
    },
    stair = {
        dr = function(sq, x, y)
            dr_tile(34, x, y)
        end
    },
    lvl1={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(14, x, y)
            else
                dr_tile(13, x, y)
            end
        end
    },
    lvl2={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(16, x, y)
            else
                dr_tile(15, x, y)
            end
        end
    },
    lvl3={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(18, x, y)
            else
                dr_tile(17, x, y)
            end
        end
    },
    lvl4={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(20, x, y)
            else
                dr_tile(19, x, y)
            end
        end
    },
    lvl5={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(23, x, y)
            else
                dr_tile(22, x, y)
            end
        end
    },
    lvl6={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(25, x, y)
            else
                dr_tile(24, x, y)
            end
        end
    },
    lvl7={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(27, x, y)
            else
                dr_tile(26, x, y)
            end 
        end
    },
    lvl8={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(29, x, y)
            else
                dr_tile(28, x, y)
            end
        end 
    },
    lvl9={
        dr = function(sq, x, y)
            if sq.trigger and not is_subset(sq.trigger, mode.history()) then
                dr_tile(-1, x, y)
            elseif sq.event and is_subset({detach_move_event(sq.event).."_solved"}, mode.history()) then
                dr_tile(31, x, y)
            else
                dr_tile(30, x, y)
            end
        end
    },
    pushup ={
        onEnter = function(e, sq)              
            if #events == 0  and not sq.entered then
                if dsq(sq,3) and (not dsq(sq,3).p) then
                    if e ==hero then
                        if dsq(sq,3).tile_special and not sub(dsq(sq,3).tile_special,1,4) =="push" then
                            mode.push = true
                        end

                        wait(15, setEnter, sq)
                        local db = mk_bullet(-10, -10, 0, 0)
                        db.life = 50
                        remove_buts()
                        
                        wait(24, goto_sq, e, dsq(sq,3))
                    else
                        wait(23, function () goto_sq(e, dsq(sq,3))  end)
                    end
                else
                    wait(30, play)
                    mode.push = false
                end
            end  
           
        end,

        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(44, x,y)
            else
                dr_tile(36, x, y)
            end
        end,
        upd = function(sq, x, y)
            if sq.entered and (sq.enter_turn +1 == mode.turns) then
               setEnter(sq)
            end
        end
    },
    pushdown={
        onEnter = function(e, sq)
            if #events == 0 and not sq.entered then
                if dsq(sq, 1) and (not dsq(sq, 1).p) then
                    if e ==hero then
                        if dsq(sq, 1).tile_special and not sub(dsq(sq, 1).tile_special,1,4) =="push" then
                            mode.push = true
                        end
                        wait(15, setEnter, sq)
                        local db = mk_bullet(-10, -10, 0, 0)
                        db.life = 50
                        remove_buts()
                        
                        wait(24, goto_sq, e, dsq(sq, 1))
                    else
                        wait(23, function () goto_sq(e, dsq(sq, 1))  end)
                    end
                else
                    wait(30, play)
                    mode.push = false
                end
            end  
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(45, x, y)
            else
                dr_tile(37, x, y)
            end
        end,

        upd = function(sq, x, y)
            if sq.entered and (sq.enter_turn +1 == mode.turns) then
               setEnter(sq)
            end
        end

    },
    pushleft={
        onEnter = function(e, sq)
            if #events == 0 and not sq.entered then
                if dsq(sq,2) and (not dsq(sq,2).p) then
                    if e ==hero then
                        if dsq(sq,2).tile_special and not sub(dsq(sq,2).tile_special,1,4) =="push" then
                            mode.push = true
                        end

                        wait(15, setEnter, sq)
                        local db = mk_bullet(-10, -10, 0, 0)
                        db.life = 50
                        remove_buts()
                        
                        wait(24, goto_sq, e, dsq(sq,2))
                    else
                        wait(23, function () goto_sq(e, dsq(sq,2))  end)
                    end
                else
                    wait(30, play)
                    mode.push = false
                end
            end  
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(43,x,y)
            else
                dr_tile(35, x, y)
            end
            
        end,

        upd = function(sq, x, y)
            if sq.entered and (sq.enter_turn +1 == mode.turns) then
               setEnter(sq)
            end
        end
    },
    pushright={
        onEnter = function(e, sq)
            if #events == 0 and not sq.entered then
                if dsq(sq,0) and (not dsq(sq,0).p) then
                    if e ==hero then
                        if dsq(sq,0).tile_special and not sub(dsq(sq,0).tile_special,1,4) =="push" then
                            mode.push = true
                        end

                        wait(15, setEnter, sq)
                        local db = mk_bullet(-10, -10, 0, 0)
                        db.life = 50
                        remove_buts()
                        
                        wait(24, goto_sq, e, dsq(sq,0))
                    else
                        wait(23, function () goto_sq(e, dsq(sq,0))  end)
                    end
                else
                    wait(30, play)
                    mode.push = false
                end
            end  
        end,
        dr = function(sq, x, y)
            if sq.entered then
                dr_tile(46, x, y)
            else
                dr_tile(38, x, y)
            end
            
        end,

        upd = function(sq, x, y)
            if sq.entered and (sq.enter_turn +1 == mode.turns) then
               setEnter(sq)
            end
        end
    }, 
    medal = {
        dr = function(sq, x, y)
            local up = gsq(sq.px, sq.py-1)
            if up and up.event then
                local lvl = tonum(sub(up.event[1], 6))
                if mode.cond_medal(lvl) == 1 then
                    dr_tile(42, x, y)
                elseif mode.cond_medal(lvl) == 2 then
                    dr_tile(41, x,y)
                elseif mode.cond_medal(lvl) == 3 then
                    dr_tile(40, x, y)
                elseif mode.cond_medal(lvl) == 4 then
                    dr_tile(39, x, y)
                else
                    dr_tile(-1, x, y)
                end
            end

        end
    }

}
