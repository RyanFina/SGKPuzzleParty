newsrf("pieces.png", "pieces")
newsrf("movemap.png", "movemap")

local test = require("test.lua")

for i = 1, #PIECES, 1 do
	PIECES[i].custom_dr= function(e,x,y,angle)
		spritesheet("pieces")
		spr(e.iron and 2*i-1 or 2*i-2, x, y)
		spritesheet("gfx")
	end
end

gryphon_typ = #PIECES
lang["piece_"..gryphon_typ] = "Gryphon"
lang["short_piece_"..gryphon_typ] = "Gryphn"

add(PIECES, {type=gryphon_typ,
	name="gryphon", hp=4, tempo=4, danger=9, seek="rdist",
	give_soul=true, hdy=0, cus_move=true,
	behavior={
		{ id="offset",0,1,8, move=1, atk=1, off={1,1}},
		{ id="offset",1,2,8, move=1, atk=1, off={-1,1}},
		{ id="offset",2,3,8, move=1, atk=1, off={-1,-1}},
		{ id="offset",0,0,8, move=1, atk=1, off={1,-1}},
		{ id="offset",3,3,8, move=1, atk=1, off={1,-1}},
	},
	custom_dr = function(e,x,y,angle)
		spritesheet("pieces")
		spr(e.iron and 13 or 12, x, y)
	end,
	custom_move_dr2 = function(x,y)
		spritesheet("movemap")
		spr(12, x, y, 2, 2)
	end
})

-- SEQ moves
nightrider_typ = #PIECES
lang["piece_"..nightrider_typ] = "Nightrider"
lang["short_piece_"..nightrider_typ] = "NitRdr"

add(PIECES, {type=nightrider_typ,
	name="nightrider", hp=4, tempo=5, danger=6, seek="kdist",
	give_soul=true, hdy=0, cus_move=true,
	behavior={
		{ id="seq", move=1, atk=1, 1,2, 2,4, 3,6, 4,8 },
		{ id="seq", move=1, atk=1, 2,1, 4,2, 6,3, 8,4 },
		{ id="seq", move=1, atk=1, 2,-1, 4,-2, 6,-3, 8,-4 },
		{ id="seq", move=1, atk=1, 1,-2, 2,-4, 3,-6, 4,-8 },
		{ id="seq", move=1, atk=1, -1,-2, -2,-4, -3,-6, -4,-8 },
		{ id="seq", move=1, atk=1, -2,-1, -4,-2, -6,-3, -8,-4 },
		{ id="seq", move=1, atk=1, -2,1, -4,2, -6,3, -8,4 },
		{ id="seq", move=1, atk=1, -1,2, -2,4, -3,6, -4,8 },
	},
	custom_dr = function(e,x,y,angle)
		spritesheet("pieces")
		spr(e.iron and 15 or 14, x, y)
	end,
	custom_move_dr2 = function(x,y)
		spritesheet("movemap")
		spr(2, x, y, 2, 2)
	end
})
-- CUSTOM with jump combo
minknight_typ = #PIECES
lang["piece_"..minknight_typ] = "Mino Knight"
lang["short_piece_"..minknight_typ] = "MinKni"

add(PIECES, {type=minknight_typ,
	name="minknight", hp=4, tempo=4, danger=3, seek="wdist",
	give_soul=true, hdy=0, cus_move=true,
	behavior={
		{ id="offset",4,5,8, move=1, atk=1, off={0,1}},
		{ id="jumpc", move=1, atk=1, -2,-1, -1,-2, 1,-2, 2,-1},
	},
	custom_dr = function(e,x,y,angle)
		spritesheet("pieces")
		spr(e.iron and 17 or 16, x, y)
	end,
	custom_move_dr2 = function(x,y)
		spritesheet("movemap")
		spr(4, x, y, 2, 2)
	end
})
patrol_typ = #PIECES
lang["piece_"..patrol_typ] = "Patrol Soldier"
lang["short_piece_"..patrol_typ] = "Patrol"

add(PIECES, {type=patrol_typ,
	name="patrol", hp=4, tempo=4, danger=6, seek="kdist",
	hdy=0, cus_move=true,
	behavior={
		-- { id="clockwork", move=1, 0,1, 0,1},
		-- { id="clockwork", move=1,  1, 0, 1, 0},
		-- { id="clockwork", move=1,  0,-1, 0,-1},
		-- { id="clockwork", move=1, atk=1,  -1, 0, -1, 0},
	},
	custom_dr = function(e,x,y,angle)
		spritesheet("pieces")
		spr(e.iron and 21 or 20, x, y)
	end,
})
function add_bsq(e, sq, m, a)
	local x, y
	if m == nil then
		m = 1
	end
	if a == nil then
		a = 1
	end
	if not e.sq then
		x, y = hero.sq.px, hero.sq.py
	else
		x, y = e.sq.px, e.sq.py
	end
	if (sq) then
		add(e.behavior, {id="jump", move=m, atk=a, sq.px - x, sq.py - y})
	end
