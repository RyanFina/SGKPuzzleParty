local M = {}

function printNestedValues(tbl, depth, max)
    depth = depth or 1
    max = max or 4
    local spacing = ""
    local index = 0
    while spacing == "" and depth ~= 0 do
        for i = 0, depth, 1 do
            spacing = spacing .. "\t"
        end
    end
    for key, innerTable in pairs(tbl) do
        index = index + 1
        -- _log(index .. "/ "..depth .. " / " .. max)
        if depth > max then
            break
        end
        
        if type(key) == "table" then
            _log("oops")
        else
            
            -- Check if the current value is a table
            if type(innerTable) == "table" then
                -- Iterate through the inner table recursively
                _log(spacing .. key .. ":")
                printNestedValues(innerTable, depth + 1)
            else
                -- Print the value if it's not a table
                _log(spacing .. key .. ": " .. tostr(innerTable))
            end
            if depth == 0 and index == #tbl then
                _log(spacing .. "--------------")
            end
        end

    end
end

function M.openSesame(mystery, name)
    name = name or ""
    _log(name)
    if type(mystery) == "table" then
        printNestedValues(mystery)
    elseif type(mystery) == "nil" then
        _log("nothing here")
    else
        _log(mystery)
    end
end

return M
