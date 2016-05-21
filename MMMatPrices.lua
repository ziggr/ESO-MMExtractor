-- MMMatPrices.lua
--
-- Scan the entire Master Merchant database. Export 10-day and 30-day average prices for all the crafting materials that Zig cares about.

OUT_FILE_PATH = "./MMMatPrices.txt"
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))
TAB = "\t"

-- Cutoffs -------------------------------------------------------------------
-- Want to output 10-day and 30-day averages? Here is where those numbers 10 and 30 appear, and get translated to seconds-since-the-epoch timestamp numbers.
DAYS_AGO = { 10, 30 }
CUTOFFS = {}    -- integer days_ago ==> cutoff timestamp

-- "name" here is what Zig uses in spreadsheets, NOT the official display name
-- from ESO data with it's goofy ^ns suffix.
MATS = {
  { "jute"          , "|H0:item:811:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "flax"          , "|H0:item:4463:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "cotton"        , "|H0:item:23125:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "spidersilk"    , "|H0:item:23126:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ebonthread"    , "|H0:item:23127:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "kresh"         , "|H0:item:46131:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ironthread"    , "|H0:item:46132:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "silverweave"   , "|H0:item:46133:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "void cloth"    , "|H0:item:46134:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ancestor silk" , "|H0:item:64504:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }

}


HISTORY = {}    -- "link" ==> History table, initialized in init_history()

-- Sale ----------------------------------------------------------------------
-- One sale, whether for 1 or a stack of 200 or anywhere in between.
-- Element of History
Sale = {
  gold = 0
, ct   = 0
}

function Sale:New(gold, ct)
    local o = { gold = gold
              , ct   = ct
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Sale:Add(b)
    self.gold = self.gold + b.gold
    self.ct   = self.ct   + b.ct
end

function Sale:Average()
    if self.ct == 0 then return 0 end
    local avg_f = self.gold / self.ct
    local avg_i = math.floor(avg_f + 0.5)
    return avg_i
end

-- History -------------------------------------------------------------------
-- One material's sales history
History = {
  name = ""             -- "Jute"
, link = ""             -- "|H0:item:811:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
}

function History:New(name, link)
    local o = { name = name
              , link = link
              }
    for days_ago, _ in pairs(CUTOFFS) do
        o[days_ago] = {}
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

-- If a sale is within the last 10 days, append it to the last-10-days list.
-- Same for the 30-day list.
function History:Append(mm_sale)
    --d(self.name)
    local ts = mm_sale.timestamp
    for days_ago, cutoff in pairs(CUTOFFS) do
        if cutoff <= ts then
            sale = Sale:New(mm_sale.price, mm_sale.quant)
            table.insert(self[days_ago], sale)
        end
    end
end

-- Average one list of Sale records
function History:Average(days_ago)
    local l   = self[days_ago]
    local acc = Sale:New(0, 0)
    for _, sale in ipairs(l) do
        acc:Add(sale)
    end
    return acc:Average()
end

-- Create and return a table of "link" ==> History, one element for each MATS line.
function init_history()
    local r = {}
    for _, name_link in ipairs(MATS) do
        local name = name_link[1]
        local link = name_link[2]
        r[link] = History:New(name, link)
    end
    return r
end

-- Return earliest timestamp for N days ago. Any timestamp smaller than this is unworthy.
function Cutoff(days_ago)
    local now = os.time()
    return now - 24*60*60*days_ago
end

function init_cutoffs()
    local r = {}
    for _, days_ago in ipairs(DAYS_AGO) do
        r[days_ago] = Cutoff(days_ago)
    end
    return r
end


-- ===========================================================================
-- Reading MM data
-- ===========================================================================

function loop_over_input_files()
    for i = 0,20 do
        local in_file_path = "../../SavedVariables/MM"
                             .. string.format("%02d",i)
                             .. "Data.lua"
        local var_name = "MM" .. string.format("%02d",i)
                         .. "DataSavedVariables"
        local mm_sales_data = read_input_file(in_file_path, var_name)
        record_mm_sales_data(mm_sales_data)
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
    local var = _G[var_name]
    _G[var_name] = nil
    return var["Default"]["MasterMerchant"]["$AccountWide"]["SalesData"]
end

-- Scan through a "SalesData" table, recording all mat sales records to HISTORY.
function record_mm_sales_data(mm_sales_data)
    if not mm_sales_data then return end
    for k,v in pairs(mm_sales_data) do     -- k  = 45061
        for kk,vv in pairs(v) do        -- kk = "31:0:3:12:0"
            if vv["sales"] then
                for i, mm_sale in ipairs(vv["sales"]) do
                    record_mm_sale(mm_sale)
                end
            end
        end
    end
end

function record_mm_sale(mm_sale)
    --d(mm_sale.itemLink)
    local h = HISTORY[mm_sale.itemLink]
    if h then
        --d("found    : " .. mm_sale.itemLink)
        h:Append(mm_sale)
    else
        --d("not a mat: " .. mm_sale.itemLink)
    end
end

-- ===========================================================================
-- Writing data
-- ===========================================================================

function write_list(l)
    local line = ""
    for i,key in ipairs(l) do
        if 1 < i then
            line = line .. TAB
        end
        line = line .. key
    end
    OUT_FILE:write(line .. "\n")
end

function write_averages()
    write_header()
    for i, name_link in ipairs(MATS) do
        local name    = name_link[1]
        local link    = name_link[2]
        local history = HISTORY[link]
        local l       = { name, link }
        for _, days_ago in ipairs(DAYS_AGO) do
            local avg = history:Average(days_ago)
            table.insert(l, string.format("%d", avg))
        end
        write_list(l)
    end
end

function write_header()
    local l = { "# name", "link" }
    for _, days_ago in ipairs(DAYS_AGO) do
        table.insert(l, tostring(days_ago) .. " day average")
    end
    write_list(l)
end

-- ignore "nil" as empty string
function b(table,key)
    if table[key] == nil then return "" end
    return tostring(table[key])
end


function d(s)
    print(s)
end

-- main ----------------------------------------------------------------------

CUTOFFS = init_cutoffs()
HISTORY = init_history()

loop_over_input_files()

write_averages()
