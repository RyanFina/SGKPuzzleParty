-- Adding new custom cards.
local new_cards = {
    { gid=0, team=0, n=50, pwe=0, id="Pawn",	type_piece=0, piece=1, undead=1 },
    { gid=1, team=0, n=50, pwe=0, id="Knight", type_piece=1, piece=1, undead=1 },
    { gid=2, team=0, n=50, pwe=0, id="Bishop",type_piece=2, piece=1, undead=1 },
    { gid=3, team=0, n=50, pwe=0, id="Rook", type_piece=3, piece=1, undead=1 },
    { gid=4, team=0, n=50, pwe=0, id="Queen", type_piece=4, piece=1, undead=1 },
    { gid=5, team=0, n=50, pwe=0, id="King", type_piece=5, piece=1, undead=1 },
    { gid=6, team=0, n=50, pwe=0, id="Gryphon", type_piece=gryphon_typ, piece=1, undead=1 },
    { gid=7, team=0, n=50, pwe=0, id="Nightrider", type_piece=nightrider_typ, piece=1, undead=1 },
    { gid=8, team=0, n=50, pwe=0, id="Mini Knight", type_piece=minknight_typ, piece=1, undead=1 },
    { gid=9, team=0, n=50, pwe=0, id="Patrol", type_piece=patrol_typ, piece=1, undead=1 },
    { gid=10, team=0, n=50, pwe=0, id="Down", type_tile="down", tile=1},
    { gid=11, team=0, n=50, pwe=0, id="Up", type_tile="up", tile=1},
    { gid=12, team=0, n=50, pwe=0, id="Left", type_tile="left", tile=1},
    { gid=13, team=0, n=50, pwe=0, id="Right", type_tile="right", tile=1},
    { gid=14, team=0, n=50, pwe=0, id="Push Up", type_tile="pushup", tile=1},
    { gid=15, team=0, n=50, pwe=0, id="Push Down", type_tile="pushdown", tile=1},
    { gid=16, team=0, n=50, pwe=0, id="Push Left", type_tile="pushleft", tile=1},
    { gid=17, team=0, n=50, pwe=0, id="Push Right", type_tile="pushright", tile=1},
    { gid=18, team=0, n=50, pwe=0, id="Moat", type_tile="moat", tile=1},
    { gid=19, team=0, n=50, pwe=0, id="Normal", type_tile="normalize", tile=1},

}

local exclude = {
}

concat(CARDS, new_cards)
concat(EXCLUDE, exclude)

-- general card properties
for ca in all(new_cards) do
	ca.spsheet = "samplemod_cards"
	ca.played = 1
	ca.ignored = 0
	if ca.piece then
      ca.need = ca.need or {}
      add(ca.need,8)
      ca.need_surrender = 1
   end
end

return new_cards