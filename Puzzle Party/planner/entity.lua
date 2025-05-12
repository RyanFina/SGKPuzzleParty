newsrf("planner/smol_entity.png", "smol_entities")
function dr_entity(id, x, y)
    local oldSp = spritesheet()
    spritesheet("smol_entities")
    -- sspr(id * 16, 0, 16, 16, x, y)
    spr(id, x, y)
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
function generate_dummy(name, px, py, info)
    local square = gsq(px, py)

    -- Function to create a new dummy table
    local function create_dummy()
        return {
            x = -1309,
            y = -1309,
            z = 0,
            tempo = 0,
            behavior = {},
            bad = true,
            type = -1,
            name = name,
            hp = 0,
            hp_max = 0,
            dr = function() end,
            upd = function() end,
            mark = {},
            sq = square,
            nocarry = 1,
            knockback = 100,
            iron = 1,
            inert = 1,
        }
    end

    -- Create a new dummy table for the square
    square.p = create_dummy()

    -- If info is provided, import it into the dummy table
    if info then
        tbl_import(square.p, info)
    end

    -- Update function for the square
    square.upd = function()
        if not square.p then
            square.p = create_dummy()
            if info then
                tbl_import(square.p, info)
            end
        end

        -- Additional logic for updating the square
        for ent in all(ents) do
            if ent.x == square.x and ent.y == square.y and ent.out and ent.over then
                ent.over = nil
                if stack.special == 'strafe' then
                    ent.right_clic = nil
                end

                if info and info.freelift then
                else
                    if stack.grab then
                        ent.on_drag = nil
                    end
                end

                ent.out()
                break
            end
        end
    end

    return square
