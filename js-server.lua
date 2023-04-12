local js = {
    queue = {},
    actions = {},
    isWeb = love.system.getOS() == "Web",
}

local function split(str, sep)
    local t={}
    for sub_str in string.gmatch(str, "([^"..sep.."]+)") do
            table.insert(t, sub_str)
    end
    return t
end

-- This runs executes the "runCommand" on the lua-server.js with given arguments.
function js.run(cmd, ...)
    local command = "JS: " .. cmd
    local args = {...}
    for i = 1, #args do
        command = command .. ">>>" .. tostring(args[i])
    end

    print(command)
end

-- This directly executes the given code. 
-- Note that the server may not allow this since eval is considered a security risk.
function js.eval(code)
    print("RUN_JS: " .. code)
end

-- Gets and Runs the queue.
function js.update()
    -- Waiting for input will cause the game to freeze if not on web or without the cutsom love.js file.
    if not js.isWeb then
        return
    end

    -- The new love.js will instantly return a string with all the commands.
    local input = io.read()
    if input == nil then
        return
    end
    
    -- Commands are split by "<<<"
    local commands = split(input, "<<<")
    for _, commandStr in ipairs(commands) do
        if string.sub(commandStr, 1, 5) == "LUA: " then
            local command = {}

            -- Arguments are split by the character ">>>"
            local args = split(string.sub(commandStr, 6), ">>>")

            command[1] = 1
            command[2] = args[1]
            command[3] = {}
            for i = 2, #args do
                table.insert(command[3], args[i])
            end
            table.insert(js.queue, command)
        elseif string.sub(commandStr, 1, 9) == "RUN_LUA: " then
            local command = {}
            command[1] = 2
            command[2] = string.sub(commandStr, 10)
            table.insert(js.queue, command)
        end
    end

    for _, command in ipairs(js.queue) do
        -- lua() function
        if command[1] == 1 then
            if js.actions[command[2]] then
                js.actions[command[2]](unpack(command[3]))
            end

        -- run_lua() fucntion
        else
            local func, err = loadstring(command[2]);
            if func then func() end
        end
    end

    -- reseting the queue
    js.queue = {}
end

-- Binds a function to a specific call from javascript.
-- 'func' takes the arguments passed from the javascript call.
function js.set(action, func)
    js.actions[action] = func
end

return js