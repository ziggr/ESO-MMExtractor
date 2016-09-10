-- mm.lua
--
-- mm
--
-- Return the MM for a single item link
--
-- Intended to make it easier to calculate prices during a guild auction.
dofile("mm_lib.lua")



function parse_argv()
    local links = {}
    for i,link in ipairs(arg) do
        table.insert(links, link)
    end
    return links
end

function loop_over_links()
    for _,link in ipairs(LINKS) do
        local history    = History:New("name?", link)
        local item_id    = to_item_id(link)
        local item_index = to_item_index(link)
        local sd = MMDATA[item_id][item_index]
        if sd then
            local item_desc = sd["itemDesc"]
            history.name = item_desc
            for _,mm_sale in ipairs(sd["sales"]) do
                history:Append(mm_sale)
            end
        end


        l = {}

        for days_ago, _ in pairs(CUTOFFS) do
            local avg = history:Average(days_ago)
            table.insert(l, avg)
        end
        table.insert(l, history.name)
        write_list(l)
    end
end

-- main ----------------------------------------------------------------------

LINKS   = parse_argv()

loop_over_links()