end
function checksq(x, y, e, ss, m, a)
	if ss == nil then
		ss = e.sq
	end
	xx2 = ss.px + x
	yy2 = ss.py + y
	if (gsq(xx2, yy2)) then
		sq = gsq(xx2, yy2)
	else
		return false
	end
	if(sq.moat and not ss.moat) then
		add_bsq(e, sq, m, a)
		if e.flying then
			return true
		end
		return false
	elseif (sq.p == nil or sq.p == hero) then
		add_bsq(e, sq, m, a)
		return true
	else
		if e.flying then
			add_bsq(e, sq, m, a)
			return true
		end
		return false
	end
end

function mod_range(e, sq)
	if sq == nil then
		sq = e.sq
	end
	for kbeh, beh in ipairs(e.behavior) do
		-- Line move offsetted by a sequence of moves
		if (beh.id == "offset") then
			lin_start = true
			dummy_piece = {sq = sq, flying = e.flying, behavior = {}}
			spos = {0, 0}
			lstart = beh[1] * 2 + 2
			lfin = beh[2] * 2 + 2
			max_r = min(e.cage or beh[3], beh[3]) - 1
			if not checksq(beh.off[1], beh.off[2], dummy_piece, sq, beh.move, beh.atk) then
				lin_start = false
			else
				spos = {beh.off[1], beh.off[2]}
			end
			if (lin_start) then
				checksq(spos[1], spos[2], e, sq, beh.move, beh.atk)
				for i = lstart, lfin, 2 do
					xx,yy = spos[1], spos[2]
					xxx = DIRS[i-1]
					yyy = DIRS[i]
					for j = 1, max_r do
						xx = xx + xxx
						yy = yy + yyy
						if not checksq(xx, yy, e, sq, beh.move, beh.atk) then
							break
						end
					end
				end
			end
		-- Sequence of moves
		elseif (beh.id == "seq") then
			range = min(e.cage or #beh / 2, #beh / 2) * 2
			for i = 2, range, 2 do
				if not checksq(beh[i - 1], beh[i], e, sq, beh.move, beh.atk) then
					break
				end
			end
		-- Jump moves for custom pieces using the previous sets, will not be deleted after get_range()
		elseif (beh.id == "jumpc") then
			beh2 = clone(beh, true)
			beh2.id = "jump"
			add(e.behavior, beh2)

		elseif beh.id =="clockwork" and e.sq then
			e.turn = e.turn or 1
			e.buffer = e.buffer or 0
			e.give_soul = false
			if e.turn ~= mode.turns and mode.turns >0 then
				if (e.turn -1 -e.buffer) % e.tempo == kbeh-1 then 
					for index = 2, #beh, 2 do
						local off_sq = gsq(e.sq.px + beh[index-1], e.sq.py + beh[index])
						if off_sq then
							if off_sq.p == nil and beh.move then
								goto_sq(e, off_sq)

							elseif gsq(e.sq.px + beh[index-1], e.sq.py + beh[index]).p == hero and beh.atk then
								goto_sq(e, hero.sq)
								wait(TEMPO, function()
									xpl_king(hero) 
								end)
								local next_beh = kbeh ==#e.behavior and 1 or kbeh+1
								break
							else
								e.buffer = e.buffer + 1
								break
							end
						end
					end
					e.turn = mode.turns
				end
			end
		end
	end
end
function placeable(sq)
	return is_free(sq)
end
function clear_range(e)
	dellist = {}
	if (e.behavior) then
		for k, beh in pairs(e.behavior) do
			if (beh.id == "jump") then
				add(dellist, k)
			end
		end
		for l = #dellist, 1, -1 do
			deli(e.behavior, dellist[l])
		end
	end
end

prepend("get_range", function(e, b)
	-- Custom behavior
	-- If a piece has "cus_move=true", then use the following move defs, then delete all "jump" moves after move calculation
	if (e.cus_move and e.behavior) then
		mod_range(e)
	end

	if (b == "move") then
		if (e == hero and e.sq) then
			for piece in all(PIECES) do
				if (piece.behavior and piece.cus_move) then
					mod_range(piece, e.sq)
				end
			end
		end
	end
end, "some_pieces:gr")

append("get_range", function(e, b)
	if (e.cus_move and e.behavior) then
		clear_range(e)
	end
	if (b == "move") then
		if (e == hero and e.sq) then
			for piece in all(PIECES) do
				if (piece.behavior and piece.cus_move) then
					clear_range(piece)
				end
			end
		end
	end
end, "some_pieces:gr2")
prepend("dr_movemap", function(e,x,y)
	if e.custom_move_dr2 then
		if e.banner then
			spritesheet("pieces")
			spr(54, x, y, 2, 2)
		else
			print(e.custom_move_dr2(x,y))
		end
		spritesheet("gfx")
	end
end, "some_pieces:dmm")