end
entity = {

        altar={
            new_entity = function(px,py)
                local altar=mke()
                add_child(board,altar)
                altar.name="altar"
                altar.y=5*SQ
                altar.dp=DP_PIECES
                altar.c_deep=60+irnd(60)	
                local piece = generate_dummy(altar.name, px,py)
                return altar
            end,
            dr=function(e,x,y)
                if e.c_deep then
                    local c=e.c_deep/60
                    c=1-ease_out_back(1-c)
                    y=y+c*20
                    pal_inc(min(0,1-c*5))
                end
                spritesheet("tutorial")
                if mode.no_shotgun then
                    sspr(144,32,48,32,x,y)
                else
                    sspr(144,64,48,32,x,y)
                end
                spritesheet("gfx")
            end
        },
        castle={
            new_entity = function()
                    local castle=mke()
                    add_child(board,castle)
                    castle.name="castle"
                    castle.dp=DP_TOP
                    return castle
            end,
            dr=function(e,x,y)
                spritesheet("tutorial")
                sspr(16,0,192,30,-32,SQ*8)
                spritesheet("gfx")
            end
        },

        shotgun_pickup= {
            new_entity = function()
                shotgun_pickup=mke()
                shotgun_pickup.dp=DP_TOP
                shotgun_pickup.x=board.x+12
                shotgun_pickup.y=board.y+10+SQ*5
                shotgun_pickup.child_invis=true
                return shotgun_pickup
            end,
            dr=function(e,x,y)
                if e.anim_pickup then
                    if e.t < 170 then
                        circfill(x+12,y+4-e.t/17,15*e.t/170,4+cyc(2,8))
                        spritesheet("gfx")
                        sspr(112,0,24,8,x,y-e.t/17)
                    else
                        -- RAY
                        tcamera(-x,-y)
                        e.back=1
                        foreach(e.ents or {},dre)
                        e.back=nil
                        foreach(e.ents or {},dre)
                        tcamera(x,y)				
                        for i=0,1 do
                            if i==0 then fillp_dissolve(.5) end
                            circfill(x+12,y-6,20+(1-i)*8-cos(e.t/60)*5,5)
                            fillp()
                        end
                        
                        spritesheet("gfx")
                        sspr(112,0,24,8,x,y-10)
        
                    end
                else
                    spritesheet("gfx")
                    sspr(112,0,24,8,x,y+round(cos(t/150)))
                end
            end
        },

        wall = {
            new_entity = function(px, py)
                if gsq(px,py) then
                    local wall = mke()
                    add_child(board,wall)
                    wall.name= "wall"
                    wall.y=py*SQ-1
                    wall.x = px*SQ
                    wall.dp=DP_PIECES
                    local piece = generate_dummy(wall.name, px,py)
                    return wall
                end
            end,
            dr= function(_,x,y)
                dr_entity(19,x,y)
            end,
        },

        door={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local door = mke()
                    door.inter = false
                    add_child(board,door)
                    door.name= "door"
                    door.y=py*SQ-1
                    door.x = px*SQ
                    door.dp=DP_PIECES
                    local piece = generate_dummy(door.name, px,py)
                    piece.upd = function()
                        if (gsq(px,py).p and gsq(px,py).p.event and is_subset(gsq(px,py).p.event, mode.history())) then
                            sfx("shoot")
                            door.inter = true
                            gsq(px,py).p = nil 
                            gsq(px,py).op = nil 
                            gsq(px,py).highlight = true 
                            gsq(px,py).danger = {}
                            if hero then
                                remove_buts()
                                play()
                            end
                        end
                    end
                    return door
                end
            end,
            dr= function(e,x,y)
                -- interacted door condition
                if e.inter then
                    dr_entity(9,x,y)
                else
                    dr_entity(8,x,y)
                end    
            end,
        },

        plant={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local plant = mke()
                    local square = gsq(px,py)
                    add_child(board,plant)
                    plant.inter= false
                    plant.name= "plant"
                    plant.y=py*SQ-1
                    plant.x = px*SQ
                    plant.dp=DP_PIECES
                    local piece = generate_dummy(plant.name, px,py)
                    piece.upd = function(self)
                        if square and square.p and square.p.event and not plant.inter then
                            if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                               (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                             plant.inter = true
                             if hero then
                                 remove_buts()
                                 play()
                             end
                            end           
                        end
                    end
                    return plant
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(1,x,y)
                else
                    dr_entity(0,x,y)
                end    
            end,
        },
  
        removeable_plant = {
            new_entity = function(px, py)
                if gsq(px,py) then
                    local removeable_plant = mke()
                    local square = gsq(px,py)
                    add_child(board,removeable_plant)
                    removeable_plant.inter= false
                    removeable_plant.name= "removeable_plant"
                    removeable_plant.y=py*SQ-1
                    removeable_plant.x = px*SQ
                    removeable_plant.dp=DP_PIECES
                    local piece = generate_dummy(removeable_plant.name, px,py)
                    piece.upd = function(self)
                        if square and square.p and square.p.event and not removeable_plant.inter then
                            if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                               (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                             removeable_plant.inter = true
                             if hero then
                                remove_buts()
                                play()
                             end
                            end           
                        end
                    end
                    return removeable_plant
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(1,x,y) -- WIP, need better destroy plant pot
                else
                    dr_entity(0,x,y)
                end    
            end,
        },
        chest={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local chest = mke()
                    local square = gsq(px,py)
                    add_child(board,chest)
                    chest.inter= false
                    chest.name= "chest"
                    chest.y=py*SQ-1
                    chest.x = px*SQ
                    chest.dp=DP_PIECES
                    local piece = generate_dummy(chest.name, px,py)
                    piece.upd = function(self)
                        if square and square.p and square.p.event and not chest.inter then
                            if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                               (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                             chest.inter = true
                             if hero then
                                remove_buts()
                                play()
                             end
                            end           
                        end
                    end
                    return chest
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(3,x,y)
                else
                    dr_entity(2,x,y)
                end    
            end
        },

        keychest={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local keychest = mke()
                    local square = gsq(px,py)
                    add_child(board,keychest)
                    keychest.inter= false
                    keychest.name= "keychest"
                    keychest.y=py*SQ-1
                    keychest.x = px*SQ
                    keychest.dp=DP_PIECES
                    local piece = generate_dummy(keychest.name, px,py)
                    piece.upd = function(self)
                        if square and square.p and square.p.event and not keychest.inter then
                            if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                               (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                             keychest.inter = true
                             if hero then
                                remove_buts()
                                play()
                             end
                            end           
                        end
                    end
                    return keychest
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(7,x,y)
                else
                    dr_entity(6,x,y)
                end    
            end
        },

        keydoor={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local keydoor = mke()
                    add_child(board,keydoor)
                    keydoor.inter= false
                    keydoor.name= "keydoor"
                    keydoor.y=py*SQ-1
                    keydoor.x = px*SQ
                    keydoor.dp=DP_PIECES
                    local piece = generate_dummy(keydoor.name, px,py)
                    piece.upd = function(self)
                        if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                            keydoor.inter = true
                            gsq(px,py).p = nil 
                            gsq(px,py).op = nil 
                            gsq(px,py).highlight = true 
                            gsq(px,py).danger = {}
                            if hero then
                                remove_buts()
                                play()
                            end
                        end
                    end
                    return keydoor
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(11,x,y)
                else
                    dr_entity(10,x,y)
                end    
            end
        },

        keychest2={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local keychest2 = mke()
                    local square = gsq(px,py)
                    add_child(board, keychest2)
                    keychest2.inter = false
                    keychest2.name= "keychest2"
                    keychest2.y = py * SQ - 1
                    keychest2.x = px * SQ
                    keychest2.dp = DP_PIECES
                    keychest2.upd = function()
                        if square and square.p and square.p.event and not keychest2.inter then
                            if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                               (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                                keychest2.inter = true
                                if hero then
                                    remove_buts()
                                    play()
                                end
                            end           
                        end
                    end
                    return keychest2
                end
            end,
            dr= function(e,x,y)
                 if e.inter then
                    dr_entity(5, x, y)
                else
                    dr_entity(4, x, y)
                end
            end
        },
  
        keydoor2={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local keydoor2 = mke()
                    add_child(board, keydoor2)
                    keydoor2.inter = false
                    keydoor2.name= "keydoor2"
                    keydoor2.y = py * SQ - 1
                    keydoor2.x = px * SQ
                    keydoor2.dp = DP_PIECES
                    keydoor2.upd = function()
                        if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                            keydoor2.inter = true
                            gsq(px,py).p = nil 
                            gsq(px,py).op = nil 
                            gsq(px,py).highlight = true 
                            gsq(px,py).danger = {}    
                            if hero then
                                remove_buts()
                                play()
                            end
                        end
                    end
                    return keydoor2
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(13, x, y)
                else
                    dr_entity(12, x, y)
                end
            end
        },

        passdoor={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local passdoor = mke()
                    add_child(board, passdoor)
                    passdoor.inter = false
                    passdoor.name= "passdoor"
                    passdoor.y = py * SQ - 1
                    passdoor.x = px * SQ
                    passdoor.dp = DP_PIECES
                    passdoor.upd = function()
                        if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                            passdoor.inter = true
                            gsq(px,py).p = nil 
                            gsq(px,py).op = nil 
                            gsq(px,py).highlight = true 
                            gsq(px,py).danger = {}    
                            if hero then
                                remove_buts()
                                play()
                            end
                        end
                    end
                    return passdoor
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(15, x, y)
                else
                    dr_entity(14, x, y)
                end
            end
        },

        passcode={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local passcode = mke()
                    add_child(board, passcode)
                    passcode.name= "passcode"
                    passcode.y = py * SQ - 1
                    passcode.x = px * SQ
                    passcode.dp = DP_PIECES
                    return passcode
                end
            end,
            dr= function(e,x,y)
                dr_entity(16, x, y)
            end
        },

        cursedwall={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local cursedwall = mke()
                    add_child(board, cursedwall)
                    cursedwall.name= "cursedwall"
                    cursedwall.y = py * SQ - 1
                    cursedwall.x = px * SQ
                    cursedwall.dp = DP_PIECES
                    return cursedwall
                end
            end,
            dr= function(e,x,y)
                dr_entity(17, x, y)
            end
        },

        crackedwall={
            new_entity = function(px, py)
                if gsq(px,py) then
                    local crackedwall = mke()
                    add_child(board, crackedwall)
                    crackedwall.name= "crackedwall"
                    crackedwall.inter = false
                    crackedwall.y = py * SQ - 1
                    crackedwall.x = px * SQ
                    crackedwall.dp = DP_PIECES
                    crackedwall.upd = function()
                        if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                            sfx("shoot")
                            crackedwall.inter = true
                            gsq(px,py).p = nil 
                            gsq(px,py).op = nil 
                            gsq(px,py).highlight = true 
                            gsq(px,py).danger = {}
                            sfx("boulder_xpl")
                            if hero then
                                remove_buts()
                                play()
                            end
                        end
                    end
                    return crackedwall
                end
            end,
            dr= function(e,x,y)
                if e.inter then
                    dr_entity(11, x, y) -- WIP, better destroy wall
                else
                    dr_entity(18, x, y)
                end
            end,
        },

        secrettable = function(px, py)
            local secrettable = mke()
            add_child(board, secrettable)
            secrettable.name= "secrettable"
            secrettable.y = py * SQ - 1
            secrettable.x = px * SQ
            secrettable.dp = DP_PIECES
            secrettable.dr = function(e, x, y)
                dr_entity(20, x, y)
            end
            return secrettable
        end,

        barrel = {
            new_entity = function(px, py)
                if gsq(px,py) then
                    local barrel = mke()
                    add_child(board,barrel)
                    barrel.name= "barrel"
                    barrel.y=py*SQ-1
                    barrel.x = px*SQ
                    barrel.dp=DP_PIECES
                    local piece = generate_dummy(barrel.name, px,py,{freelift=1})
                    return barrel
                end
            end,
            dr= function(_,x,y)
                dr_entity(21,x,y)
            end,
        },

}