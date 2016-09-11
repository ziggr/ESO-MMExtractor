dofile("mm_lib.lua")

FN_INPUT  = arg[1]
FN_OUTPUT = arg[2]

io.input(FN_INPUT)
io.output(FN_OUTPUT)


function line_to_mm(line)
    -- 67x|H1:item:30156:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
    --ct, link = string.match(line, "([%dx]*)(|H.-:item:.-|h|h)")
    --print("ct="..ct.." link="..link)
    print("# Line:"..line)
    local acc = 0
    for ct, link in string.gmatch(line, "([%dx]*)(|H.-:item:.-|h|h)") do
        if link == "" then return "" end
        if ct == "" then
            ct = 1
        else
            ct = string.gsub(ct, "x", "")
            ct = tonumber(ct)
        end
        local history = link_to_history(link)
        if not history then return "" end
        local avg = history:AverageFirst()
        print("ct=".. ct .. " x avg="..avg.. " = " .. tostring(ct*avg) .. " link="..link)
        acc = acc + ct * avg
    end
    return acc
end


while true do
    local line = io.read()
    if line == nil then break end
    local val = line_to_mm(line)
    io.write(val, "\n")
end
