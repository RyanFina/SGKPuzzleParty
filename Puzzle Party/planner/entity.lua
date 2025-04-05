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

test= 0
entity = {
    event={
        altar = function ()
            local altar=mke()
            add_child(board,altar)
            altar.name="altar"
            altar.y=5*SQ
            altar.dp=DP_PIECES
            altar.c_deep=60+irnd(60)	
            altar.dr=function(e,x,y)
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
            return altar
        end,
        castle=function()
            local castle=mke()
            add_child(board,castle)
            castle.name="castle"
            castle.dp=DP_TOP
            castle.dr=function(e,x,y)
                spritesheet("tutorial")
                sspr(16,0,192,30,-32,SQ*8)
                spritesheet("gfx")
            end
            if #events == 0 then
                return true
            end
            return castle
        end,
        shotgun_pickup = function ()
            shotgun_pickup=mke()

            shotgun_pickup.dp=DP_TOP
            shotgun_pickup.x=board.x+12
            shotgun_pickup.y=board.y+10+SQ*5
            shotgun_pickup.child_invis=true
            shotgun_pickup.dr=function(e,x,y)
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
            return shotgun_pickup
        end,
    },
    breached={
        wall = function(px,py)
            local wall = mke()
            add_child(board,wall)
            wall.name= "wall"
            wall.y=py*SQ-1
            wall.x = px*SQ
            wall.dp=DP_PIECES
            wall.dr=function(e,x,y)
                dr_entity(19,x,y)
            end
            return wall
        end,
        door = function(px, py)
            local door = mke()
            local inter = false
            add_child(board,door)
            door.name= "door"
            door.y=py*SQ-1
            door.x = px*SQ
            door.dp=DP_PIECES
         
            door.dr=function(e,x,y)
                -- interacted door condition
                if inter then
                    dr_entity(9,x,y)
                else
                    dr_entity(8,x,y)
                end    
            end
            door.upd = function()
                if (gsq(px,py).p and gsq(px,py).p.event and is_subset(gsq(px,py).p.event, mode.history())) then
                    sfx("shoot")
                    inter = true
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
        end,
        plant = function(px, py)
            local plant = mke()
            local inter= false
            local square = gsq(px,py)
            add_child(board,plant)
            plant.name= "plant"
            plant.y=py*SQ-1
            plant.x = px*SQ
            plant.dp=DP_PIECES
            plant.dr=function(e,x,y)
                if inter then
                    dr_entity(1,x,y)
                else
                    dr_entity(0,x,y)
                end
            end
            plant.upd = function()
                if square and square.p and square.p.event and not inter then
                    if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                       (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                        inter = true
                        if hero then
                            remove_buts()
                            play()
                        end
                    end           
                end
            end
            return plant
        end,
        removeable_plant = function(px, py)
            local removeable_plant = mke()
            local inter= false
            local square = gsq(px,py)
            add_child(board,removeable_plant)
            removeable_plant.name= "removeable_plant"
            removeable_plant.y=py*SQ-1
            removeable_plant.x = px*SQ
            removeable_plant.dp=DP_PIECES
            removeable_plant.dr=function(e,x,y)
                if inter then
                    dr_entity(1,x,y) -- WIP, need better destroy plant pot
                else
                    dr_entity(0,x,y)
                end
            end
            removeable_plant.upd = function()
                if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                    inter = true
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
            return removeable_plant
        end,
        chest = function(px, py)
            local chest = mke()
            local inter = false
            local square = gsq(px,py)
            add_child(board, chest)
            chest.name= "chest"
            chest.y = py * SQ - 1
            chest.x = px * SQ
            chest.dp = DP_PIECES
            chest.dr = function(e, x, y)
                if inter then
                    dr_entity(3, x, y)
                else
                    dr_entity(2, x, y)    
                end
            end
            chest.upd= function()
                if square and square.p and square.p.event and not inter then
                    if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                       (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                        inter = true
                        if hero then
                            remove_buts()
                            play()
                        end
                    end           
                end
            end
            return chest
        end,

        keychest = function(px, py)
            local keychest = mke()
            local inter = false
            local square = gsq(px,py)
            add_child(board, keychest)
            keychest.name= "keychest"
            keychest.y = py * SQ - 1
            keychest.x = px * SQ
            keychest.dp = DP_PIECES
            keychest.dr = function(e, x, y)
                if inter then
                    dr_entity(7, x, y)
                else
                    dr_entity(6, x, y)
                end
            end
            keychest.upd = function()
                if square and square.p and square.p.event and not inter then
                    if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                       (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                        inter = true
                        if hero then
                            remove_buts()
                            play()
                        end
                    end           
                end
            end
            return keychest
        end,
        keydoor = function(px, py)
            local keydoor = mke()
            local inter = false
            add_child(board, keydoor)
            keydoor.name= "keydoor"
            keydoor.y = py * SQ - 1
            keydoor.x = px * SQ
            keydoor.dp = DP_PIECES
            keydoor.dr = function(e, x, y)
                if inter then
                    dr_entity(11, x, y)
                else
                    dr_entity(10, x, y)
                end
            end
            keydoor.upd = function()
                if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                    inter = true
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
        end,
        keychest2 = function(px, py)
            local keychest2 = mke()
            local inter = false
            local square = gsq(px,py)
            add_child(board, keychest2)
            keychest2.name= "keychest2"
            keychest2.y = py * SQ - 1
            keychest2.x = px * SQ
            keychest2.dp = DP_PIECES
            keychest2.dr = function(e, x, y)
                if inter then
                    dr_entity(5, x, y)
                else
                    dr_entity(4, x, y)
                end
            end
            keychest2.upd = function()
                if square and square.p and square.p.event and not inter then
                    if (square.p.repeatable == nil and is_subset({gsq(px,py).p.event[1]}, mode.history())) or
                       (square.p.repeatable ~=nil and is_subset(gsq(px,py).p.event, mode.history())) then
                        inter = true
                        if hero then
                            remove_buts()
                            play()
                        end
                    end           
                end
            end
            return keychest2
        end,
        keydoor2 = function(px, py)
            local keydoor2 = mke()
            local inter = false
            add_child(board, keydoor2)
            keydoor2.name= "keydoor2"
            keydoor2.y = py * SQ - 1
            keydoor2.x = px * SQ
            keydoor2.dp = DP_PIECES
            keydoor2.dr = function(e, x, y)
                if inter then
                    dr_entity(13, x, y)
                else
                    dr_entity(12, x, y)
                end
            end
            keydoor2.upd = function()
                if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                    inter = true
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
        end,
        passdoor = function(px, py)
            local passdoor = mke()
            local inter = false
            add_child(board, passdoor)
            passdoor.name= "passdoor"
            passdoor.y = py * SQ - 1
            passdoor.x = px * SQ
            passdoor.dp = DP_PIECES
            passdoor.dr = function(e, x, y)
                if inter then
                    dr_entity(15, x, y)
                else
                    dr_entity(14, x, y)
                end
            end
            passdoor.upd = function()
                if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                    inter = true
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
        end,
        passcode = function(px, py)
            local passcode = mke()
            add_child(board, passcode)
            passcode.name= "passcode"
            passcode.y = py * SQ - 1
            passcode.x = px * SQ
            passcode.dp = DP_PIECES
            passcode.dr = function(e, x, y)
                dr_entity(16, x, y)
            end
            return passcode
        end,

        cursedwall = function(px, py)
            local cursedwall = mke()
            add_child(board, cursedwall)
            cursedwall.name= "cursedwall"
            cursedwall.y = py * SQ - 1
            cursedwall.x = px * SQ
            cursedwall.dp = DP_PIECES
            cursedwall.dr = function(e, x, y)
                dr_entity(17, x, y)
            end
            return cursedwall
        end,
        crackedwall = function(px, py)
            local crackedwall = mke()
            local inter = false
            add_child(board, crackedwall)
            crackedwall.name= "crackedwall"
            crackedwall.y = py * SQ - 1
            crackedwall.x = px * SQ
            crackedwall.dp = DP_PIECES
            crackedwall.dr = function(e, x, y)
                if inter then
                    dr_entity(11, x, y) -- WIP, better destroy wall
                else
                    dr_entity(18, x, y)
                end
            end
            crackedwall.upd = function()
                if (gsq(px, py).p and gsq(px, py).p.event and is_subset(gsq(px, py).p.event, mode.history())) then
                    sfx("shoot")
                    inter = true
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
        end,
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
    },
    puzzle = {
        barrel = function(px, py)
            local barrel = mke()
            add_child(board,barrel)
            barrel.name= "barrel"
            barrel.y=py*SQ-1
            barrel.x = px*SQ
            barrel.dp=DP_PIECES
            barrel.dr=function(e,x,y)
                dr_entity(21,x,y)
            end
            return barrel
        end,
        wall = function(px,py)
            local wall = mke()
            add_child(board,wall)
            wall.name= "wall"
            wall.y=py*SQ-1
            wall.x = px*SQ
            wall.dp=DP_PIECES
            wall.dr=function(e,x,y)
                dr_entity(19,x,y)
            end
            return wall
        end,
    }
}