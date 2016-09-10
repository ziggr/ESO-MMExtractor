-- mm_lib.lua


-- Cutoffs -------------------------------------------------------------------
-- Want to output 10-day and 30-day averages? Here is where those numbers 10 and 30 appear, and get translated to seconds-since-the-epoch timestamp numbers.
DAYS_AGO    = { 10, 30 }
CUTOFFS     = {}    -- integer days_ago ==> cutoff timestamp
NOW         = os.time()
SEC_PER_DAY = 24*60*60

TAB = "\t"

-- Sale ----------------------------------------------------------------------
-- One sale, whether for 1 or a stack of 200 or anywhere in between.
-- Element of History
Sale = {
  gold = 0
, ct   = 0
, ts   = 0
}

function Sale:New(gold, ct, ts)
    local o = { gold = gold
              , ct   = ct
              , ts   = ts
              }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Sale:Add(b)
    self.gold = self.gold + b.gold
    self.ct   = self.ct   + b.ct
end

function Sale:AddWeighted(b, weight)
    self.gold = self.gold + b.gold * weight
    self.ct   = self.ct   + b.ct   * weight
end

-- Return a simple mean price of this single sales record.
function Sale:Mean()
    if self.ct == 0 then return 0 end
    local avg_f = self.gold / self.ct
    local avg_i = math.floor(avg_f + 0.5)
    return avg_i
end

-- How many days ago was this sale?
-- Today = 0
function Sale:DaysAgo()
    local secs_ago = NOW - self.ts
    local days_ago = math.floor(secs_ago / SEC_PER_DAY)
    -- d("NOW:" .. tostring(NOW).. " self.ts:" .. tostring(self.ts)
    --   .. " secs_ago:" .. tostring(secs_ago) .. " days_ago:"..tostring(days_ago))
    return days_ago
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
            sale = Sale:New(mm_sale.price, mm_sale.quant, mm_sale.timestamp)
            table.insert(self[days_ago], sale)
        end
    end
end

-- Outlier -------------------------------------------------------------------
-- Looking at the full span of data, is any individual data point so far out
-- of the usual that it's not worth counting?
-- Master Merchant uses "more than 3 standard deviations from the mean" and
-- so shall we.
Outlier = {
  mean   = 0
, stddev = 0
}
function Outlier:New(l)
    local o = { mean   = 0
              , stddev = 0
              }
    setmetatable(o, self)
    self.__index = self
    o.mean   = Mean(l)
    o.stddev = StandardDeviation(l)
    return o
end

function Outlier:IsOutlier(sale)
    return 3 * self.stddev < math.abs(self.mean - sale:Mean())
end

function less_ts(a, b)
    return a.ts < b.ts
end

-- Average one list of Sale records
--
-- 1. Ignore outliers.
--    "outlier" is controlled by Outlier:IsOutlier()
--    and currently "more than 3 standard deviations out"
--
-- 2. Weight more recent days higher than older days.
--
-- This outlier control and weighting still does not match Master Merchant.
-- Not sure why not. Grr.
--
function History:Average(days_ago)
    local l         = self[days_ago]
    local acc       = Sale:New(0, 0)
    local outlier   = Outlier:New(l)

                        -- Outlier detection requires that sales records be
                        -- sorted by time. We cannot rely on our MM reader to
                        -- leave sales sorted by time: some records are split
                        -- across files and the files might be read out of
                        -- order. sort() by timestamp, ascending.
    table.sort(l, less_ts)

    for _, sale in ipairs(l) do
        local sale_mean = sale:Mean()
        if outlier:IsOutlier(sale) then
            -- ignore outlier
            -- d("Ignoring outlier: "..self.name.." "..tostring(sale_mean)
            --         .. "  mean="..tostring(outlier.mean)
            --         .. "  stddev="..tostring(outlier.stddev)
            --         )
        else
            weight = days_ago - sale:DaysAgo()
            acc:AddWeighted(sale, weight)
        end
    end
    return acc:Mean()
end

-- Return a simple mean average of all values in history.
function Mean(l)
    local acc = Sale:New(0, 0)
    for _, sale in ipairs(l) do
        acc:Add(sale)
    end
    return acc:Mean()
end

function StandardDeviation(l)
    local std       = 0
    local sample_ct = 0
    local mean      = Mean(l)
    for _, sale in ipairs(l) do
        local offset = (sale:Mean() - mean)^2
        std       = std       + offset * sale.ct
        sample_ct = sample_ct +          sale.ct
    end
    return math.sqrt(std / sample_ct)
