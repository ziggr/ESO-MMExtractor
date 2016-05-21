-- MMExtractor.lua
--
-- Export the entire Master Merchant database as a single tab-delimited-text file.
-- Runs in ~5 seconds, produces a 30+MB tab-delimited-text file.
--
-- Intentially stupid: no thinking. Just convert to a more public format.

OUT_FILE_PATH = "./MMExtractor.txt"
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))
TAB = "\t"

function d(s)
    print(s)
end

function loop_over_input_files()
    write_header()
    for i = 0,20 do
        local in_file_path = "../../SavedVariables/MM"
                             .. string.format("%02d",i)
                             .. "Data.lua"
        local var_name = "MM" .. string.format("%02d",i)
                         .. "DataSavedVariables"
        local sales_data = read_input_file(in_file_path, var_name)
        extract(sales_data)
    end
end

-- Dodge "No such file or directory" IO errors
--
-- http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function file_exists(in_file_path)
    local f = io.open(in_file_path, "r")
    if f == nil then
        return false
    end
    io.close(f)
    return true
end

-- Read one MM00Data.lua file and return its "SalesData" table.
function read_input_file(in_file_path, var_name)
                        -- Read it.
    if not file_exists(in_file_path) then return nil end
    dofile(in_file_path)

                        -- Find the "SalesData" table within it.
    var = _G[var_name]
    _G[var_name] = nil
    return var["Default"]["MasterMerchant"]["$AccountWide"]["SalesData"]
end

-- Scan through a "SalesData" table, writing all sales records to CSV.
function extract(sales_data)
    if not sales_data then return end
    for k,v in pairs(sales_data) do     -- k  = 45061
        for kk,vv in pairs(v) do        -- kk = "31:0:3:12:0"
            if vv["sales"] then
                item_desc = vv["itemDesc"]
                for i, sale in ipairs(vv["sales"]) do
                    extract_sale(item_desc, sale)
                end
            end
        end
    end
end

HEADER = { "itemDesc", "seller", "buyer", "price", "quant", "timestamp", "guild", "itemLink" }
function write_header()
    l = "# "
    for i,key in ipairs(HEADER) do
        if 1 < i then
            l = l .. TAB
        end
        l = l .. key
    end
    OUT_FILE:write(l .. "\n")
end

-- Write one sale record
function extract_sale(itemDesc, sale)
    l = item_desc .. TAB
    for i,key in ipairs(HEADER) do
        if 1 < i then
            l = l .. TAB
        end
        if key == "item_desc" then
            l = l .. item_desc
        else
            l = l .. b(sale, key)
        end
    end
    OUT_FILE:write(l .. "\n")
end

-- ignore "nil" as empty string
function b(table,key)
    if table[key] == nil then return "" end
    return tostring(table[key])
end

loop_over_input_files()
