newsrf("planner/smol_entity.png", "smol_entities")
newsrf("planner/mid_entity.png", "mid_entities")
function dr_entity(id, x, y)
    local oldSp = spritesheet()
    spritesheet("smol_entities")
    -- sspr(id * 16, 0, 16, 16, x, y)
    spr(id, x, y)
    spritesheet(oldSp)
end

function dr_mid_entity(id, x, y)
    local oldSp = spritesheet()
    spritesheet("mid_entities")
    sspr(id * 48, 0, 48, 48, x-16, y-32)
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
end

function create_singular_entity(name, id, info)
    local tbl = {
        new_entity = function(px, py)
            if gsq(px,py) then
                local ent = mke()
                add_child(board,ent)
                ent.name= name
                ent.y=py*SQ-1
                ent.x = px*SQ
                ent.dp=DP_PIECES
                generate_dummy(ent.name, px,py, info)
                return ent
            end
        end,
        dr= function(_,x,y)
            if type(id)=="number" then
                dr_entity(id,x,y)
            elseif type(id)=="table" then
                local start, endd, duration = unpack(id)
                dr_entity(cyc(endd-start, duration)+start,x,y)
            end
        end,
    }
    entity[name] = tbl
end

function create_double_state_entity(name, id1, id2, self_destruct, f, info)
    local tbl ={
        new_entity = function(px, py)
            if gsq(px,py) then
                local ent = mke()
                local square = gsq(px,py)
                add_child(board,ent)
                ent.inter= false
                ent.name= name
                ent.y=py*SQ-1
                ent.x = px*SQ
                ent.dp=DP_PIECES
                generate_dummy(ent.name, px,py, info)
                square.upd = function(self)
                    if square and square.p and square.p.event and not ent.inter then
                        if (square.p.repeatable == nil and is_subset({square.p.event[1]}, history)) or
                            (square.p.repeatable ~=nil and is_subset(square.p.event, history)) then
                            ent.inter = true
                            if self_destruct then
                                square.p = nil 
                                square.op = nil 
                                square.highlight = true 
                                square.danger = {}
                            end
                            if f then
                                f()
                            end
                            if hero then
                            remove_buts()
                            play()
                            end
                        end           
                    end
                end
                return ent
            end
        end,
        dr= function(e,x,y)
            if e.inter then
                if type(id2)=="number" then
                    dr_entity(id2,x,y)
                elseif type(id2)=="table" then
                    local start, endd, duration = unpack(id2)
                    dr_entity(cyc(endd-start+1, duration)+start,x,y)
                end
            else
                if type(id1)=="number" then
                    dr_entity(id1,x,y)
                elseif type(id1)=="table" then
                    local start, endd, duration = unpack(id1)
                    dr_entity(cyc(endd-start+1, duration)+start,x,y)
                end
            end    
        end,
    }
    entity[name] = tbl
end

function create_singular_mid_entity(name, id, info)
    local tbl = {
        new_entity = function(px, py)
            if gsq(px,py) then
                local ent = mke()
                add_child(board,ent)
                ent.name= name
                ent.y=py*SQ-1
                ent.x = px*SQ
                ent.dp=DP_PIECES
                generate_dummy(ent.name, px,py, info)
                return ent
            end
        end,
        dr= function(_,x,y)
            if type(id)=="number" then
                dr_mid_entity(id,x,y)
            elseif type(id)=="table" then
                local start, endd, duration = unpack(id)
                dr_mid_entity(cyc(endd-start, duration)+start,x,y)
            end
        end,
    }
    entity[name] = tbl
end

function create_double_state_mid_entity(name, id1, id2, self_destruct, f, info)
    local tbl ={
        new_entity = function(px, py)
            if gsq(px,py) then
                local ent = mke()
                local square = gsq(px,py)
                add_child(board,ent)
                ent.inter= false
                ent.name= name
                ent.y=py*SQ-1
                ent.x = px*SQ
                ent.dp=DP_PIECES
                generate_dummy(ent.name, px,py, info)
                square.upd = function(self)
                    if square and square.p and square.p.event and not ent.inter then
                        if (square.p.repeatable == nil and is_subset({square.p.event[1]}, history)) or
                            (square.p.repeatable ~=nil and is_subset(square.p.event, history)) then
                            
                            ent.inter = true
                            if self_destruct then
                                square.p = nil 
                                square.op = nil 
                                square.highlight = true 
                                square.danger = {}
                            end
                            if f then
                                f()
                            end
                            if hero then
                            remove_buts()
                            play()
                            end
                        end           
                    end
                end
                return ent
            end
        end,
        dr= function(e,x,y)
            if e.inter then
                if type(id2)=="number" then
                    dr_mid_entity(id2,x,y)
                elseif type(id2)=="table" then
                    local start, endd, duration = unpack(id2)
                    dr_mid_entity(cyc(endd-start+1, duration)+start,x,y)
                end
            else
                if type(id1)=="number" then
                    dr_mid_entity(id1,x,y)
                elseif type(id1)=="table" then
                    local start, endd, duration = unpack(id1)
                    dr_mid_entity(cyc(endd-start+1, duration)+start,x,y)
                end
            end    
        end,
    }
    entity[name] = tbl
end

entity = {
        altar={
            new_entity = function(px,py)
                local altar=mke()
                add_child(board,altar)
                altar.name="altar"
                altar.y=5*SQ-1
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
                sspr(16,0,192,30,-32,SQ*40)
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
}

create_double_state_entity("plant", 0,1, false, nil, {freelift=1, iron= false})
create_double_state_entity("chest", 2,3)
create_double_state_entity("keychest2",4,5)
create_double_state_entity("keychest",6,7)
create_double_state_entity("door", 8, 9, true, bind(sfx, "shoot"))
create_double_state_entity("keydoor",10,11, true)
create_double_state_entity("keydoor2",12,13, true)
create_double_state_entity("passdoor",14,15, true)
create_double_state_entity("crackedwall",18,11, true, bind(sfx, "boulder_xpl"))
create_double_state_entity("pot1",38,39, false, nil, {freelift=1, iron= false})
create_double_state_entity("pot2",40,41, false, nil, {freelift=1, iron= false})
create_double_state_entity("pot3",42,43, false, nil, {freelift=1, iron= false})
create_double_state_entity("pot4",44,45, false, nil, {freelift=1, iron= false})
create_double_state_entity("camp_fire",49,{46,48,15})
create_double_state_entity("candle",{50,53,15},54, false, nil, {freelift=1, iron= false})

create_singular_entity("passcode",16)
create_singular_entity("wall",19)
create_singular_entity("barrier",19)
create_singular_entity("cursedwall",17)
create_singular_entity("secrettable",20)
create_singular_entity("barrel", 21, {freelift=1})

create_singular_entity("left_horizontal_wall",22)
create_singular_entity("middle_horizontal_wall",23)
create_singular_entity("right_horizontal_wall",24)
create_singular_entity("top_left_lg_wall",26)
create_singular_entity("top_middle_lg_wall",27)
create_singular_entity("top_right_lg_wall",28)
create_singular_entity("mid_left_lg_wall",29)
create_singular_entity("mid_middle_lg_wall",30)
create_singular_entity("mid_right_lg_wall",31)
create_singular_entity("bot_left_lg_wall",32)
create_singular_entity("bot_middle_lg_wall",33)
create_singular_entity("bot_right_lg_wall",34)
create_singular_entity("up_vertical_wall",35)
create_singular_entity("middle_vertical_wall",36)
create_singular_entity("down_vertical_wall",37)
create_singular_entity("singular_wall",25)

create_singular_mid_entity("double_chain",7)