end

-- Return earliest timestamp for N days ago. Any timestamp smaller than this is unworthy.
function Cutoff(days_ago)
    return NOW - SEC_PER_DAY*days_ago
end

function init_cutoffs()
    local r = {}
    for _, days_ago in ipairs(DAYS_AGO) do
        r[days_ago] = Cutoff(days_ago)
    end
    return r
end

-- THIS IS INCORRECT
-- Item links are significant only to the second number. After that is noise
-- that can sometimes vary (Rejera did) and cause us to miss sale records.
--
function link_strip(link)
    -- Find the 4th colon

    delim = ':'
    local delim_index = 0
    local end_index   = 0
    for i = 1,4 do
        end_index = string.find(link, delim, delim_index + 1)
        if end_index == nil then
            break
        end
        delim_index = end_index
    end
                        -- 4, not 0, to skip over "H0" which can be "H1" or
                        -- some other number. Doesn't matter. Same item.
    return string.sub(link, 4, end_index)
end

-- Return the first number in the colon-delimited sequence
-- |H1:item:30160:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
-- item ID :-----:
function to_item_id(link)
    return tonumber(string.match(link, '|H.-:item:(.-):'))
end

-- Return a colon-separated list of numbers that MM uses to identify
-- level, traits, and other significant differentiators when grouping
-- item sales.
--
-- This CANNOT be done offline, as MM depends on ESO API calls to extract
-- level and other traits. Nobody has reverse-engineered those API calls
-- well enough to reliably replace them.
--   So instead of unreliably replacing ESO API calls, we scan MM data until
-- we find an EXACT match of the link, and then use whatever MM itemIndex goes
-- with that link.
--
-- O(n) scan for n rows with the same itemID. Usually n < 100.
function to_item_index(link)
    item_id = to_item_id(link)
    if not MMDATA[item_id] then
        d("NOT FOUND: itemID="..item_id)
        return nil
    end

    link_stripped = link_strip_x(link)
    for item_index, v in pairs(MMDATA[item_id]) do
        if v["sales"] then
            for i, s in ipairs(v["sales"]) do
                if link_strip_x(s["itemLink"]) == link_stripped then
                    return item_index
                end
            end
        end
    end

    d("NOT FOUND: link="..link)
end

-- Remove the parts of a link that can vary without affecting MM itemID or itemIndex
--
-- Strips "|H0:item:" prefix and "|h|h" suffix
function link_strip_x(link)
    return string.match(link, '|H.-:item:(.+)|h')
end


-- ===========================================================================
-- Reading MM data
-- ===========================================================================

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

-- Read all MM SavedVariables files, merge all of their SalesData into a giant in-memory table.
function read_all_mm_files()
    local mm_all = {}
    for i = 0,20 do
        local in_file_path = "../../SavedVariables/MM"
                             .. string.format("%02d",i)
                             .. "Data.lua"
        local var_name = "MM" .. string.format("%02d",i)
                         .. "DataSavedVariables"
        local mm_sales_data = read_input_file(in_file_path, var_name)
        if mm_sales_data then
            for item_id, v in pairs(mm_sales_data) do
                if not mm_all[item_id] then
                    mm_all[item_id] = v
                else
                    --d("MERGING itemId="..item_id)
                    for item_index, vv in pairs(v) do
                        if not mm_all[item_id][item_index] then
                            mm_all[item_id][item_index] = vv
                        else
                            --d("MERGING itemId="..item_id.." itemIndex="..item_index)
                            for si, s in ipairs(vv["sales"]) do
                                table.insert(mm_all[item_id][item_index]["sales"], s)
                            end
                        end
                    end
                end
            end
        end
    end
    return mm_all
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
    print(line)
end


-- ignore "nil" as empty string
function b(table,key)
    if table[key] == nil then return "" end
    return tostring(table[key])
end

-- Convert "1456709816" to "2016-02-28" ISO 8601 formatted date
function iso_date(secs_since_1970)
    t = os.date("*t", secs_since_1970)
    return string.format("%04d-%02d-%02d"
                        , t.year
                        , t.month
                        , t.day
                        )
end

function d(s)
    print(s)
end

-- main ----------------------------------------------------------------------

CUTOFFS = init_cutoffs()
MMDATA  = read_all_mm_files()

