-- Code here will affect the whole game, including changes from other mods.
-- Loading and writing files is authorized but only within your mod's folder. Paths should be relative to the mod folder.
-- These will replace the vanilla game's surfaces. If multiple mods do this for the same surfaces, only the last one loaded will take effect. Here we're doing it to give the Black King a moustache.
    newsrf("title.png", "title")
    newsrf("gfx.png", "gfx")
    newsrf("tutorial.png", "tutorial")
    newsrf("planner/tiles.png", "customtiles")
    -- Make sure your mod's unique surfaces have unique names so they don't unintentionally replace each other.
    newsrf("cards.png", "samplemod_cards")
    newsrf("pieces.png", "samplemod_pieces")
    newsrf("dialogue.png", "dialogue")
    -- Puzzle music
    newmus("Background_Check.wav", "floor1")
    newmus("Moron.wav", "floor2")
    newmus("Needle_In_A_Haystack.wav", "floor3")
    newmus("Too Crazy.wav", "floor4")
    -- You may create a save bank for your mod with this function:
    -- newbnk(128, 64, 4)
    
    local test = require("test.lua")
    local global = gimme("global")
    -- You may also use this function with "replaceable" and "forbidden" to get lists of replaceable and forbidden variable names respectively. Use it with Autocall and you will get a list of function names you may use in your mod's game modes, if you do they will be called automatically by the game.
    local replaceable = gimme("replaceable")
    local forbidden = gimme("forbidden")
    local autocall = gimme("autocall")
    DEV = true 
    
    test.openSesame(global, "Global")
    
    test.openSesame(forbidden, "Forbidden")
    
    test.openSesame(replaceable, "Replaceable")
    
    test.openSesame(autocall, "Autocall")
    for i,v in ipairs(MODLIST) do if v.title == "Puzzle Party Demo" then
        mod_index,mod = i,v
        break
    end end
    
    require("planner/medals.lua")
    bestTries = {}
    
    require("planner/pieces.lua")
    local new_cards = require("planner/cards.lua")
    -- START_LVL=100
    require("planner/lang.lua")
    function add_lang()
        for key, v in pairs(english) do
            for k, v in pairs(english[key]) do
                k = key .."_" .. k
                lang[k] = v
            end
        end
        for k, v in pairs(english) do
            tbl_import(lang, v)
        end
    end
    add_lang()
    append("load_lang",add_lang,"added_lang")
    
    local entities= {}
    count_event = {room={}}
    
    require("planner/entity.lua")
    function add_unique(tbl, value)
        if not count_event[value] then
            count_event[value] = 1
            add(tbl, value)
        else
            count_event[value] = count_event[value] + 1
        end
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
    function better_sub(str, start, finish)
        local start = start or 1
        local finish = finish or #str
        if type(str)=="string" then
            return sub(str, start, finish)
        else
            return nil
        end
        
    end
    function process_conditions(tbl)
        local function not_(str)
            str = sbs(str,"%b()", "")
            return (better_sub(str, 1, 4) == "not_" and better_sub(str, 5) or nil)
        end
    
        local function quality(str)
            local num
            local compare
            if match(str, "%b()") then
                local valid_comparisons = {
                    lt = true,
                    le = true,
                    gt = true,
                    ge = true,
                }
                compare = better_sub(match(str, "%b()"),2,3)
                if valid_comparisons[compare] then
                    num =tonum(better_sub(match(str, "%b()"),4,-2))
                else
                    num =tonum(better_sub(match(str, "%b()"),2,-2))
                end
            end
            local ev
            if type(num)=="number" then
                ev = sbs(str, "%b()", "")
                local cond_event = true
                local function prep_count(ev)
                    return count_event[ev] and count_event[ev] or 0
                end
                if compare == "lt" then
                    if better_sub(ev,1,4) =="not_" then
                        cond_event = prep_count(better_sub(ev,5)) < num 
                    else 
                        cond_event = prep_count(ev) < num
                    end
                elseif compare == "le" then
                    if better_sub(ev,1,4) =="not_" then
                        cond_event = prep_count(better_sub(ev,5)) <= num 
                    else 
                        cond_event = prep_count(ev) <= num
                    end
                elseif compare == "gt" then
                    if better_sub(ev,1,4) =="not_" then
                        cond_event = prep_count(better_sub(ev,5)) > num 
                    else 
                        cond_event = prep_count(ev) > num
                    end
                elseif compare == "ge" then
                    if better_sub(ev,1,4) =="not_" then
                        cond_event = prep_count(better_sub(ev,5)) >= num 
                    else 
                        cond_event = prep_count(ev) >= num
                    end
                else
                    if better_sub(ev,1,4) =="not_" then
                        cond_event = prep_count(better_sub(ev,5)) == num 
                    else 
                        cond_event = prep_count(ev) == num
                    end
                end
                return num, cond_event, compare
            else
                return "nil", true, "nil"
            end
        end
    
        if tbl then
            if tbl.condition and type(tbl.condition) == "string" then
                tbl.condition = split(sbs(tbl.condition,"%s+", ""), ",")
            end
            if tbl.event and type(tbl.event) == "string" then
                tbl.event = split(sbs(tbl.event,"%s+", ""), ",")
            end
            if tbl.trigger and type(tbl.trigger) == "string" then
                tbl.trigger = split(sbs(tbl.trigger,"%s+", ""), ",")
            end
            if tbl.prelude and type(tbl.prelude) == "string" then
                tbl.prelude = split(sbs(tbl.prelude,"%s+", ""), ",")
            end
        end
        
        local un_cond= {{},{}}
        local cond = {{},{}}
        local trig = {{},{}}
        local nums= {{},{}}
        local cond_quality = {true, false}
        local compare ={{},{}}
        if tbl and tbl.condition then
            for i = 1, #tbl.condition do
                local condition = tbl.condition[i]
                local not_condition = not_(condition)
                
                if not_condition then
                    cond[2][#cond[2] + 1] = sbs(not_condition,"%b()", "")
                    un_cond[2][#un_cond[2] + 1] = condition
                else
                    cond[1][#cond[1] + 1] = sbs(condition,"%b()", "")
                    un_cond[1][#un_cond[1] + 1] = condition
                end
                
            end
            for i = 1, #un_cond[1], 1 do
                local _, quality_cond = quality(un_cond[1][i])
                if quality_cond ~= true then
                    cond_quality[1] = false
                    break
                end
            end
            for i = 1, #un_cond[2], 1 do
                local _, quality_cond = quality(un_cond[2][i])
                if quality_cond ~= true then
                    cond_quality[2] = true
                    break
                end
            end
        end
        if tbl and tbl.trigger then
            for i = 1, #tbl.trigger do
                if not_(tbl.trigger[i]) then
                    nums[2][#nums[2]+1], _, compare[2][#compare[2]+1] = quality(tbl.trigger[i])
                    trig[2][#trig[2]+1] = sbs(not_(tbl.trigger[i]),"%b()", "")
                else
                    nums[1][#nums[1]+1] , _, compare[1][#compare[1]+1]= quality(tbl.trigger[i])
                    trig[1][#trig[1]+1] = sbs(tbl.trigger[i],"%b()", "")
                end
            end
        end
        local condition = not tbl or not tbl.condition or 
        (is_subset(cond[1],history) and cond_quality[1] and (#cond[2]==0 or
        not is_subset(cond[2], history) or cond_quality[2]) )
        
        return tbl, condition, trig, nums, compare
    end
    
    function piece_transition(p, tempo)
        local fdi=0
        for di=0,3 do
            if dsq(p.sq,di)==nil then 
                fdi=di
            end
        end
        local dx=DIR[fdi*2+1]*16
        local dy=DIR[fdi*2+2]*16
        
        p.x=p.x+dx
        p.y=p.y+dy
        p.c_fade_in=tempo
        mv(p,-dx,-dy,tempo)
    end
    
    function move_hero_ang(tsq,f,skip_reload,tempo)
        local x = tsq.x - hero.sq.x
        local y = tsq.y - hero.sq.y
        hero.force_ang=atan2(x,y)
        move_hero(tsq,f,skip_reload,tempo)
    end
    
    function mk_entity(mk_e, px,py,ev)
        local condition
        local trig = {}
        local nums = {}
        local compare = {}
        if type(px)=="table" then
            _, condition= process_conditions(px)
            if condition
            then
                local mk = entity[mode_id][mk_e]()
                mode.load_entities(mk)
            end
        elseif px == nil and py == nil then
            local mk = entity[mode_id][mk_e]()
            mode.load_entities(mk)
        else    
            ev, condition, trig , nums, compare= process_conditions(ev)
            if condition
            then
                local mk = entity[mode_id][mk_e](px,py)
                if gsq(px,py) then
                    if mk_e =="barrel" then
                        if ev then
                            gsq(px,py).p={
                            event=ev.event or nil,
                            prelude = ev.prelude or nil,
                            trigger=trig[1] or nil,
                            repeatable=ev.repeatable or nil,
                            no_trig= trig[2] or nil,
                            nums = nums or nil,
                            compare = compare or nil,
                            x = -1309,
                            y = -1309,
                            z=0,
                            tempo = 0,
                            behavior = {},
                            bad=true,
                            type=-1,
                            name="barrel",
                            hp=0,
                            hp_max=0,
                            dr=function () end,
                            upd=function () end,
                            mark ={},
                            sq=gsq(px,py),
                            nocarry = 1, 
                            knockback =100,
                            freelift= 1,
                            iron = 1, 
                            }
                        else
                            gsq(px,py).p={
                            x = -1309,
                            y = -1309,
                            z=0,
                            tempo = 0,
                            behavior = {},
                            bad=true,
                            type=-1,
                            name="barrel",
                            hp=0,
                            hp_max=0,
                            dr=function () end,
                            upd=function () end,
                            mark ={},
                            sq= gsq(px,py),
                            nocarry = 1, 
                            knockback = 100,
                            freelift= 1, 
                            iron = 1
                            }
                        end
                        gsq(px,py).upd = function() 
                            if not gsq(px,py).p then
                                if ev then
                                    gsq(px,py).p={
                                    event=ev.event or nil,
                                    prelude = ev.prelude or nil,
                                    trigger=trig[1] or nil,
                                    repeatable=ev.repeatable or nil,
                                    no_trig= trig[2] or nil,
                                    nums = nums or nil,
                                    compare = compare or nil,
                                    x = -1309,
                                    y = -1309,
                                    z=0,
                                    tempo = 0,
                                    behavior = {},
                                    bad=true,
                                    type=-1,
                                    name="barrel",
                                    hp=0,
                                    hp_max=0,
                                    dr=function () end,
                                    upd=function () end,
                                    mark ={},
                                    sq=gsq(px,py),
                                    nocarry = 1, 
                                    knockback =100,
                                    freelift= 1,
                                    iron = 1, 
                                    }
                                else
                                    gsq(px,py).p={
                                    x = -1309,
                                    y = -1309,
                                    z=0,
                                    tempo = 0,
                                    behavior = {},
                                    bad=true,
                                    type=-1,
                                    name="barrel",
                                    hp=0,
                                    hp_max=0,
                                    dr=function () end,
                                    upd=function () end,
                                    mark ={},
                                    sq= gsq(px,py),
                                    nocarry = 1, 
                                    knockback = 100,
                                    freelift= 1, 
                                    iron = 1
                                    }
                                end
                            end
                            for ent in all(ents) do
                                if ent.x == gsq(px,py).x and ent.y == gsq(px,py).y and ent.out and ent.over then
                                    ent.over = nil
                                    if stack.special == 'strafe' then
                                        ent.right_clic = nil
                                    end
                                    ent.out()
                                end
                            end
                        end
                    else
                        if ev then
                            gsq(px,py).p={
                            event=ev.event or nil,
                            prelude = ev.prelude or nil,
                            trigger=trig[1] or nil,
                            repeatable=ev.repeatable or nil,
                            no_trig= trig[2] or nil,
                            nums = nums or nil,
                            compare = compare or nil,
                            x = -1309,
                            y = -1309,
                            z=0,
                            tempo = 0,
                            behavior = {},
                            bad=true,
                            type=-1,
                            name= "",
                            hp=0,
                            hp_max=0,
                            dr=function () end,
                            upd=function () end,
                            mark ={},
                            sq=gsq(px,py),
                            nocarry = 1, 
                            iron =1
                            }
                        else
                            gsq(px,py).p={
                            x = -1309,
                            y = -1309,
                            z=0,
                            tempo = 0,
                            behavior = {},
                            bad=true,
                            type=-1,
                            name="" ,
                            hp=0,
                            hp_max=0,
                            dr=function () end,
                            upd=function () end,
                            mark ={},
                            sq= gsq(px,py),
                            nocarry = 1, 
                            iron =1
                            }
                        end
                    
                        gsq(px,py).upd = function()
                            for ent in all(ents) do
                                if ent.x == gsq(px,py).x and ent.y == gsq(px,py).y and ent.out and ent.over then
                                    ent.over = nil
                                    if stack.special == 'strafe' then
                                        ent.right_clic = nil
                                    end
                                    if stack.grab then
                                        ent.on_drag = nil
                                    end
                                    ent.out()
                                end
                            end
                        end
                    end
                end
                mode.load_entities(mk)
            end
        end
    
        event_nxt()
    end
    
    piece_souls = {}
    function ev_souls(typ, isUnlimited)
        if type(isUnlimited) == "number" then
            piece_souls[typ] = piece_souls[typ] and piece_souls[typ] + isUnlimited or isUnlimited
            append("activate_soul", function(e)
                if e.oid and e.oid ==typ and piece_souls[typ] >0 then
                    add_soul(typ)
                    piece_souls[typ] = piece_souls[typ] -1
                end
            end, "souls"..typ)
            add_soul(typ)
            piece_souls[typ] = piece_souls[typ] -1
        elseif isUnlimited then
            append("activate_soul", function(e)
                if e.oid and e.oid ==typ then
                    add_soul(typ)
                end
               
            end, "souls"..typ)
            add_soul(typ)
        else
            add_soul(typ)
        end
        event_nxt()
    end
    function ev_offset_soul_slot()
        offSoul = mke()
        offSoul.upd = function()
            for v in all(ents) do
                if v.x == 135+board_x then
                    v.x = 270
                end
            end    
        end
    
        offSoul.dr = function()
            if 20 - board_x/8 >=10  and mode.turns then
                lprint("Turns: "..mode.turns, 5, 175,2) 
            end
        end
        event_nxt()
    end
    function ev_paralysis(num, is_stack_only)
        if not is_stack_only then
            mode.base.paralysis = num
        end
        stack.paralysis = num
        event_nxt()
    end
    
    function ev_shotgun()
        shotgun_pickup.anim_pickup = true
        shotgun_pickup.t = 0
        music("level_up_A")
        shotgun_pickup.upd=function(e)	
            if e.t%8==0 and e.t>170 then
                local ray=mke(0,12,-6)
                add_child(e,ray)
                ray.a=rnd(1)
                ray.va=0.005
                ray.life=60+irnd(60)
                ray.cl=4+irnd(2)
                ray.upd=function(e)
                    e.a=e.a+e.va
                end
                ray.dr=function(e,x,y)		
                
                    local c=1
                    if e.t<30 then c=e.t/30 end
                    if e.life<30 then c=e.life/30 end
                
                    local ex=x+cos(e.a)*MCW
                    local ey=y+sin(e.a)*MCW
    
                    local ra=.02*c		
                    local cl=ray.cl
                    if e.par.back then
                        cl=5
                        ra=ra*2
                        fillp_dissolve(.5)
                    end
                    
                    local ax=x+cos(e.a-ra)*MCW
                    local ay=y+sin(e.a-ra)*MCW
                    local bx=x+cos(e.a+ra)*MCW
                    local by=y+sin(e.a+ra)*MCW
                    trifill(ax,ay,bx,by,x,y,cl)
                    fillp_dissolve()
                end
            end
            for ray in all(e) do upe(ray)	end
            
            if btnp("validate") and shotgun_pickup.t > 170 then      
                mode.no_shotgun=false
                hide_shotgun= false
                sfx("level_up_sel")
                music("codex")
                kl(shotgun_pickup)
                shotgun_pickup=nil
                event_nxt()
            end
        end
    end
    function ev_mk_play_button()
        if not play_button then
            play_button = mk_text_but(245,160,32,"PLAY",function ()
                for p in all(bads) do
                    if p and p.old_upd then
                        if p.airy then
                            p.upd= function()
                                p.old_upd()
                                p.airy = true
                            end
                        else
                            p.upd = p.old_upd
                        end
                    end
                end
            end)
            play_button.ents[1].button = false
        end
        if not export_button then
            export_button= mk_text_but(280,160,32,"EXPORT",function ()
                -- Define the string to export
                local function spawn_ev_code(is_instant)
                    local spawn_info = ""
                    for p in all(bads) do
                        if p.type == patrol_typ and p.inert then
                        else
                            spawn_info = spawn_info .. 
                            "\t{ev=ev_spawn, params={" .. 
                            p.type .. "," ..tostr( p.bad ).. "," .. p.sq.px .. "," .. p.sq.py .. ", nil" ..
                            ", {" ..
                            (p.hp<p.hp_max and "hp=" .. p.hp .. ", " or "") ..
                            (p.hp_max ~= PIECES[p.type+1].hp and "hp_max=" .. p.hp_max .. ", " or "") ..
                            ("cd=" .. p.cd .. ", ") ..
                            (p.tempo ~= PIECES[p.type+1].tempo and "tempo=" .. p.tempo .. ", " or "") ..
                            (p.iron and "iron=" .. tostr(p.iron) .. ", " or "") ..
                            (p.inert and "inert=" .. tostr(p.inert) .. ", " or "") ..
                            (p.flying and "flying=" .. tostr(p.flying) .. ", " or "") ..
                            (p.shield and "shield=" .. tostr(p.shield) .. ", " or "") ..
                            (p.protect and "protect=" .. tostr(p.protect) .. ", " or "") ..
                            (p.airy and "airy=" .. tostr(p.airy) .. ", " or "") ..
                            (is_instant and "instant=" .. 1 .. ", " or "") ..
                            "}" ..
                            "}}," .. "\n"
                        end
                    end
                    return spawn_info
                end
                
                local function tile_code()
                    local tile_info =""
                    for sq in all(squares) do
                        if sq.tile_special then
                            tile_info= tile_info..
                            "{'" ..
                            sq.tile_special .. "'," ..
                            sq.px .. "," ..
                            sq.py .. "," ..
                            "}," .. "\n"
                        end
                    end
                    return tile_info
                end
                local content = '{ev_cond, params={"(1)SWAP_HERE"}},\n' ..
                spawn_ev_code()..
                "{ev_else}," .. "\n" ..
                spawn_ev_code(true)..
                "{ev_end}," .. "\n"
                
                -- Define the filename
                local filename = "scene_export.lua"
    
                -- Concatenate the full file path
                local filepath = filename
    
                -- Write the string to the file (overwrites if it exists)
                file(filepath, content)
                _log("File created or overwritten at: " .. filepath)
    
                filename = "tile_export.lua"
                filepath = filename
                file(filepath, tile_code())
                _log("File created or overwritten at: " .. filepath)
                
            end)
            export_button.ents[1].button = false
        end
        event_nxt()
    end
    function ev_mk_card_set_button()
        if not card_set_button then
            card_set_button = mk_text_but(8,3,32,"SET",function ()
                for sl in all(card_slots) do
                    if sl.ca and sl.ca.team ==0 then
                       tear_apart(sl.ca, nil) 
                    end
                end
                if has_card("Pawn") then
                    wait(TEMPO, add_card, "Normal")
                    wait(TEMPO, add_card, "Up")
                    wait(TEMPO, add_card, "Down")
                    wait(TEMPO, add_card, "Left")
                    wait(TEMPO, add_card, "Right")
                    wait(TEMPO, add_card, "Push Up")
                    wait(TEMPO, add_card, "Push Down")
                    wait(TEMPO, add_card, "Push Left")
                    wait(TEMPO, add_card, "Push Right")
                    wait(TEMPO, add_card, "Moat")
                elseif has_card("Up") then
                    wait(TEMPO, add_card, "Patrol")
                    wait(TEMPO, add_card, "Pawn")
                    wait(TEMPO, add_card, "Knight")
                    wait(TEMPO, add_card, "Bishop")
                    wait(TEMPO, add_card, "Rook")
                    wait(TEMPO, add_card, "Queen")
                    wait(TEMPO, add_card, "King")
                    wait(TEMPO, add_card, "Gryphon")
                    wait(TEMPO, add_card, "Nightrider")
                    wait(TEMPO, add_card, "Mini Knight")
                end
                wait(TEMPO*2, play)
            end)
            card_set_button.ents[1].button = false
            event_nxt()
        end
    end
    function ev_remove_play_button()
        kl(play_button)
        play_button = nil
    
        kl(export_button)
        export_button = nil
        event_nxt()
    end
    function mk_square_trigger(ev, ...)
        local condition
        local trig = {}
        local nums = {}
        local compare = {}
        ev, condition, trig, nums, compare = process_conditions(ev)
        if condition 
        then
            local args = {...}
            if type(args[1]) =="table" then
                args= args[1]
                local n= #args
                if n %4 ~=0 then
                    for i = n%4+1, 1, -1 do
                        deli(args,i)   
                    end
                end
                for i = 1, n, 4 do
                    local x= args[i]
                    local y= args[i+1]
                    add(mode.destination, {x,y, args[i+2], args[i+3]})
                    gsq(x,y).event=ev.event or nil
                    gsq(x,y).prelude = ev.prelude or nil
                    gsq(x,y).trigger= trig[1] or nil
                    gsq(x,y).repeatable= ev.repeatable or nil
                    gsq(x,y).no_trig = trig[2] or nil
                    gsq(x,y).nums = nums or nil
                    gsq(x,y).compare = compare or nil
                end
            
            else
                -- 1~2 squares that trigger a particular event
                if type(args[1]) == "number" then
                    local n= #args
                    if n %2 ~=0 then
                        deli(args, n)
                    end
                    for i = 1, n, 2 do
                        local x= args[i]
                        local y= args[i+1]
                        gsq(x,y).event=ev.event or nil
                        gsq(x,y).trigger= trig[1] or nil
                        gsq(x,y).repeatable= ev.repeatable or nil
                        gsq(x,y).no_trig = trig[2] or nil
                        gsq(x,y).nums = nums or nil
                        gsq(x,y).compare = compare or nil
                    end
                elseif sub(args[1],1,3) =="num" then
                    local n= #args[2]
                    if n %2 ~=0 then
                        deli(args[2], n)
                    end
                    for i = 1, n, 2 do
                        local x= args[2][i]
                        local y= args[2][i+1]
                        gsq(x,y).event=ev.event or nil
                        gsq(x,y).trigger= trig[1] or nil
                        gsq(x,y).repeatable= ev.repeatable or nil
                        gsq(x,y).no_trig = trig[2] or nil
                        gsq(x,y).nums = nums or nil
                        gsq(x,y).compare = compare or nil
                    end
                elseif sub(args[1],1,3) =="row" then
                    for i = -10, 10, 1 do
                        if gsq(i, args[2]) then
                            gsq(i, args[2]).event=ev.event or nil
                            gsq(i, args[2]).trigger= trig[1] or nil
                            gsq(i, args[2]).repeatable= ev.repeatable or nil
                            gsq(i, args[2]).no_trig = trig[2] or nil
                            gsq(i, args[2]).nums = nums or nil
                            gsq(i, args[2]).compare = compare or nil
                        end
                    end
                elseif sub(args[1],1,3) =="col" then
                    for i = -10, 10, 1 do
                        if gsq(args[2], i) then
                            gsq(args[2], i).event=ev.event or nil
                            gsq(args[2], i).trigger= trig[1] or nil
                            gsq(args[2], i).repeatable= ev.repeatable or nil
                            gsq(args[2], i).no_trig = trig[2] or nil
                            gsq(args[2], i).nums = nums or nil
                            gsq(args[2], i).compare = compare or nil
                        end
                    end
                elseif sub(args[1],1,4) == "rect" then
                    local x1, y1, x2, y2 = args[2], args[3], args[4], args[5]
                    local s1 = x1 > x2 and -1 or 1
                    local s2 = y1 > y2 and -1 or 1
                    for x = x1, x2, s1 do
                        for y = y1, y2, s2 do
                            if x == x1 or x == x2 or y == y1 or y == y2 then
                                if gsq(x, y) then
                                    gsq(x, y).event=ev.event or nil
                                    gsq(x, y).trigger= trig[1] or nil
                                    gsq(x, y).repeatable= ev.repeatable or nil
                                    gsq(x, y).no_trig = trig[2] or nil
                                    gsq(x, y).nums = nums or nil
                                    gsq(x, y).compare = compare or nil
                                end
                            end
                        end
                    end
                elseif sub(args[1],1,5) == "frect" then
                    local x1, y1, x2, y2 = args[2], args[3], args[4], args[5]
                    local s1 = x1>x2 and -1 or 1
                    local s2 = y1>y2 and -1 or 1
                    for x = x1, x2,s1 do
                        for y = y1, y2, s2 do
                            if gsq(x, y) then
                                gsq(x, y).event=ev.event or nil
                                gsq(x, y).trigger= trig[1] or nil
                                gsq(x, y).repeatable= ev.repeatable or nil
                                gsq(x, y).no_trig = trig[2] or nil
                                gsq(x, y).nums = nums or nil
                                gsq(x, y).compare = compare or nil
                            end
                        end
                    end
                elseif sub(args[1],1,5) == "ellip" then
                    local cx, cy, rx, ry = args[2], args[3], args[4], args[5]
                    for x = cx - rx, cx + rx do
                        for y = cy - ry, cy + ry do
                            local ellipse_eq = pow((x - cx), 2) / pow(rx, 2) + pow((y - cy), 2) / pow(ry, 2)
                            if ellipse_eq <= 1 and ellipse_eq >= 0.9 then -- Adjust the range to get the border
                                if gsq(x, y) then
                                    gsq(x, y).event=ev.event or nil
                                    gsq(x, y).trigger= trig[1] or nil
                                    gsq(x, y).repeatable= ev.repeatable or nil
                                    gsq(x, y).no_trig = trig[2] or nil
                                    gsq(x, y).nums = nums or nil
                                    gsq(x, y).compare = compare or nil
                                end
                            end
                        end
                    end
                elseif sub(args[1],1,6) == "fellip" then
                    local cx, cy, rx, ry = args[2], args[3], args[4], args[5]
                    for x = cx - rx, cx + rx do
                        for y = cy - ry, cy + ry do
                            if pow((x - cx),2 )/ pow(rx, 2) + pow((y - cy),2) / pow(ry,2)<= 1 then
                                if gsq(x, y) then
                                    gsq(x, y).event=ev.event or nil
                                    gsq(x, y).trigger= trig[1] or nil
                                    gsq(x, y).repeatable= ev.repeatable or nil
                                    gsq(x, y).no_trig = trig[2] or nil
                                    gsq(x, y).nums = nums or nil
                                    gsq(x, y).compare = compare or nil
                                end
                            end
                        end
                    end
                elseif sub(args[1],1,4) == "circ" then
                    local cx, cy, r = args[2], args[3], args[4]
                    for x = cx - r, cx + r do
                        for y = cy - r, cy + r do
                            local circle_eq = (x - cx) ^ 2 + (y - cy) ^ 2
                            if circle_eq <= r ^ 2 and circle_eq >= (r - 1) ^ 2 then -- Adjust the range to get the border
                                if gsq(x, y) then
                                    gsq(x, y).event=ev.event or nil
                                    gsq(x, y).trigger= trig[1] or nil
                                    gsq(x, y).repeatable= ev.repeatable or nil
                                    gsq(x, y).no_trig = trig[2] or nil
                                    gsq(x, y).nums = nums or nil
                                    gsq(x, y).compare = compare or nil
                                end
                            end
                        end
                    end
                elseif sub(args[1],1,5) == "fcirc" then
                    local cx, cy, r = args[2], args[3], args[4]
                    for x = cx - r, cx + r do
                        for y = cy - r, cy + r do
                            if (x - cx) ^ 2 + (y - cy) ^ 2 <= r ^ 2 then
                                if gsq(x, y) then
                                    gsq(x, y).event=ev.event or nil
                                    gsq(x, y).trigger= trig[1] or nil
                                    gsq(x, y).repeatable= ev.repeatable or nil
                                    gsq(x, y).no_trig = trig[2] or nil
                                    gsq(x, y).nums = nums or nil
                                    gsq(x, y).compare = compare or nil
                                end
                            end
                        end
                    end
                elseif sub(args[1],1,4)=="rand" then
                    for i = 1, args[2], 1 do
                       squares[irnd(#squares)+1].event=ev.event or nil
                       squares[irnd(#squares)+1].trigger= trig[1] or nil
                       squares[irnd(#squares)+1].repeatable= ev.repeatable or nil
                       squares[irnd(#squares)+1].no_trig = trig[2] or nil
                       squares[irnd(#squares)+1].nums = nums or nil
                       squares[irnd(#squares)+1].compare = compare or nil
                    end    
                end
            end
        end
        event_nxt()
    end
    function ev_reset_gameplay()
        remove_buts() -- needed or tuto crash when player click
        mode.in_cine=false
        hero.force_ang=nil
        reset_mode()
        reset_move_cursor()
        -- play()
        event_nxt()
    end
    
    function ev_wait(tmp)
        wait(tmp, event_nxt)
    end
    
    function ev_spawn(type,isBad, x,y,tbl, info)
        local instant = false
        if not info then
            info = isBad and "default" or {
                hp = 1,
                hp_max = 4,
                cd = 1,
            }
        else
            if info.instant then
                instant = true
            end
        end
    
        if x == nil or y == nil then
            for v in all(get_free_squares()) do
                x = v.px
                y = v.py
                break
            end
        end
        local condition
        local trig = {}
        local nums = {}
        local compare = {}
        tbl, condition, trig, nums, compare = process_conditions(tbl)
    
        if condition  
        then
            if gsq(x,y) and gsq(x,y).p then
                goto_sq(gsq(x,y).p, get_free_squares()[1])
            end
            local p=new_piece(type, isBad , gsq(x,y))
    
            p.event= tbl and tbl.event or nil
            p.prelude= tbl and tbl.prelude or nil  
            p.repeatable= tbl and tbl.repeatable or nil
            p.trigger= trig[1] or nil
            p.no_trig = trig[2] or nil
            p.nums = nums or nil
            p.compare= compare or nil
            if info ~="default" then
                if info.pike then
                    local beh = PIECES_TYPES[type].behavior
                    add(beh, { id="line",1,1,2,  atk=1, fatality="pike" })
                    info.behavior = beh
                end
                tbl_import(p, info)
            end
            
            if not isBad then
                add(allies, p)
            end
            piece_transition(p,TEMPO)
            p.turn = p.turn or 1
            p.buffer = p.buffer or 0
            if p and p.behavior and #p.behavior>0 and p.behavior[1].id=="clockwork" then
                p.upd= function()
                    local px = p.sq.px
                    local py = p.sq.py
                    local ind =  (p.turn -1 -p.buffer) % p.tempo+1
                    if p.behavior[ind] then
                        if p.behavior[ind].atk then
                            for i = 2, #p.behavior[ind], 2 do
                                if gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i])
                                and not gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i]).p
                                then 
                                    if not cl_danger["id "..(px + p.behavior[ind][i-1]).. (py + p.behavior[ind][i])] then
                                        add(cl_danger, {px + p.behavior[ind][i-1], py + p.behavior[ind][i],id="id "..(px + p.behavior[ind][i-1]).. (py + p.behavior[ind][i])})
                                        id_tbl(cl_danger)
                                    end
    
                                    if not gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i]).danger["id ".. p.type..p.sq.px .. p.sq.py] then
                                        p.id = "id ".. p.type..p.sq.px .. p.sq.py
                                        add(gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i]).danger, p) 
                                        id_tbl(gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i]).danger)
                                    end
                               
                                    px = px + p.behavior[ind][i-1]
                                    py = py + p.behavior[ind][i]
                                else
                                    break
                                end
                            end
                        elseif p.behavior[ind].move then
                            for i = 2, #p.behavior[ind], 2 do
                                if gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i])
                                and not gsq(px + p.behavior[ind][i-1], py + p.behavior[ind][i]).p
                                then 
                                    add(cl_movement, {px + p.behavior[ind][i-1], py + p.behavior[ind][i]})
                                    px = px + p.behavior[ind][i-1]
                                    py = py + p.behavior[ind][i]
                                else
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    
        if instant then
            wait(2, event_nxt)
        else
            wait(TEMPO, event_nxt)
        end
    end
    
    function ev_set_hero_angle(ang)
        hero.force_ang=ang
        event_nxt()
    end
    function ev_create_edit_panel()
        if edit_panel then
            kl(edit_panel)
            kl(edit_panel.iron_but)
            kl(edit_panel.inert_but)
            kl(edit_panel.flying_but)
            kl(edit_panel.shield_but)
            kl(edit_panel.airy_but)
            kl(edit_panel.protect_but)
    
            edit_panel.iron_but = nil
            edit_panel.inert_but = nil
            edit_panel.flying_but = nil
            edit_panel.shield_but = nil
            edit_panel.airy_but = nil
            edit_panel.protect_but = nil
            edit_panel = nil
        end
        edit_panel = mke()
        edit_panel.dp = DP_TOP
        edit_panel.x, edit_panel.y = 245+80, 5
        edit_panel.dr = dr_edit_panel
        edit_panel.upd = function() 
            if not mcl then return end
            if not selected then return end
            local function adjust_cd()
                if mx > edit_panel.x + strwidth("CD: ") and
                    mx < edit_panel.x + strwidth("CD: ") + strwidth(" - ") and
                    my > edit_panel.y + 12 and
                    my < edit_panel.y + 18 then
                    selected.cd = selected.cd - 1
                end
                if mx>edit_panel.x+strwidth("CD:")+strwidth(" - ") + strwidth(tostr(selected.cd))  and 
                    mx<edit_panel.x+strwidth("CD:")+strwidth(" - ") +strwidth(tostr(selected.cd))+strwidth(" + ") and 
                    my>edit_panel.y+12 and 
                    my<edit_panel.y +18 then
                    if selected.cd < selected.tempo then
                        selected.cd = selected.cd +1
                    else
                        sfx("wrong_shield")
                    end
                end
            end
    
            local function adjust_tempo()
                if mx > edit_panel.x + strwidth("TEMPO: ") and
                    mx < edit_panel.x + strwidth("TEMPO: ") + strwidth(" - ") and
                    my > edit_panel.y + 19 and
                    my < edit_panel.y + 25 then
                    if selected.tempo > 1 then
                        selected.tempo = selected.tempo - 1
                        if selected.cd > selected.tempo then
                            selected.cd = selected.tempo
                        end
                    else
                        sfx("wrong_shield")
                    end
                end
                if mx>edit_panel.x+strwidth("tempo:")+strwidth(" - ") + strwidth(tostr(selected.tempo)) and 
                    mx<edit_panel.x+strwidth("tempo:")+strwidth(" - ") +strwidth(tostr(selected.tempo))+strwidth(" + ") and
                    my>edit_panel.y+19 and
                    my<edit_panel.y +25 
                then
                    selected.tempo = selected.tempo +1
                end
            end
            local function adjust_hp()
                if mx > edit_panel.x + strwidth("HP: ") and
                    mx < edit_panel.x + strwidth("HP: ") + strwidth(" - ") and
                    my > edit_panel.y + 26 and
                    my < edit_panel.y + 32 then
                    if selected.hp > 1 then
                        selected.hp = selected.hp - 1
                    else
                        sfx("wrong_shield")
                    end
                end
                if mx>edit_panel.x+strwidth("HP:")+strwidth(" - ") + strwidth(tostr(selected.hp)) and 
                    mx<edit_panel.x+strwidth("HP:")+strwidth(" - ") +strwidth(tostr(selected.hp))+strwidth(" + ") and 
                    my>edit_panel.y+26 and 
                    my<edit_panel.y +32 then
                    if selected.hp < selected.hp_max then
                        selected.hp = selected.hp +1
                    else
                        sfx("wrong_shield")
                    end
                end
            end
            local function adjust_hp_max()
                if mx > edit_panel.x + strwidth("HP MAX: ") and
                    mx < edit_panel.x + strwidth("HP MAX: ") + strwidth(" - ") and
                    my > edit_panel.y + 33 and
                    my < edit_panel.y + 39 then
                    if selected.hp_max > 1 then
                        selected.hp_max = selected.hp_max - 1
                        if selected.hp_max < selected.hp then
                            selected.hp = selected.hp_max
                        end
                    else
                        sfx("wrong_shield")
                    end
                end
                if mx>edit_panel.x+strwidth("HP MAX:")+strwidth(" - ") + strwidth(tostr(selected.hp_max)) and 
                    mx<edit_panel.x+strwidth("HP MAX:")+strwidth(" - ") +strwidth(tostr(selected.hp_max))+strwidth(" + ") and 
                    my>edit_panel.y+33 and 
                    my<edit_panel.y +39 then
                    selected.hp_max = selected.hp_max +1
                end
            end
            adjust_cd()
            adjust_tempo()
            adjust_hp()
            adjust_hp_max()
        end
        edit_panel.iron_but = mk_text_but(edit_panel.x+3,edit_panel.y+40,32,"IRON",function ()
            if selected.type ==5 then return end
            selected.iron = not selected.iron
        end)
        edit_panel.iron_but.ents[1].button = false
        edit_panel.iron_but.dp = DP_TOP
    
        edit_panel.inert_but = mk_text_but(edit_panel.x+36,edit_panel.y+40,32,"INERT",function ()
            selected.inert = not selected.inert
        end)
        edit_panel.inert_but.ents[1].button = false
        edit_panel.inert_but.dp = DP_TOP
    
        edit_panel.flying_but = mk_text_but(edit_panel.x+3,edit_panel.y+55,32,"FLYING",function ()
            selected.flying = not selected.flying
        end)
        edit_panel.flying_but.ents[1].button = false
        edit_panel.flying_but.dp = DP_TOP
    
        edit_panel.shield_but = mk_text_but(edit_panel.x+36,edit_panel.y+55,32,"SHIELD",function ()
            selected.shield = not selected.shield
        end)
        edit_panel.shield_but.ents[1].button = false
        edit_panel.shield_but.dp = DP_TOP
    
        edit_panel.airy_but = mk_text_but(edit_panel.x+3,edit_panel.y+70,32,"airy",function ()
            local piece = selected
            local old_upd = piece.upd
            if piece.airy then
                piece.upd = function()
                    old_upd()
                    piece.airy = false
                end
            else
                piece.upd = function()
                    old_upd()
                    piece.airy = true
                end
            end
    
        end)
        edit_panel.airy_but.ents[1].button = false
        edit_panel.airy_but.dp = DP_TOP
    
        edit_panel.protect_but = mk_text_but(edit_panel.x+36,edit_panel.y+70,32,"protect",function ()
            selected.protect = not selected.protect
        end)
        edit_panel.protect_but.ents[1].button = false
        edit_panel.protect_but.dp = DP_TOP
    
        event_nxt()
    end
    
    
    function dr_edit_panel(e,x,y)
        rectfill(x,y,x+70,y+170,1)
        rect(x,y,x+70,y+170,3)
        hdclear(x,y,x+70,y+170)
        if selected then
            lprint(selected.name, lprint("Name: ", x+3, y+5, 4), y+5, 4)
            lprint(" + ", lprint(selected.cd, lprint(" - ", lprint("cd:", x+3, y+12, 4), y+12, 4), y+12, 4), y+12, 4)
            lprint(" + ", lprint(selected.tempo, lprint(" - ", lprint("tempo:", x+3, y+19, 4), y+19, 4), y+19, 4), y+19, 4)
            lprint(" + ", lprint(selected.hp, lprint(" - ", lprint("HP:", x+3, y+26, 4), y+26, 4), y+26, 4), y+26, 4)
            lprint(" + ", lprint(selected.hp_max, lprint(" - ", lprint("HP MAX:", x+3, y+33, 4), y+33, 4), y+33, 4), y+33, 4)
    
        end
    end
    
    function show_edit_panel()
        if not edit_panel or not edit_panel.iron_but then return end
        if edit_panel.x ==245+80 then
            mv(edit_panel,-80,0,25)
            mv(edit_panel.iron_but,-80,0,25)
            mv(edit_panel.inert_but,-80,0,25)
            mv(edit_panel.flying_but, -80,0,25)
            mv(edit_panel.shield_but, -80,0,25)
            mv(edit_panel.airy_but,-80,0,25)
            mv(edit_panel.protect_but, -80,0,25)
        end
    end
    
    function hide_edit_panel()
        if not edit_panel or not edit_panel.iron_but then return end
        if edit_panel.x ==245 then
            mv(edit_panel,80,0,25)
            mv(edit_panel.iron_but,80,0,25)
            mv(edit_panel.inert_but,80,0,25)
            mv(edit_panel.flying_but, 80,0,25)
            mv(edit_panel.shield_but, 80,0,25)
            mv(edit_panel.airy_but,80,0,25)
            mv(edit_panel.protect_but, 80,0,25)
        end
    end
    
    local intro_panel = ""
    function ev_create_name_panel() 
        if not panel then
            panel = mke()
            panel.dp = DP_TOP
            panel.x, panel.y = MCW/2-SQ, MCH+50
            panel.dr = dr_name_panel
        end
        
        event_nxt()
    end
    function dr_name_panel(e,x,y)
        local txt= get_lang(mode_id .."_" .. intro_panel)
        rectfill(x,y-9, x+ strwidth(txt)+2, y,2)
        lprint(txt, x+2, y-7, 4)
    end
    function ev_show_name_panel(name)
        intro_panel = name
        panel.twcv= ease_bounce_out
        mvt(panel,MCW/2-SQ,MCH-5,50,bind(wait,60,function()
            panel.twcv = ease_out
            mvt(panel,MCW/2-SQ,MCH+50,50)
        end))
        event_nxt()
    end
    -- OBJECTIVES PANEL
    obj_tabs = {"current","completed"}
    local tab_index = 1
    local items_per_page = 10
    local current_page = 1
    function create_objectives() 
        objectives=mke()
        objectives.dp=DP_TOP+1
        objectives.dr=dr_objectives
        objectives.x,objectives.y=32,18-500
    
        goal = mke()
        goal.dp=DP_TOP
        goal.dr=dr_goal
        goal.dr = dr_goal
        goal.x,goal.y=5,5
        goal.index = 1
    
        for k, v in ipairs(obj_tabs) do
            local tab = mke()
            tab.dp=DP_TOP+1
            tab.dr=dr_tab
            tab.index = k
            tab.name = v
            tab.w = strwidth(v)+2
            tab.x,tab.y=32+2+ 33*(k-1)+2,18-500 + 6+6+1
            tab.upd= function()
                if btnp("validate") then
                    if my>tab.y and my<tab.y+10 and mx>tab.x and mx<tab.x+tab.w then
                        tab_index = tab.index
                        current_page = 1 -- Reset to the first page when changing tabs
                    end
                end
            end
        end
    
        -- Add navigation buttons
        local prev_button = mke()
        prev_button.dp = DP_TOP + 1
        prev_button.x, prev_button.y = 32+10, 18-500 + 130
        prev_button.w = strwidth("< Prev")
        prev_button.dr = function(e, x, y)
            prev_button.x, prev_button.y = objectives.x+10, objectives.y+130
            if current_page > 1 then
                pprint("< Prev", e.x, e.y, 100, 3)
            end
        end
        prev_button.upd = function()
            if btnp("validate") and current_page > 1 and my>prev_button.y and my<prev_button.y+10 and mx>prev_button.x and mx<prev_button.x+prev_button.w  then
                current_page = current_page - 1
            end
        end
    
        local next_button = mke()
        next_button.dp = DP_TOP + 1
        next_button.x, next_button.y = 32+200, 18-500 + 130
        next_button.w = strwidth("Next >")
        next_button.dr = function(e, x, y)
            next_button.x, next_button.y = objectives.x+200, objectives.y+130
            local quests = tab_index == 1 and quest.current or quest.completed
            local total_pages = ceil(#quests / items_per_page)
            if current_page < total_pages then
                pprint("Next >", e.x, e.y, 100, 3)
            end
        end
        next_button.upd = function()
            local quests = tab_index == 1 and quest.current or quest.completed
            local total_pages = ceil(#quests / items_per_page)
            if btnp("validate") and current_page < total_pages and my>next_button.y and my<next_button.y+10 and mx>next_button.x and mx<next_button.x+next_button.w then
                current_page = current_page + 1
            end
        end
    
        event_nxt()
    end
    function dr_goal(e,x,y)
        e.obj=quest.current[e.index] and quest.current[e.index].name
        if not e.obj then return end
        lprint(get_lang(mode_id.."_".."quest"), x, y, 4)
        pprint(get_lang(mode_id.."_"..e.obj), x, y+6, 85, 3)
    end
    function dr_tab(e,x,y)
        e.x,e.y=objectives.x+2+ 33*(e.index-1)+2,objectives.y + 6+1
        if e.index == tab_index then
            rect(e.x, e.y-1, e.x+e.w, e.y+10 ,5)
        else
            rect(e.x, e.y-1, e.x+e.w, e.y+10 ,3)
        end
        
        bprint(e.name, e.x+2,e.y+2, e.w, 4)
    end
    
    function dr_objectives(e,x,y)
        rectfill(x,y,x+258,y+144,1)
        rect(x,y,x+258,y+144,3)
        hdclear(x,y,x+258,y+144)
        lprint(get_lang(mode_id.."_".."quest"), x+115, y+1, 4)
    
        local quests = tab_index == 1 and quest.current or quest.completed
        local total_pages = ceil(#quests / items_per_page)
    
        local start_index = (current_page - 1) * items_per_page + 1
        local end_index = min(start_index + items_per_page - 1, #quests)
        
        for i = start_index, end_index do
            local txt = get_lang(mode_id .. "_" .. quests[i].name)
            -- Split the text into words
            local words = {}
            words=split(txt," ")
    
            -- Reconstruct the text into chunks of up to 60 characters
            local current_chunk = ""
            local is_overflow = false
            for i, word in ipairs(words) do
                if #current_chunk + #word + 1 <= 60 then
                    current_chunk = current_chunk .. (current_chunk == "" and "" or " ") .. word
                else
                    is_overflow = true
                    break
                end
            end
    
            txt = current_chunk .. (is_overflow and "..." or "")
    
            pprint(txt, x + 2 + 6, y + 10 * (i - start_index + 1) + 6 + 10, 250, 3)
        end
    
    end
    function ev_quest(obj)
        local condition
        local tbl = {}
        tbl, condition = process_conditions(quest[mode_id][obj])
        if not quest.current[obj] then
            add(quest.current, quest[mode_id][obj])
        else
            if condition and not quest.completed[obj] then
                add(quest.completed,quest[mode_id][obj])
                del(quest.current, quest[mode_id][obj]) 
                if tbl.event then
                    mode.trigger_events(mode_id, tbl.event[1])
                end
            end
        end
        mark_event(obj)
        map_tbl(quest.current,"name")
        map_tbl(quest.completed,"name")
        event_nxt()
    end
    function hide_objectives()
        if not objectives then return end
        if objectives.y ==18 then
            mv(objectives,0,-500,50)
        end
    end
    function ev_hide_objectives()
        if not objectives then return end
        if objectives.y ==18 then
            mv(objectives,0,-500,50)
        end
        
        event_nxt()
    end
    
    function show_objectives()
        goal.index = goal.index== #quest.current and 1 or goal.index+1  
        if objectives.y ==18-500 then
            mv(objectives,0,500,50)
        end
    end
    
    function ev_show_objectives()
        if objectives.y ==18-500 then
            mv(objectives,0,500,50)
        end
        
        event_nxt()
    end
    -- Define animation sequences
    ANIMATIONS = {
        IDLE = {
            frames = {0, 1, 2, 2, 1, 0},
            delay = 6,
            custom = function(t, frames)
                return frames[mid(1, t % 50, #frames)]
            end
        },
        DIA_FIVE = {
            frames = {0, 3, 4, 0, 3, 0, 4},
            delay = 6
        },
        DIA_SIX = {
            frames = {0, 3, 4, 0, 3, 5, 3, 4},
            delay = 6
        }
    }
    -- DIALOGUE BOX
        function animatedFrame(animation, t)
            local frames = animation.frames
            local delay = animation.delay
            
            if animation.custom then
                return animation.custom(round(t / delay), frames)
            else
                local frameIndex = round(t / delay) % #frames + 1
                return frames[frameIndex]
            end
        end
    
        function dr_dialogue(e,x,y)
            local w,h=e.width,e.height
            -- outer dialogue frame
            rectfill(x,y,x+w-1,y+h-1,1)
            rect(x,y,x+w-1,y+h-1,3)
            line(x-1,y+1,x-1,y+h,2)
            line(x-1,y+h,x+w,y+h,2)
            hdclear(x,y,x+w-1,y+h-1)
            
            if e.is_right then
                spritesheet("dialogue")
                -- inner dialogue frame
                sspr(0,2,45,42,x+w-45-2,y+3)
    
                local f=0
                if e.typing then
                    if e.frames==5 then
                        f = animatedFrame(ANIMATIONS.DIA_FIVE, e.t)
                    else
                        f= animatedFrame(ANIMATIONS.DIA_SIX, e.t)
                    end
                else
                    f= animatedFrame(ANIMATIONS.IDLE, e.t)
                end
                
                -- animated avatar
                sspr(48+f*24,1+43*(e.character-1),24,39,x+w-45-2+14,y+4)
    
                pprint(e.name, x+3, y+3, 192, 4)
                pprint(e.txt, x+3, y+3+6, w-49, 3, 0, e.ttypewriter)
                draw_button("validate", 244-45, 160-(124-e.y))
            else
                if e.character~=0 then	
                    spritesheet("dialogue")
                    sspr(0,2,45,42,x+2,y+3)
                    local f=0
                    if e.typing then
                        if e.frames==5 then
                            f = animatedFrame(ANIMATIONS.DIA_FIVE, e.t)
                        else
                            f= animatedFrame(ANIMATIONS.DIA_SIX, e.t)
                        end
                    else
                        f= animatedFrame(ANIMATIONS.IDLE, e.t)
                    end
                    sspr(48+f*24,1+43*(e.character-1),24,39,x+14,y+4)
                    pprint(e.name, x+2+45+2, y+3, 192, 4)
                    pprint(e.txt, x+2+45+2, y+3+6, w-49, 3, 0, e.ttypewriter)
                else
                    pprint(e.txt, x+2, y+3+6, w, 3, 0, e.ttypewriter)
                end
                draw_button("validate", 244, 160-(124-e.y))
            end
    
        end
    
        function launch_dialogue(is_down, is_right, character, key,index,event,frames, on_close)
            mode.in_cine=true
            local condition
            local tbl = {}
            tbl, condition = process_conditions(event)
            if condition then
                local index = index or 1
                local dia=mke()
                dia.name= match(get_lang(mode_id.."_"..key), "<(.-)>") or ""
                dia.opts = match(get_lang(mode_id.."_"..key), "{(.+)}") or ""
                dia.txt = sbs(get_lang(mode_id.."_"..key), "<.->", "") or ""
                dia.txt = sbs(dia.txt, "{.+}", "") or ""
    
                -- Split the text into words
                local words = {}
                words=split(dia.txt," ")
    
                 -- Reconstruct the text into chunks of up to 185 characters
                local chunks = {}
                local current_chunk = ""
                for i, word in ipairs(words) do
                    if #current_chunk + #word + 1 <= 185 then
                        current_chunk = current_chunk .. (current_chunk == "" and "" or " ") .. word
                    else
                        add(chunks, current_chunk)
                        current_chunk = word
                    end
                end
                if current_chunk ~= "" then
                    add(chunks, current_chunk)
                end
    
                local max_index = #chunks
                dia.txt = (index ~= 1 and "..." or "") .. chunks[index] .. (index == max_index and "" or "...")
                local len_dia = safesize(dia.txt)
    
                dia.dr=dr_dialogue
                dia.dp=DP_TOP
                dia.is_right=is_right
                dia.character=character or ""
                dia.frames=frames
                dia.width, dia.height = 192, 47
                
                if is_down then dia.x,dia.y=64,124 else dia.x,dia.y=64,0 end
            
                dia.ttypewriter=0
                dia.typing=true
                local fast=false
                dia.upd=function()
                    dia.ttypewriter=dia.ttypewriter+(fast and 5 or .5)
                    if dia.ttypewriter>len_dia then fast=true dia.typing=false end		
    
                    if dia.typing then
                        if dia.t%(fast and 3 or 6)==0 then
                            _sfx("tic",3,.2,0,.5+hrnd(.02))
                        end
                        if btnp("validate") and dia.t > 10 then
                            fast=true
                        end
                    else
                        if btnp("validate") and index == max_index and dia.opts=="" then
                            kl(dia)
                            if on_close then on_close() end
                        elseif btnp("validate") and index < max_index then
                            kl(dia)
                            index = index + 1
                            launch_dialogue(is_down, is_right, character, key, index, tbl, frames, on_close)
                        end
                    end
                end
                dia.choices= {}
                if dia.opts ~= "" and index == max_index then
                    local options= split(dia.opts, ",")
                    local max_w_option=0
                    for v in all(options) do
                        if strwidth(v)>max_w_option then
                            max_w_option=strwidth(v)
                        end
                    end
                    if flr((dia.x +dia.width)/3)<max_w_option then
                        max_w_option= flr((dia.x +dia.width)/3)
                    end
                    local height = 0
                    for k, v in ipairs(options) do
                        local choice = mke()
                        choice.dp = DP_TOP
                        choice.index= k
                        choice.txt = v
                        choice.dr= dr_choice
                        choice.w= max_w_option+3
                        choice.h= ceil(strwidth(v)/max_w_option)
                        choice.is_down = not is_down
                        choice.x= dia.x+dia.width-choice.w
                        choice.y= not is_down and dia.y+dia.height+8*height or dia.y-8*height 
                        height = height + choice.h
    
                        choice.upd= function()
                            if btnp("validate") then
                                local condition
                                if choice.is_down then
                                    condition = my > choice.y+2 and my < choice.y + choice.h*8+2 
                                else 
                                    condition = my > choice.y-6 and my < choice.y + choice.h*8-6
                                end
                                if mx > choice.x and mx < choice.x + choice.w and condition then
                                    kl(dia)
                                    for choice in all(dia.choices) do
                                        kl(choice)
                                    end
                                    for i = #options, 1,-1 do
                                        if i~=choice.index then
                                            deli(events,i)
                                        end     
                                    end
                                    if on_close then on_close() end
                                end
                            end
                        end
                        add(dia.choices, choice)
                    end
                end
                remove_buts() -- needed or tuto crash when player click
                mode.in_cine=false
                hero.force_ang=nil
                reset_mode()
                reset_move_cursor()
            else
                if on_close then on_close() end
            end
        end
    
    function dr_choice(e) 
        if e.is_down then
            rectfill(e.x-1, e.y+1, e.x+e.w-1, e.y+e.h*8+1,1)
            rect(e.x, e.y, e.x+e.w, e.y+e.h*8 ,3)
            bprint(e.txt, e.x+2,e.y+2, e.w, 5)
        else
            rectfill(e.x-1, e.y-9, e.x+e.w-1, e.y+e.h*8-9,1)
            rect(e.x, e.y-8, e.x+e.w, e.y+e.h*8-8,3)
            bprint(e.txt, e.x+2,e.y-6, e.w, 5)
        end
    end
    function mark_event(name, ev, params)
        add_unique(history, name)
        add(history.room, name)
        if ev then
            if type(params) == "table" then
                ev(unpack(params))
            else
                ev(params)
            end
        end
    end
    function ev_mark_event(name, ev, params)
        mark_event(name, ev, params)
        event_nxt()
    end
    function ev_down_dialogue(key,cond)
        launch_dialogue(true, false, 0, key, 1, cond, nil, event_nxt)
    end
    function ev_down_dialogue_left( character, key,cond, frames)
        launch_dialogue(true, false, character, key,1,cond, frames, event_nxt)
    end
    function ev_down_dialogue_right( character, key,cond, frames)
        launch_dialogue(true, true, character, key,1,cond ,frames,event_nxt)
    end
    function ev_up_dialogue_left( character, key,cond, frames)
        launch_dialogue(false, false, character, key,1,cond, frames, event_nxt)
    end
    function ev_up_dialogue_right( character, key,cond, frames)
        launch_dialogue(false, true, character, key,1,cond, frames, event_nxt)
    end
    
    function ev_move_hero_ang(px, py, f, skip_reload, tempo)
        skip_reload = skip_reload or true
        tempo =tempo or 30
        move_hero_ang(gsq(px, py), f, skip_reload, tempo)
        event_nxt()
    end
    function ev_goto_sq(is_bad, index, px, py, tempo, f)
        tempo = tempo or 30
        if is_bad then
            goto_sq(bads[index], gsq(px, py), tempo, f)
        else
            goto_sq(allies[index], gsq(px, py), tempo, f)
        end
        wait(tempo, sfx, "jump")
        event_nxt()
    end
    
    function ev_repeat_after_me(str)
        log(str)
        event_nxt()
    end
    pressR = false
    
    function ev_transport(id, f)
        remove_buts()
    
        if mode_id =="puzzle" then
            if (not bestTries[mode.lvl] or bestTries[mode.lvl] > mode.turns) 
            and is_subset({mode.lvl .. "_solved"}, history.room) 
            and not pressR
            then
                bestTries[mode.lvl] = mode.turns
            end
        end
        for k = #history.room, 1, -1 do
            if not (sub(history.room[k], -7, -1) == "_solved") and not (sub(mode.room_history()[k],-7,-1) =="_unlock") then
                if history.room[k]=="kingkill" or history.room[k]=="pawnkill" 
                or history.room[k]=="queenkill" or history.room[k]=="knightkill" 
                or history.room[k]=="rookkill" or history.room[k]=="bishopkill" then
                    if count_event.room[history.room[k]] then
                        count_event.room[history.room[k]] = count_event.room[history.room[k]] - 1
                    end 
                end
                deli(history.room, k)
            end
        end
        for k, v in pairs(entities) do
            kl(v)   
            v= nil
        end
        for sq in all(squares) do
            sq.upd= function()
            end
        end
        entities={}
        cl_danger={}
        piece_souls={}
        if chess_panel and ctrl_panel then
            mv(chess_panel,-100,0,30)
            mv(ctrl_panel,100,0,30)
            mv(medal_panel, 100, 0, 50)
        end
       
        name_panel=nil
        mode.px= hero.sq.px
        mode.py= hero.sq.py
        mode.lvl= id or mode.lvl+1
    
        wait(90,fade_to,-4,20)
        local function next_room()
            new_level()
            if mode_id =="puzzle" then
                remove_soul_slot()
                add_soul_slot()
            end
            if general_events[mode_id][mode.lvl] then
                mode.trigger_events(mode_id,mode.lvl)
            end
        end
        local global_history={}
        local room_history= {}
        for k, v in pairs(history) do
            if k ~= "room" and v ~= "dev" then
                add(global_history, v)
            elseif k == "room" then
                tbl_import(room_history, v)
            end
        end
        local global_count_ev = {}
        local room_count_ev = {}
        for k, v in pairs(count_event) do
            if k ~= "room" then
                global_count_ev[k] = v
            else
                tbl_import(room_count_ev, v)
            end
        end
    
        local current_quest = {}
        local completed_quest = {}
        for k, v in pairs(quest) do
            if k =="current" then
                tbl_import(current_quest, v)
            elseif k == "completed" then
                tbl_import(completed_quest, v)
            end
        end
        if SAVE[mode_id] then
            SAVE[mode_id].bestTries = bestTries
            SAVE[mode_id].global_history = global_history
            SAVE[mode_id].room_history = room_history
            SAVE[mode_id].global_count_ev = global_count_ev
            SAVE[mode_id].room_count_ev = room_count_ev
            SAVE[mode_id].current_quest = current_quest
            SAVE[mode_id].completed_quest = completed_quest
        end
        end_level(f or next_room)
        if allies then 
            for ally in all(allies) do
                fx_ascend(ally)
            end
        end
        mode.clear_allies()
        pressR = false
        kl(offSoul)
    
        for k, v in pairs(PIECES_TYPES) do
            append("activate_soul", function (e)
                
            end, "souls"..k)
        end
    
        event_nxt()
    end
    
    function ev_cond(cond, num1, num2)
        local condition
        num2 = num2 or 0
        if type(cond) =="string" then
            cond= split(sbs(cond,"%s+", ""), ",")
            cond= {condition = cond}
        end
        _, condition = process_conditions(cond)
        if not condition then
            for i = num1, 1, -1 do
                deli(events,i)
            end
        else
            for i = num1+num2, num1+1, -1 do
                deli(events,i)
            end
        end
        event_nxt()
    end
    function empty()
        event_nxt()
    end
    function ev_else()
        event_nxt()
    end
    function ev_end()
        event_nxt()
    end
    function mk_cutscene(table)
        init_vig(table, function ()
            event_nxt()
        end)
    end
    function ev_firepower(num, is_stack_only)
        if not is_stack_only then
           mode.base.firepower = mode.base.firepower + num 
        end
        
        stack.firepower = stack.firepower + num
        event_nxt()
    end
    function ev_set_firepower(num , is_stack_only)
        if not is_stack_only then
            mode.base.firepower = num
        end
        stack.firepower = num
        event_nxt()
    end
    function ev_chamber_max(num , is_stack_only)
        if not is_stack_only then
            mode.base.chamber_max = mode.base.chamber_max + num
        end
        
        stack.chamber_max = stack.chamber_max + num
        event_nxt()
    end
    function ev_set_chamber_max(num , is_stack_only)
        if not is_stack_only then
            mode.base.chamber_max = num
        end
        stack.chamber_max = num
        event_nxt()
    end
    function ev_firerange(num, is_stack_only)
        if not is_stack_only then
            mode.base.firerange = mode.base.firerange + num
        end
        stack.firerange = stack.firerange + num
        event_nxt()
    end
    
    function ev_set_firerange(num, is_stack_only)
        if not is_stack_only then
            mode.base.firerange = num
        end
        stack.firerange = num
        event_nxt()
    end
    function ev_spread(num, is_stack_only)
        if not is_stack_only then
            mode.base.spread = mode.base.spread + num
        end
        stack.spread = stack.spread + num
        event_nxt()
    end
    function ev_set_spread(num, is_stack_only)
        if not is_stack_only then
            mode.base.spread = num
        end
        stack.spread = num
        event_nxt()
    end
    function ev_ammo_max(num, is_stack_only)
        if not is_stack_only then
            mode.base.ammo_max = mode.base.ammo_max + num
        end
        stack.ammo_max = stack.ammo_max + num
        event_nxt()
    end
    function ev_set_ammo_max(num, is_stack_only)
        if not is_stack_only then
            mode.base.ammo_max = num
        end
        stack.ammo_max = num
        event_nxt()
    end
    function ev_soul_slot(num, is_stack_only)
        -- if mode.base.soul_slot +num >0 then
            if not is_stack_only then
                mode.base.soul_slot = num
            end
            stack.soul_slot = num
            if num > 0 then
                for i = 1, num, 1 do
                    add_soul_slot()
                end
            elseif num <0 then
                for i = 1, -num, 1 do
                    remove_soul_slot()
                end
            end
        -- end
    
        event_nxt()
    end
    function ev_knockback(num, is_stack_only)
        if not is_stack_only then
            mode.base.knockback = mode.base.knockback + num
        end
        stack.knockback = stack.knockback + num
        event_nxt()
    end
    
    function ev_set_knockback(num, is_stack_only)
        if not is_stack_only then
            mode.base.knockback = num
        end
        stack.knockback = num
        event_nxt()
    end
    
    function ev_pierce(num, is_stack_only)
        if not is_stack_only then
            mode.base.pierce = mode.base.pierce + num
        end
        stack.pierce = stack.pierce + num
        event_nxt()
    end
    
    function ev_set_pierce(num, is_stack_only)
        if not is_stack_only then
            mode.base.pierce = num
        end
        stack.pierce = num
        event_nxt()
    end
    function ev_blood_bowl(num, is_stack_only)
        if not is_stack_only then
            mode.base.blood_bowl = mode.base.blood_bowl + num
        end
        stack.blood_bowl = stack.blood_bowl + num
        event_nxt()
    end
    function ev_set_blood_bowl(num, is_stack_only)
        if not is_stack_only then
            mode.base.blood_bowl = num
        end
        stack.blood_bowl = num
        event_nxt()
    end
    function ev_tempo(name, num)
        local name_tempo = name.."_tempo"
        num = num or 1
        mode.base[name_tempo] = mode.base[name_tempo] and mode.base[name_tempo] + num or num
        event_nxt()
    end
    
    function ev_set_tempo(name, num)
        local name_tempo = name.."_tempo"
        mode.base[name_tempo] = num
        event_nxt()
    end
    function ev_turn(num)
        mode.turns = mode.turns + num
        event_nxt()
    end
    function ev_hp(name, num)
        local name_hp = name.."_hp"
        num = num or 1
        mode.base[name_hp] = mode.base[name_hp] + num
        event_nxt()
    end
    function ev_set_hp(name, num)
        local name_hp = name.."_hp"
        mode.base[name_hp] = num
        event_nxt()
    end
    function ev_pike(name, value)
        local name_pike = name.."_pike"
        mode.base[name_pike] = value
        event_nxt()
    end
    function ev_gain(tbl)
        if type(tbl) == "string" then
            tbl = split(sbs(tbl,"%s+", ""), ",")
        elseif type(tbl) =="number" then
            tbl = {tbl}
        end
    
        -- Convert each string in tbl to a number
        for i, v in ipairs(tbl) do
            tbl[i] = tonum(v)
        end
        tbl_import(mode.base.gain, tbl)
        event_nxt()
    end
    function ev_loss(tbl)
        if type(tbl) == "string" then
            tbl = split(sbs(tbl,"%s+", ""), ",")
        elseif type(tbl) =="number" then
            tbl = {tbl}
        end
     
        for v in all(tbl) do
            del(mode.base.gain, tonum(v))
            del(mode.tbase, tonum(v))
        end
    
        event_nxt()
    end
    
    function ev_special(name, is_stack_only)
       if not is_stack_only then
           mode.base.special = name
       end
       stack.special = name
       event_nxt() 
    end
    function ev_ammo_regen(num, is_stack_only)
        if not is_stack_only then
            mode.base.ammo_regen = num
        end
        stack.ammo_regen = num
        event_nxt()
    end
    
    function ev_set_ammo_regen(num, is_stack_only)
        if not is_stack_only then
            mode.base.ammo_regen = num
        end
        stack.ammo_regen = num
        event_nxt()
    end
    function ev_grab(is_stack_only)
        if not is_stack_only then
            mode.base.grab = 1
        end
        stack.grab =1
        event_nxt()
    end
    function ev_cards(cards)
        for card in all(cards) do
            add_card(card)
        end
        event_nxt()
    end
    function ev_reset_cards()
        for sl in all(card_slots) do
            if sl.ca then
               tear_apart(sl.ca, nil) 
            end
        end
        event_nxt()
    end
    function ev_steed(nums, is_stack_only)
        if not is_stack_only then
            mode.base.steed = nums
        end
        stack.steed =nums
        event_nxt()
    end
    function ev_militia(name, value)
        local name_militia = name.."_militia"
        mode.base[name_militia] = value
        event_nxt()
    end
    
    function ev_cage(name, num)
        local name_cage = name.."_cage"
        num = num or 1
        mode.base[name_cage]= num
        event_nxt()
    end
    function ev_healer(name, num)
        local name_healer = name.."_healer"
        mode.base[name_healer]= num
        event_nxt()
    end
    
    function ev_protect(name)
        local name_protect = name.."_protect"
        mode.base[name_protect]= 1
        event_nxt()
    end
    
    function ev_wraith(name, value)
        value = value or 1
        local name_wraith = name.."_wraith"
        mode.base[name_wraith]= value
        event_nxt()
    end
    function ev_orth(name)
        local name_orth = name.."_orth"
        mode.base[name_orth]= 1
        event_nxt()
    end
    
    function ev_rep(name, num)
        local name_rep = name.."_rep"
        mode.base[name_rep]= num
        event_nxt()
    end
    
    function ev_enable_shotgun()
        mode.no_shotgun=false
        event_nxt()
    end
    function ev_disable_shotgun()
        mode.no_shotgun=true
        event_nxt()
    end
    function ev_hide_card()
       mode.hide_card=true
       event_nxt() 
    end
    function ev_show_card()
        mode.hide_card=false   
        event_nxt()
    end
    
    function ev_base_promote(name, value)
        local name_promote = name.."_promote"
        mode.base[name_promote]= value      
        event_nxt()
    end
    
    function ev_crown(is_stack_only)
        if not is_stack_only then
            mode.base.crown = 1
        end
        stack.crown = 1
        event_nxt()
    end
    
    function ev_hop(dmg, is_stack_only)
        dmg = dmg or 0
        if not is_stack_only then
            mode.base.hop = 1
            if dmg then
                mode.base.hop_dmg = dmg
            end
        end
        stack.hop = 1
        if dmg then
            stack.hop_dmg= dmg
        end
        event_nxt()
        
    end
    allies = {}
    history = {room={}}
    
    
    -- TILES
    require("planner/tiles.lua")
    require("planner/tileType.lua")
    for _, v in pairs(tileType) do
        if not v.dr then
            v.dr= function() end
        end
        if not v.upd then
            v.upd= function() end
        end
        if not v.onEnter then
            v.onEnter= function() end
        end
        if not v.onLeave then
            v.onLeave = function() end
        end
    end
    
    Octiles= {}
    append("new_level", function() 
        if tiles[mode_id] and tiles[mode_id][mode.lvl] then
            for v in all(tiles[mode_id][mode.lvl]) do
                local ow_squares = {}
                if type(v[2]) =="number" then
                    if #v%2 == 0 then
                        deli(v, #v)
                    end
                    for i = 2, #v, 2 do
                        if gsq(v[i],v[i+1]) then
                            gsq(v[i],v[i+1]).tile_special = v[1]
                            add(ow_squares, gsq(v[i],v[i+1]))
                        end
                    end
                else
                    if sub(v[2],1,3) =="num" then
                        if #v%2 == 1 then
                            deli(v, #v)
                        end
                        for i = 3, #v, 2 do
                            if gsq(v[i],v[i+1]) then
                                gsq(v[i],v[i+1]).tile_special = v[1]
                                add(ow_squares, gsq(v[i],v[i+1]))
                                if sub(v[2],-5,-1)=="_ocpy" then
                                    add(Octiles, ow_squares[#ow_squares])
                                end
                            end
                        end
                  
                    elseif sub(v[2],1,3) == "row" then
                        for i = -10, 10, 1 do
                            if gsq(i, v[3]) then
                                if sub(v[2],-5,-1)=="_ocpy" then
                                    add(Octiles, gsq(i,v[3]))
                                end
                                gsq(i,v[3]).tile_special= v[1]
                                add(ow_squares, gsq(i,v[3]))
                            end
                        end
                    elseif sub(v[2],1,3) =="col" then
                        for i = -10, 10, 1 do
                            if gsq(v[3],i) then
                                if sub(v[2],-5,-1)=="_ocpy" then
                                    add(Octiles, gsq(v[3],i))
                                end
                                gsq(v[3],i).tile_special= v[1]
                                add(ow_squares, gsq(v[3],i))
                            end
                        end
                    elseif sub(v[2],1,4) == "rect" then
                        local x1, y1, x2, y2 = v[3], v[4], v[5], v[6]
                        local s1 = x1 > x2 and -1 or 1
                        local s2 = y1 > y2 and -1 or 1
                        for x = x1, x2, s1 do
                            for y = y1, y2, s2 do
                                if x == x1 or x == x2 or y == y1 or y == y2 then
                                    if gsq(x, y) then
                                        if sub(v[2],-5,-1)=="_ocpy" then
                                            add(Octiles, gsq(x,y))
                                        end
                                        gsq(x, y).tile_special = v[1]
                                        add(ow_squares, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,5) == "frect" then
                        local x1, y1, x2, y2 = v[3], v[4], v[5], v[6]
                        local s1 = x1>x2 and -1 or 1
                        local s2 = y1>y2 and -1 or 1
                        for x = x1, x2,s1 do
                            for y = y1, y2, s2 do
                                if gsq(x, y) then
                                    if sub(v[2],-5,-1)=="_ocpy" then
                                        add(Octiles, gsq(x,y))
                                    end
                                    gsq(x, y).tile_special = v[1]
                                    add(ow_squares, gsq(x, y))
                                end
                            end
                        end
                    elseif sub(v[2],1,3) =="tri" then
                        local x1, y1, x2, y2, x3, y3 = v[3], v[4], v[5], v[6], v[7], v[8]
                        -- Draw the outline of the triangle
                        -- Helper function to add squares along a line
                        local function add_line_squares(x1, y1, x2, y2)
                            local dx = abs(x2 - x1)
                            local dy = abs(y2 - y1)
                            local sx = x1 < x2 and 1 or -1
                            local sy = y1 < y2 and 1 or -1
                            local err = dx - dy
    
                            while true do
                                if gsq(x1, y1) then
                                    add(ow_squares, gsq(x1, y1))
                                    gsq(x1, y1).tile_special = v[1]
                                    if sub(v[2], -5, -1) == "_ocpy" then
                                        add(Octiles, gsq(x1, y1))
                                    end
                                end
    
                                if x1 == x2 and y1 == y2 then break end
                                local e2 = 2 * err
                                if e2 > -dy then
                                    err = err - dy
                                    x1 = x1 + sx
                                end
                                if e2 < dx then
                                    err = err + dx
                                    y1 = y1 + sy
                                end
                            end
                        end
    
                        -- Draw the edges of the triangle
                        add_line_squares(x1, y1, x2, y2)
                        add_line_squares(x2, y2, x3, y3)
                        add_line_squares(x3, y3, x1, y1)
                    elseif sub(v[2], 1, 4) == "ftri" then
                        local x1, y1, x2, y2, x3, y3 = v[3], v[4], v[5], v[6], v[7], v[8]
                        -- Fill the triangle using a scanline algorithm
                        local function interpolate(x1, y1, x2, y2, y)
                            if y2 == y1 then return x1 end
                            return x1 + (x2 - x1) * (y - y1) / (y2 - y1)
                        end
                    
                        -- Sort vertices by y-coordinate (y1 <= y2 <= y3)
                        if y1 > y2 then
                            x1, x2 = x2, x1
                            y1, y2 = y2, y1
                        end
                        if y1 > y3 then
                            x1, x3 = x3, x1
                            y1, y3 = y3, y1
                        end
                        if y2 > y3 then
                            x2, x3 = x3, x2
                            y2, y3 = y3, y2
                        end
                    
                        for y = y1, y3 do
                            local x_start, x_end
                            if y < y2 then
                                x_start = interpolate(x1, y1, x3, y3, y)
                                x_end = interpolate(x1, y1, x2, y2, y)
                            else
                                x_start = interpolate(x1, y1, x3, y3, y)
                                x_end = interpolate(x2, y2, x3, y3, y)
                            end
                    
                            for x = min(x_start, x_end), max(x_start, x_end) do
                                if gsq(x, y) then
                                    add(ow_squares, gsq(x, y))
                                    gsq(x, y).tile_special = v[1]
                                    if sub(v[2], -5, -1) == "_ocpy" then
                                        add(Octiles, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,5) == "ellip" then
                        local cx, cy, rx, ry = v[3], v[4], v[5], v[6]
                        for x = cx - rx, cx + rx do
                            for y = cy - ry, cy + ry do
                                local ellipse_eq = pow((x - cx), 2) / pow(rx, 2) + pow((y - cy), 2) / pow(ry, 2)
                                if ellipse_eq <= 1 and ellipse_eq >= 0.9 then -- Adjust the range to get the border
                                    if gsq(x, y) then
                                        if sub(v[2],-5,-1)=="_ocpy" then
                                            add(Octiles, gsq(x,y))
                                        end
                                        gsq(x, y).tile_special = v[1]
                                        add(ow_squares, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,6) == "fellip" then
                        local cx, cy, rx, ry = v[3], v[4], v[5], v[6]
                        for x = cx - rx, cx + rx do
                            for y = cy - ry, cy + ry do
                                if pow((x - cx),2 )/ pow(rx, 2) + pow((y - cy),2) / pow(ry,2)<= 1 then
                                    if gsq(x, y) then
                                        if sub(v[2],-5,-1)=="_ocpy" then
                                            add(Octiles, gsq(x,y))
                                        end
                                        gsq(x, y).tile_special = v[1]
                                        add(ow_squares, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,4) == "circ" then
                        local cx, cy, r = v[3], v[4], v[5]
                        for x = cx - r, cx + r do
                            for y = cy - r, cy + r do
                                local circle_eq = (x - cx) ^ 2 + (y - cy) ^ 2
                                if circle_eq <= r ^ 2 and circle_eq >= (r - 1) ^ 2 then -- Adjust the range to get the border
                                    if gsq(x, y) then
                                        if sub(v[2],-5,-1)=="_ocpy" then
                                            add(Octiles, gsq(x,y))
                                        end
                                        gsq(x, y).tile_special = v[1]
                                        add(ow_squares, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,5) == "fcirc" then
                        local cx, cy, r = v[3], v[4], v[5]
                        for x = cx - r, cx + r do
                            for y = cy - r, cy + r do
                                if (x - cx) ^ 2 + (y - cy) ^ 2 <= r ^ 2 then
                                    if gsq(x, y) then
                                        if sub(v[2],-5,-1)=="_ocpy" then
                                            add(Octiles, gsq(x,y))
                                        end
                                        gsq(x, y).tile_special = v[1]
                                        add(ow_squares, gsq(x, y))
                                    end
                                end
                            end
                        end
                    elseif sub(v[2],1,4)=="rand" then
                        local sq 
                        local i = 1
                        local j = 0
                        while i <= v[3] do
                            local free_square = get_free_squares()[irnd(#get_free_squares()) + 1]
                            if free_square.event == nil then
                                free_square.tile_special = v[1]
                                add(ow_squares, free_square)
                                if sub(v[2], -5, -1) == "_ocpy" then
                                    add(Octiles, free_square)
                                end
                                i = i + 1
                            end
                            j = j + 1
                            -- Add a condition to break the loop if it runs too many times to avoid infinite loop
                            if j > 1000 then
                                break
                            end
                        end
                    end
                end
    
                for sq in all(ow_squares) do
                    if sub(sq.tile_special,1,4) == "moat" then
                        sq.moat = true
                    end
                    local old_dr = sq.dr
                    local old_upd = sq.upd
            
                    sq.dr = function(sq,x,y)
                        if sub(sq.tile_special,1,4) ~= "void" then
                            old_dr(sq,x,y)
                        end
                        if sq.c_deep then --account for board spawn/despawn anim
                            local n = sq.c_deep
                            y = y + (3/4000)*pow(n,3) - (85/3000)*pow(n,2)
                        end
                        if tileType[sq.tile_special] then
                            tileType[sq.tile_special].dr(sq,x,y)
                        end
                        
                    end
                    sq.upd = function(sq,x,y)
                        old_upd(sq,x,y)
                 
                        if tileType[sq.tile_special] then
                            tileType[sq.tile_special].upd(sq,x,y)
                        end
                        
                    end
                    for sq in all(Octiles) do
                        sq.upd = function (_, x,y)
                                    sq.p={
                                        airy = true,
                                        x = -1309,
                                        y = -1309,
                                        z=0,
                                        tempo = 0,
                                        behavior = {},
                                        bad=true,
                                        type=-1,
                                        name="",
                                        hp=0,
                                        hp_max=0,
                                        dr=function () end,
                                        upd=function () end,
                                        mark ={},
                                        sq=sq,
                                        nocarry=1,
                                    }
                                    for entity in all(ents) do
                                        if entity.x == sq.x and entity.y == sq.y and entity.over and
                                            entity.out then
                                            entity.over = nil
                
                                            if stack.special == 'strafe' then
                                                entity.right_clic = nil
                                            end
                                            if stack.grab then
                                                entity.on_drag= nil
                                            end
                                            entity.out()
                                        end
                                    end
                        end
                    end
                    
                end   
            end
       
        end
        
    end, "tiles")
    
    prepend("goto_sq", function (e, sq) --when a piece leaves a square
        if e.sq then
            if e.sq.tile_special then
                tileType[e.sq.tile_special].onLeave(e, e.sq)
            end
    
        end
    end, "tiletool_move_leave")
    
    append("goto_sq", function (e, sq) --when a piece lands on a square
        if sq.tile_special then
            tileType[sq.tile_special].onEnter(e, sq)
        end 
        -- reset move direction cursor if done push
        if mode.push then
            wait(30, play)
            mode.push = false
        end
    end, "tiletool_move_enter")
    
    -- TUTO
    require("planner/tuto_content.lua")
    -- TUTO PANEL
    ctrl_panel=nil
    chess_panel=nil
    medal_panel = nil
    name_panel = nil
    function create_panels()
        if not ctrl_panel then
            ctrl_panel=mke()
            ctrl_panel.dp=DP_INTER
            ctrl_panel.ctrl_info=1
            ctrl_panel.dr=dr_tuto_panel
            ctrl_panel.x=(3*MCW+8*SQ)/4+100
        end
        if not chess_panel then
            chess_panel=mke()
            chess_panel.dp=DP_INTER
            chess_panel.ctrl_info=2
            chess_panel.dr=dr_tuto_panel
            chess_panel.x=(MCW-8*SQ)/4-100
        end
        
        if not medal_panel then
            medal_panel = mke()
            medal_panel.dp = DP_INTER
            medal_panel.dr = dr_tuto_panel
            medal_panel.x= 42-100
            medal_panel.ctrl_info =3
        end
    
        event_nxt()	
    end
    
    function ev_show_tuto_panels(name)
        name_panel=name
        chess_panel.x=(MCW-8*SQ)/4-100
        if not mode.no_shotgun then chess_panel.x = chess_panel.x-12 end
        mv(chess_panel,100,0,30)
    
        ctrl_panel.x=(3*MCW+8*SQ)/4+100+13
        mv(ctrl_panel,-100,0,30)
    
        medal_panel.x=42-100
        mv(medal_panel, 100, 0, 50)
    
        wait(30,event_nxt)
    end
    
    function dr_tuto_panel(e,x,y)
        local h=content_tuto_panel(e, x, -5000)+5000
        content_tuto_panel(e, x, (MCH-h)/2+4)
    end
    
    function content_tuto_panel(e, x, pY)
        local pan_content = pan_contents[mode_id][name_panel]
        if pan_content then
            local lines 
            local width=65
            if e.ctrl_info ==3 then
                lines= pan_content.medal or {}
                pY= 5
                width = 100
            elseif e.ctrl_info ==1 then 
                lines = pan_content.ctrl or {} 
                width=70
            else
                lines = pan_content.chess or {}
            end
            
            for content in all(lines) do
                if content.space then
                    pY=pY+content.space
                elseif content.text then
                    pY = pprint(get_lang(content.text), x, pY, width, 3, 1)
                elseif content.title then
                    pY = pprint(get_lang(content.title), x, pY, width, 4, 1)
                elseif content.medals then
                    local state =false
                    local next_x=15
                    for k,v in ipairs(medals[mode_id][mode.lvl]) do
                        if mode.turns and mode.turns <= v and not state then
                            next_x = lprint(v ,next_x,pY,5)
                            if k ~= #medals[mode_id][mode.lvl] then
                                next_x = lprint(" / ", next_x, pY, 4)
                            end
                            
                            state= true
                        else
                            next_x = lprint(v,next_x,pY,4)
                            if k ~= #medals[mode_id][mode.lvl] then
                                next_x = lprint(" / ", next_x, pY, 4)
                            end
                        end
                    end
                    state = false
                elseif content.piece then
                    pY=pY+2
                    spr(16+content.piece,x-20,pY)
                    rectfill(x,pY-4,x+24,pY+20,1)
                    dr_movemap(PIECES[content.piece+1],x,pY-4)
                    pY=pY+20
                elseif content.line then
                    line(x-20,pY,x+20,pY,2)
                    pY=pY+2
                elseif content.but and (content.but == "tutoRead" or MOUSE and content.but == "info") then
                    if MOUSE then
                        pY = pY + draw_stick("cursor", x-6, pY, true)
                    else
                        local hw = (butInfo["info"].w + 7 + butInfo["leftPage"].w * 2 + 5)/2
                        local h = max(butInfo["info"].h, max(butInfo["leftPage"].h, 7))
                        draw_button("info", x - hw, pY + ceil((h - butInfo["info"].h) / 2), true, flr(time()%4)==0)
                        spritesheet(console_sheet)
                        sspr( 0,48,7,7, butInfo["info"].w + x - hw, pY)
                        draw_button("leftPage", butInfo["info"].w + 7 + x - hw, pY, true, flr(time()%4)==2)
                        spritesheet(console_sheet)
                        sspr( 0,55,5,7, butInfo["info"].w + 7 + butInfo["leftPage"].w + x - hw, pY)
                        draw_button("rightPage",	butInfo["info"].w + 7 + butInfo["leftPage"].w + 5 	+ x - hw, pY, true, flr(time()%4)==2)
                        pY = pY + max(butInfo["info"].h, max(butInfo["leftPage"].h, 7))
                    end
                elseif content.but then
                    if MOUSE then
                        local replace = {
                            validate = "validate",
                            shoot = "validate",
                            reload = "spacebar",
                            pause = "escape",
                            lstickb = "lstickb"
                        }
                        local but = replace[content.but]
                        pY = pY + draw_button(but, x-2-flr(butInfo[but].w/2.0), pY, true)
                    else
                        pY = pY + draw_button(content.but, x-2-flr(butInfo[content.but].w/2.0), pY, true)
                    end
                elseif content.stick then
                    if MOUSE then
                        pY = pY + draw_stick("cursor", x-4, pY+1, true)
                    else
                        if content.stick2 then
                            local fnt = font()
                            font("pico")
                            print("û", x-4, pY+2, 3)
                            font(fnt)
                            draw_stick(content.stick, x-7-12, pY, true)
                            pY = pY + draw_stick(content.stick2, x-7+12, pY, true)
                        else
                            pY = pY + draw_stick(content.stick, x-7, pY, true)
                        end
                    end
                end
                pY = pY + 2
            end
            pY = pY - 2
        end
        return pY
    end
    
    -- quest system WIP
    local quest_setting = require("planner/quest.lua")
    
    quest = {current={}, completed={}}    
    tbl_import(quest, clone(quest_setting, true))
    for k, v in pairs(quest) do
        if k~= "current" and k~= "completed" then
            map_tbl(v,"name")
        end
    end
    
    require("planner/scene.lua")
    -- Function to add move_N elements
    local function add_move_events(events)
        local count = 0
        
        for k, _ in pairs(events) do
            if type(k) == "number" then
                count = count + 1
            end
        end
    
        for i = 1, count do
            if events["move_" .. i] then
                add(events["move_"..i], {ev=ev_transport, params={i}})
            else
                events["move_" .. i] = {
                    {ev=ev_transport, params={i}}
                }
            end
            events[i.."_solved"]= {}
            events[i.."_unlock"]= {}
        end
    end
    local function add_emote_events(events)
        local count = 0
        local keys = {}
        for k, _ in pairs(events) do
            if type(k) == "string" then
                add(keys, k)
            end
        end
    
        for v in all(keys) do
            if events[v .."_noleft"] then
                add(events[v .."_noleft"], {ev=ev_down_dialogue, params={"noleft"}})
            else
                events[v .."_noleft"] = {
                    {ev=ev_down_dialogue, params={"noleft"}}
            }
            end
            if events[v .."_speechless"] then
                add(events[v .."_speechless"], {ev=ev_down_dialogue, params={"speechless"}})
            else
                events[v .."_speechless"] = {
                    {ev=ev_down_dialogue, params={"speechless"}}
            }
            end
            if events[v .."_nothing"] then
                add(events[v .."_nothing"], {ev=ev_down_dialogue, params={"nothing"}})
            else
                events[v .."_nothing"] = {
                    {ev=ev_down_dialogue, params={"nothing"}}
            }
            end
            events[v .."_empty"] = {}
        end
    end
    local function add_bound(events)
        for _, value in pairs(events) do
            local stack = {}
            local conditions = {}
    
            for k, v in pairs(value) do
                if v.ev == ev_cond then
                    add(stack, {type = "cond", index = k})
                elseif v.ev == ev_else then
                    add(stack, {type = "else", index = k})
                elseif v.ev == ev_end then
                    local end_index = k
                    local else_index = nil
                    local cond_index = nil
    
                    while #stack > 0 do
                        local item = deli(stack, #stack)
                        if item.type == "cond" then
                            cond_index = item.index
                            break
                        elseif item.type == "else" then
                            else_index = item.index
                        end
                    end
    
                    if cond_index then
                        if else_index then
                            add(value[cond_index].params, else_index - cond_index)
                            add(value[cond_index].params, end_index - else_index)
                        else
                            add(value[cond_index].params, end_index - cond_index)
                        end
                    end           
                end
            end
        end
    end
    local function convert_events(events)
        for _, value in pairs(events) do
            for _, v in pairs(value) do
                if type(v.params)~="table" then 
                    v.params= {v.params}
                end
            end
        end
    end
    -- Add move_N elements to the general_events[mode_id] table
    for _, v in pairs(general_events) do
        convert_events(v)
        add_bound(v)
        add_move_events(v)
        add_emote_events(v)
        
    end
    
    mode_id = ""
    defbtn("f", 0, "k:f")
    defbtn("v",0,"k:v")
    defbtn("h",0,"k:h")
    defbtn("r",0,"k:r")
    defbtn("x",0,"k:x")
    defbtn("mcm",0,"m:mb")
    
    function upd()
        if btnp("f") then
            if not hero then
                return
            end
            if not hero.sq then
                return
            end
            local px, py = hero.sq.px, hero.sq.py        
            local x, y = mx-hero.sq.x, my- hero.sq.y
            local up = gsq(px, py-1)
            local down = gsq(px, py+1)
            local left = gsq(px-1, py)
            local right = gsq(px+1, py)
            local conditionDown = -x+y>0 and x+y>0
            local conditionUp = -x - y>0 and x - y>0
            local conditionLeft = -x - y >0 and -x + y>0
            local conditionRight = x - y>0 and x + y>0
            local function repeatable(pos, type)
                if not type then
                    if pos.p.repeatable then
                        if pos.p.repeatable=="deplete" then
                            deli(pos.p.event,1)
                        elseif pos.p.repeatable=="tough" and #pos.p.event>1 then
                            deli(pos.p.event,1)
                        elseif pos.p.repeatable=="recycle" then
                            add(pos.p.event,pos.p.event[1])
                            deli(pos.p.event,1)
                        elseif pos.p.repeatable=="shuffle" then
                            shuffle(pos.p.event)						
                        end
                    end
                else
                    if pos.p.repeatable then
                        if pos.p.repeatable=="deplete" then
                            deli(pos.p.prelude,1)
                        elseif pos.p.repeatable=="tough" and #pos.p.prelude>1 then
                            deli(pos.p.prelude,1)
                        elseif pos.p.repeatable=="recycle" then
                            add(pos.p.prelude,pos.p.prelude[1])
                            deli(pos.p.prelude,1)
                        elseif pos.p.repeatable=="shuffle" then
                            shuffle(pos.p.prelude)						
                        end
                    end
                end
     
            end
            local function trigger_quality(piece)
                local trig_quality= {true, false}
                if piece.trigger and piece.nums then
                    for i = 1, #piece.trigger, 1 do
                        local count_ev = (piece.trigger[i]=="kingkill" or piece.trigger[i]=="pawnkill" 
                                        or piece.trigger[i]=="queenkill" or piece.trigger[i]=="knightkill" 
                                        or piece.trigger[i]=="rookkill" or piece.trigger[i]=="bishopkill"
    
                                        or piece.trigger[i]=="kingkillglobal" or piece.trigger[i]=="pawnkillglobal" 
                                        or piece.trigger[i]=="queenkillglobal" or piece.trigger[i]=="knightkillglobal" 
                                        or piece.trigger[i]=="rookkillglobal" or piece.trigger[i]=="bishopkillglobal") 
                                        and count_event.room[piece.trigger[i]] or count_event[piece.trigger[i]]
                        if piece.nums[1][i] ~= "nil" then
                            if piece.compare[1][i] =="lt" then
                                if count_ev and count_ev >= piece.nums[1][i] then
                                    trig_quality[1] = false
                                    break
                                end
                            elseif piece.compare[1][i] =="gt" then
                                if count_ev and count_ev <= piece.nums[1][i] then
                                    trig_quality[1] = false
                                    break
                                end
                            elseif piece.compare[1][i] =="le" then
                                if count_ev and count_ev > piece.nums[1][i] then
                                    trig_quality[1] = false
                                    break
                                end
                            elseif piece.compare[1][i] =="ge" then
                                if count_ev and count_ev < piece.nums[1][i]  then
                                    trig_quality[1] = false
                                    break
                                end
                            else
                                if count_ev and count_ev ~=piece.nums[1][i] then
                                    trig_quality[1] = false
                                    break
                                end 
                            end
                        end
                    end
                end
         
                if piece.no_trig and piece.nums then
                    for i = 1, #piece.no_trig, 1 do
                        local count_noev = (piece.no_trig[i]=="kingkill" or piece.no_trig[i]=="pawnkill" 
                                        or piece.no_trig[i]=="queenkill" or piece.no_trig[i]=="knightkill" 
                                        or piece.no_trig[i]=="rookkill" or piece.no_trig[i]=="bishopkill"
    
                                        or piece.no_trig[i]=="kingkillglobal" or piece.no_trig[i]=="pawnkillglobal" 
                                        or piece.no_trig[i]=="queenkillglobal" or piece.no_trig[i]=="knightkillglobal" 
                                        or piece.no_trig[i]=="rookkillglobal" or piece.no_trig[i]=="bishopkillglobal") 
                                        and count_event.room[piece.no_trig[i]] or count_event[piece.no_trig[i]]
                        if piece.nums[2][i] ~= "nil" then
                            if piece.compare[2][i]=="lt" then
                                if count_noev and count_noev >= piece.nums[2][i] then
                                    trig_quality[2] = true
                                    break
                                end
                            elseif piece.compare[2][i]=="gt" then
                                
                                if count_noev and count_noev <= piece.nums[2][i] then
                                    trig_quality[2] = true
                                    break
                                end
                            elseif piece.compare[2][i]=="le" then
                                if count_noev and count_noev > piece.nums[2][i] then
                                    trig_quality[2] = true
                                    break
                                end
                            elseif piece.compare[2][i]=="ge" then
                                if count_noev and count_noev < piece.nums[2][i] then
                                    trig_quality[2] = true
                                    break
                                end
                            else
                                if count_noev and count_noev ~=piece.nums[2][i] then
                                    trig_quality[2] = true
                                    break
                                end
                            end
                        end
                    end
                end
                return trig_quality
            end
            if conditionUp and up and up.p then 
                if (not up.p.trigger or is_subset(up.p.trigger, history) and trigger_quality(up.p)[1] and
                (#up.p.no_trig==0 or not is_subset(up.p.no_trig, history) or trigger_quality(up.p)[2]))
                and up.p.event and #events ==0 and general_events[mode_id] then
                    if not up.p.repeatable then
                        for ev in all(up.p.event) do
                            mode.trigger_events(mode_id,ev)
                        end
                    else
                        mode.trigger_events(mode_id,up.p.event[1])
                    end
                    
                    play_events()
                    repeatable(up)
                    up.p.prelude = nil
                elseif up.p.prelude and #up.p.prelude ~=0 then
                    if not up.p.repeatable then
                        for pre in pairs(up.p.prelude) do
                            mode.trigger_events(mode_id, pre)
                        end
                    else
                        mode.trigger_events(mode_id,up.p.prelude[1])
                    end
                    
                    play_events()
                    repeatable(up, true)
                end        
            elseif conditionDown and down and down.p then
                if (not down.p.trigger or is_subset(down.p.trigger, history) and trigger_quality(down.p)[1] and (#down.p.no_trig==0 or not is_subset(down.p.no_trig, history) or trigger_quality(down.p)[2])) 
                and down.p.event and #events ==0 and general_events[mode_id] then
                    if not down.p.repeatable then
                        for ev in all(down.p.event) do
                            mode.trigger_events(mode_id,ev)
                        end
                    else
                        mode.trigger_events(mode_id,down.p.event[1])
                    end
                    play_events()
                    repeatable(down)
                    down.p.prelude = nil
                elseif down.p.prelude and #down.p.prelude ~=0 then
                    if not down.p.repeatable then
                        for pre in all(down.p.prelude) do
                            mode.trigger_events(mode_id,pre)
                        end
                    else
                        mode.trigger_events(mode_id,down.p.prelude[1])
                    end
                    play_events()
                    repeatable(down, true)
                end
            elseif conditionLeft and left and left.p then
                if (not left.p.trigger or is_subset(left.p.trigger, history) and trigger_quality(left.p)[1] and (#left.p.no_trig==0 or not is_subset(left.p.no_trig, history) or trigger_quality(left.p)[2])) 
                and left.p.event and #events ==0 and general_events[mode_id] then
                    if not left.p.repeatable then
                        for ev in all(left.p.event) do
                            mode.trigger_events(mode_id,ev)
                        end
                    else
                        mode.trigger_events(mode_id,left.p.event[1])
                    end
                    play_events()
                    repeatable(left)
                    left.p.prelude = nil
                elseif left.p.prelude and #left.p.prelude ~=0 then
                    if not left.p.repeatable then
                        for pre in all(left.p.prelude) do
                            mode.trigger_events(mode_id,pre)
                        end
                    else
                        mode.trigger_events(mode_id,left.p.prelude[1])
                    end
                    play_events()
                    repeatable(left, true)
                end
            elseif conditionRight and right and right.p then
                if (not right.p.trigger or is_subset(right.p.trigger, history) and trigger_quality(right.p)[1] and (#right.p.no_trig==0 or not is_subset(right.p.no_trig, history)) or trigger_quality(right.p)[2]) 
                and right.p.event and #events ==0 and general_events[mode_id] then
                    if not right.p.repeatable then
                        for ev in all(right.p.event) do
                            mode.trigger_events(mode_id,ev)
                        end
                    else
                        mode.trigger_events(mode_id,right.p.event[1])
                    end
                    play_events()
                    repeatable(right)
                    right.p.prelude = nil
                elseif right.p.prelude and #right.p.prelude ~=0 then
                    if not right.p.repeatable then
                        for pre in all(right.p.prelude) do
                            mode.trigger_events(mode_id,pre)
                        end
                    else
                        mode.trigger_events(mode_id,right.p.prelude[1])
                    end
                    play_events()
                    repeatable(right, true)
                end
            end
        end
    
        if btnp("v") then
            if objectives then
                if objectives.y ==18 then
                    hide_objectives()
                elseif objectives.y ==18-500 then
                    show_objectives()
                end
            end
    
        end
    
        if btnp("h") then
            _log(test.openSesame(PIECES))
        local txt=""
        for k, v in pairs(bestTries) do
            txt = txt .. ":trophy: **LVL:** ".. k .." \n :star: **Best Try:** " .. v.." turns\n\n"
        end
            clipboard(txt)
        end
        if playing and btnr("r") then
            local Return = function(base) 
                local buffer = 600
                if hero and hero.sq and hero.sq.t >buffer  and not pressR then
                    pressR = true
                    mode.trigger_events(mode_id, "move_"..base)
                    play_events()
                end
            end
            if hero and (hero.win or hero.dead or hero.fail) then return end
            if mode_id =="puzzle" then
                if mode.lvl ==1 or mode.lvl ==7 then
                    return
                elseif mode.lvl <7 or mode.lvl ==100 then
                    Return(1)
                elseif mode.lvl <14 then
                    Return(7)
                end
            end
        end
        if playing and btnr("x") then
            remove_buts()
            wait(23, function()
                xpl_king(hero)
            end)
        end
    
        if btnr("mcm") then
            local sq= get_square_at(mx, my)
            if sq and not sq.draft then
                sq.draft= true
            elseif sq and sq.draft then
                sq.draft= false
            end
        end
        if DEV and rov and mcl then
            selected= rov
            if edit_panel then
                show_edit_panel()
            end
            
        end
        if selected and not btn("k:lshift") and mcr  then
            selected= nil
            if edit_panel then
                hide_edit_panel()
            end
        end
    end
    function set_updater()
        local e = mke()
        e.upd = function()
            upd()
        end
    end
    function set_drawing(dp)
        local e = mke()
        e.dr = function()
            if dp == 0 then
                draw_0()
            elseif dp ==1 then
                draw_1()
            elseif dp ==2 then
                draw_2()
            elseif dp ==3 then
                draw_3()
            elseif dp ==4 then
                draw_4()
            elseif dp ==5 then
                draw_5()
            elseif dp ==6 then
                draw_6()
            end
        end
        e.dp = dp
    end
    
    function set_all_drawing()
        for dp = DP_BG, DP_TOP, 1 do
            set_drawing(dp)
        end
    end
    cl_danger={}
    cl_movement = {}
    autocalls = {
        on_new_turn = {function ()
            cl_danger={}
            cl_movement={}
            for k, v in pairs(squares) do
                if v.draft then
                    v.draft = false
                end
                if DEV and v.p and v.p.jail and v.p.old_upd then
                    v.p.cd = v.p.cd-1
                end
            end
        end},
        on_bad_death = {function(p) 
            if p == selected and edit_panel then
                hide_edit_panel()
            end
        end},
        on_hero_death= {function()
            hide_edit_panel()
        end}
    
    }
    function set_autocall()
        for name,t in pairs(autocalls) do if #t > 0 then
            local foo = nil
            if mode[name] then foo = mode[name] end
            mode[name] = function(...)
                for f in all(t) do f(...) end
                if foo then foo(...) end
            end
        end end
    end
    append("set_mode",set_autocall,"terminal autocall")
    
    append("init_game",set_all_drawing,"terminal drawing")
    append("init_game",set_updater,"updater")
    append("set_mode", function()
        function mode.trigger_events(mode, id)
            if general_events[mode][id] then
                for event in all(general_events[mode][id]) do
                    add_event(event.ev, unpack(event.params or {}))
                end
                add_unique(history, tostr(id))
                add(history.room, tostr(id))
            end
        end
       
        function mode.move_ally(index, nxt) 
            if mode.turns % allies[index].tempo ==0 then
                local a=get_range(allies[index])
            
                -- SORT
                local f=function(sq) 
                    local sco=sq[allies[index].seek]+sq.risk
                    if sq.py <= 1 or sq.py >= 6 or sq.px <= 1 or sq.px >= 6 then
                        sco = sco + 50
                    end
                    return sco	
                end
            
                shuffle(a)
                custom_sort(a,f)
                if #a>0 then
                    allies[index].cd=0
                    allies[index].ready=false
                    allies[index].still=nil
                    goto_sq(allies[index],a[1],TEMPO,nxt)	
                    nxt=nil
                end
                sfx("jump")
            end
        end
        function mode.set_id(id)
            mode_id = id
        end
    
        function mode.load_entities(entity)
            add(entities,entity)
        end
        mode.px=0
        mode.py=0
        mode.destination = {}
        mode.base = {chamber_max=1, firepower=4, firerange=3, spread=55, ammo_max=6, knockback=0,
        soul_slot=0, gain={}, ruler = 99, ai_lvl=2
        }
        mode.tbase = {}
        function mode.clear_allies()
            for i = 1, #allies, 1 do
                kl(allies[i])
                deli(allies, i)
            end
        end
    
        function mode.room_history(value)
            if value then
                if not count_event.room[value] then
                    count_event.room[value] = 1
                else 
                    count_event.room[value] = count_event.room[value] + 1
                end   
    
                add(history.room, value)
            end
            return history.room
        end
        function mode.del_room_history(value)
            del(history.room, value)
            if count_event.room[value] then
                count_event.room[value] = count_event.room[value] - 1
            end
    
        end
        function mode.history()
            return history
        end
        function mode.clear_history()
            count_event = {room={}}
            history= {room={}}
            quest.current={}
            quest.completed={}
            Octiles = {}
            mode.turns = 0
            bestTries = {}
        end
        function mode.count_event()
            return count_event
        end
        function mode.mk_entity(...)
            mk_entity(...)
        end
        function mode.del_entity(name)
            if not name then
                for k, v in pairs(entities) do
                    kl(v)  
                    local px = ceil(v.x/SQ)
                    local py = ceil(v.y/SQ)
                    gsq(px,py).p = nil 
                    gsq(px,py).op = nil 
                    gsq(px,py).highlight = true 
                    gsq(px,py).danger = {}
                end
                entities={}
            else
                for k, v in pairs(entities) do
                    if v.name == name then
                        kl(v)
                        local px = ceil(v.x/SQ)
                        local py = ceil(v.y/SQ)
                        gsq(px,py).p = nil 
                        gsq(px,py).op = nil 
                        gsq(px,py).highlight = true 
                        gsq(px,py).danger = {}
    
                        entities[k] = nil
                    end
                end
            end
        end
        function mode.cond_medal(lvl)
            if medals[mode_id][lvl] and bestTries[lvl] and bestTries[lvl] <= medals[mode_id][lvl][1] then
                return 1
            elseif medals[mode_id][lvl] and bestTries[lvl] and bestTries[lvl] <= medals[mode_id][lvl][2] then
                return 2
            elseif medals[mode_id][lvl] and bestTries[lvl] and bestTries[lvl] <= medals[mode_id][lvl][3] then
                return 3
            elseif medals[mode_id][lvl] and bestTries[lvl] and bestTries[lvl] > medals[mode_id][lvl][3] then
                return 4
            else
                return 0
            end
        end
        mode.push = false
        function mode.loadSAVE(id)
            if SAVE[id] then
                if SAVE[id].bestTries then
                   bestTries = SAVE[id].bestTries
                end
                if SAVE[id].global_history then
                    if not DEV then
                       tbl_import(history, SAVE[id].global_history) 
                    else
                       tbl_import(history, SAVE[id].global_history) 
                        add(history, "dev")
                    end
                end
                if SAVE[id].room_history then
                    tbl_import(history.room, SAVE[id].room_history)
                end
                if SAVE[id].global_count_ev then
                    tbl_import(count_event, SAVE[id].global_count_ev)
                end
                if SAVE[id].room_count_ev then
                    tbl_import(count_event.room, SAVE[id].room_count_ev)
                end
                if SAVE[id].current_quest then
                    tbl_import(quest.current, SAVE[id].current_quest)
                end
                if SAVE[id].completed_quest then
                    tbl_import(quest.completed, SAVE[id].completed_quest)
                end
            else
                SAVE[id]= {}
            end
        end
    
    end, "event_functions")
    function on_sq_but_init(but,sq)
        
    end
    if DEV then
        add(TEST_CARDS, "Pawn")
        add(TEST_CARDS, "Knight")
        add(TEST_CARDS, "Bishop")
        add(TEST_CARDS, "Rook")
        add(TEST_CARDS, "Queen")
        add(TEST_CARDS, "King")
        add(TEST_CARDS, "Gryphon")
        add(TEST_CARDS, "Nightrider")
        add(TEST_CARDS, "Mini Knight")
        add(TEST_CARDS, "Patrol")
    end
    local drag_ca
    function on_card_but_init(but,ca)
        if ca.piece then
            local x
            local y
            local dx
            local dy
            but.left_press = function()
                if not but.drag then
                    x = ca.x
                    y = ca.y
                    dx = x - mx
                    dy = y - my
                end
            end
            but.on_drag = function()
                if drag_ca or ca.flipped then return end
                drag_ca = ca
                remove_buts()
                local function f(self)
                    local sq = get_square_at(mx,my)
                    if not mlb then
                        if placeable(sq,ca.type_piece) then
                            if ca.skip_turn and check_folly_shields(hero.sq) then
                                show_danger(hero.sq)
                                ca.x = mx + dx
                                ca.y = my + dy
                                mvt(ca,x,y,8,play)
                            else
                                ca.x = x
                                ca.y = y
                                if ca.use then
                                    local id = tostr(ca).."_used"
                                    uplift({[id]=1}) -- this function will save import table to stack, additional value to already existed key
                                    if stack[id] == ca.use then flip_card(ca) end
                                elseif ca.undead then
                                      
                                else
                                    flip_card(ca)
                                end
                                local p = new_piece(ca.type_piece,true,sq)
                                p.cd = 1
                                p.old_upd = p.upd
                                p.upd = function() 
                                    p.old_upd() 
                                    sq.p.jail = true
                                    sq.p.prison_bar = 1
                                end
                                selected = p
                                if edit_panel then
                                    show_edit_panel()
                                end
                                if ca.tear then p.ca = ca end
                                fx_spawn(p,8)
                                -- build_stack()
                                wait(20,ca.skip_turn and opp_turn or play)
                            end
                        else
                            -- invalid placement = snap card back to its original position
                            ca.x = mx + dx
                            ca.y = my + dy
                            mvt(ca,x,y,8,play)
                            sfx("wrong_shield")
                        end
                        kl(self)
                        drag_ca = nil
                        return
                    end
                    if sq then
                        ca.x = MCW
                        ca.y = MCH
                    else
                        ca.x = mx + dx
                        ca.y = my + dy
                    end
                end
                loop(f)
            end
        elseif ca.tile then
            local x
            local y
            local dx
            local dy
            but.left_press = function()
                if not but.drag then
                    x = ca.x
                    y = ca.y
                    dx = x - mx
                    dy = y - my
                end
            end
            but.on_drag = function()
                if drag_ca or ca.flipped then return end
                drag_ca = ca
                remove_buts()
                local function f(self)
                    local sq = get_square_at(mx,my)
                    if not mlb then
                        if sq then
                            ca.x = x
                            ca.y = y
                            if not sq.old_dr or not sq.old_upd then
                                sq.old_dr = sq.dr
                                sq.old_upd = sq.upd
                            end
                          
                            sq.upd = function(sq,x,y)
                                sq.old_upd(sq,x,y)
                                if sq.tile_special ~="moat" then
                                    sq.moat = false
                                end 
                                if tileType[ca.type_tile] then
                                    tileType[ca.type_tile].upd(sq,x,y)
                                end
                            end
                            sq.dr =function (sq,x,y)
                                sq.old_dr(sq,x,y)
                                if sq.c_deep then --account for board spawn/despawn anim
                                    local n = sq.c_deep
                                    y = y + (3/4000)*pow(n,3) - (85/3000)*pow(n,2)
                                end
                                if tileType[ca.type_tile] then
                                    tileType[ca.type_tile].dr(sq,x,y)
                                end
                            end
                            sq.tile_special = ca.type_tile
                            wait(20, play)
                        else
                            -- invalid placement = snap card back to its original position
                            ca.x = mx + dx
                            ca.y = my + dy
                            mvt(ca,x,y,8,play)
                            sfx("wrong_shield")
                        end
                        kl(self)
                        drag_ca = nil
                        return
                    end
                    if sq then
                        ca.x = MCW
                        ca.y = MCH
                    else
                        ca.x = mx + dx
                        ca.y = my + dy
                    end
                end
                loop(f)
            end
        end
    end
    append("play",function()
        for e in all(ents) do if e.button then
            if e.issq then
                for sq in all(squares) do 
                    if e.x == sq.x and e.y == sq.y then
                        on_sq_but_init(e,sq)
                        break
                    end 
                end
            elseif e.iscard then
                for sl in all(card_slots) do
                    local ca = sl.ca
                    if ca and e.x == sl.x and e.y == sl.y then
                        on_card_but_init(e,ca)
                        break
                    end
                end
            end
        end end
    end,"terminal change buttons")
    
    function dr_clockwork_range(p)
        local old_spr = spritesheet()
        local function get_clockwork_range(p)
            local danger = {}
            local movement ={}
            local px = p.sq.px
            local py = p.sq.py 
            for index = 1, #p.behavior, 1 do
                local ind =  (p.turn -1 -p.buffer +index-1) % p.tempo+1
                if p.behavior[ind].atk then
                    for i = 2, #p.behavior[ind], 2 do
                        if gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py) and (not gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py).p or gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py).p ==p) then
                            add(danger, {p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py})
                            px = px + p.behavior[ind][i-1]
                            py = py + p.behavior[ind][i]
                        else
                            return danger, movement
                        end                        
                    end
                elseif p.behavior[ind].move then
                    for i = 2, #p.behavior[ind], 2 do
                        if gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py) and (not gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py).p or gsq(p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py).p ==p) then
                            add(movement, {p.behavior[ind][i-1]+ px,p.behavior[ind][i]+ py})
                            px = px + p.behavior[ind][i-1]
                            py = py + p.behavior[ind][i]
                        else
                            return danger, movement
                        end                        
                    end
                end
            end
            return danger, movement
        end
        local dan, mov = get_clockwork_range(p)
    
        spritesheet("customtiles")
        for v in all(dan) do
            local sq= gsq(v[1], v[2])
            sspr(784+cyc(16,2),0,16,16,sq.x,sq.y)
        end
        for v in all(mov) do
            local sq= gsq(v[1], v[2])
            sspr(816+cyc(16,2),0,16,16,sq.x,sq.y)
        end
        spritesheet(old_spr)
    end
    defbtn("e",0,"k:e")
    defbtn("b",0,"k:b")
    defbtn("g",0,"k:g")
    function draw_0()end
    function draw_1()end
    function draw_2()
        local old_spr = spritesheet()
        spritesheet("customtiles")
      
        for k, v in pairs(bads) do
            if v.inert or v.cd <= -100 then
                spr(47, v.x, v.y)
    
            elseif v ==selected then
    
                spr(53, v.x, v.y)
    
            end
        end
    
        for v in all(cl_movement) do
            local sq= gsq(v[1], v[2])
            if sq then
                spr(1, sq.x, sq.y)
            end
            
        end
        
        for v in all(cl_danger) do
            local sq= gsq(v[1], v[2])
            if sq then
                spr(2, sq.x, sq.y)
            end
           
        end
        if rov and rov.cus_move and rov.behavior and #rov.behavior>0 and rov.behavior[1].id=="clockwork" then
            dr_clockwork_range(rov)
        end
        for k, v in pairs(squares) do
            if v.draft then
                spr(48, v.x, v.y)    
            end
        end
    
        spritesheet(old_spr)
    
    end
    function draw_3()end
    function draw_4()
        if drag_ca and get_square_at(mx,my) then
            if drag_ca.piece then
                spritesheet("pieces")
                PIECES[drag_ca.type_piece+1].custom_dr({},mx-7,my-7)
                spritesheet("gfx")
            elseif drag_ca.tile then
                spritesheet("customtiles")
                tileType[drag_ca.type_tile].dr({},mx-7,my-7)
                spritesheet("gfx")
            end
    
        end
    end
    function draw_5()
    
    end
    function draw_6()
        if btn("e") then for k,e in pairs(ents) do if not e.glacies then lprint(k,e.x,e.y,5, 0, 4) end end end
        if btn("b") then for k,e in pairs(ents) do if not e.glacies and e.button then lprint(k,e.x,e.y,5,0,4) end end end
        if btn("g") then lprint(mx..","..my, 5, 173,5,0,4) end
    end
    