function os.castToTypeOf(val, typeOf)
    local t, f = type(typeOf), type(val)
    if t == f then
        return val
    elseif t == 'number' then
        return tonumber(val)
    elseif t == 'string' then
        return tostring(val)
    elseif t == 'boolean' and f == 'string' then
        return string.asBoolean(val)
    else
        error('Could not cast from ' .. type(val) .. ' to ' .. t, 2)
    end
end

-- term.clear() already exists
function os.clear()
    term.clear()
    term.setCursorPos(1, 1)
end

function os.loading(color, func) -- func is a function that returns a boolean (that is all), true means stop
    local anim = { '|', '/', '-', '\\' }
    local i = 1;
    local x, y = term.getCursorPos()
    while (func ~= nil and not func()) or true do
        local x1, y1 = term.getCursorPos()
        term.setCursorPos(x, y)
        term.writeColored(anim[i], color ~= nil and color or term.getTextColor())
        if x1 ~= x and y1 ~= y then
            term.setCursorPos(x1, y1)
        end
        i = i + 1
        if i > 4 then
            i = 1
        end
        sleep(0.1)
    end
end

function os.pause()
    write('Press any key to continue')
    os.pullEvent('key')
end

-- Return a proxy of the given table that's read-only
function os.readOnly(t)
    local proxy = {}
    local mt = { -- create a meta-table
        __index = t,
        __newindex = function(t, k, v)
            error('Attempt to update a read-only table', 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

function os.spinner(color, func)
    local anim = { {
        '   O      ',
        ' O      O ',
        'O        O',
        'O        O',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O        ',
        'O        O',
        'O        O',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O         ',
        'O        O',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        'O         ',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        'O        O',
        ' O        ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        'O        O',
        ' O      O ',
        '   O      '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        'O        O',
        ' O      O ',
        '      O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        'O        O',
        '        O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        'O        O',
        '         O',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        ' O      O ',
        '         O',
        'O        O',
        ' O      O ',
        '   O  O   '
    }, {
        '   O  O   ',
        '        O ',
        'O        O',
        'O        O',
        ' O      O ',
        '   O  O   '
    }, {
        '      O   ',
        ' O      O ',
        'O        O',
        'O        O',
        ' O      O ',
        '   O  O   '
    } }
    local frame = 1
    local sw, sh = string.len(anim[1][1]), #anim[1]
    while true do
        for i = 1, sh do
            term.setCursorPos(math.ceil(w / 2 - sw / 2), math.ceil(h / 2) - sh / 2 + i - 1)
            term.writeColored(anim[frame][i], color ~= nil and color or term.getTextColor())
        end
        frame = frame + 1
        if frame > #anim then
            frame = 1
        end
        sleep(0.075)
    end
end

function os.try(func, ...)
    return pcall(func, ...)
end
