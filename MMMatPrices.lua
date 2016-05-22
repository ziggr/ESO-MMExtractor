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
MOST_RECENT_TS = 0

-- "name" here is what Zig uses in spreadsheets, NOT the official display name
-- from ESO data with it's goofy ^ns suffix.
MATS = {
  { "jute"                , "|H0:item:811:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"   }
, { "flax"                , "|H0:item:4463:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"  }
, { "cotton"              , "|H0:item:23125:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "spidersilk"          , "|H0:item:23126:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ebonthread"          , "|H0:item:23127:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "kresh"               , "|H0:item:46131:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ironthread"          , "|H0:item:46132:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "silverweave"         , "|H0:item:46133:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "void cloth"          , "|H0:item:46134:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ancestor silk"       , "|H0:item:64504:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "hemming"             , "|H0:item:54174:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "embroidery"          , "|H0:item:54175:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "elegant lining"      , "|H0:item:54176:33:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "dreugh wax"          , "|H0:item:54177:34:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "rawhide"             , "|H0:item:794:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "hide"                , "|H0:item:4447:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "leather"             , "|H0:item:23099:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "thick leather"       , "|H0:item:23100:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "fell hide"           , "|H0:item:23101:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "topgrain hide"       , "|H0:item:46135:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "iron hide"           , "|H0:item:46136:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "superb hide"         , "|H0:item:46137:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "shadowhide"          , "|H0:item:46138:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "rubedo leather"      , "|H0:item:64506:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "iron"                , "|H0:item:5413:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "steel"               , "|H0:item:4487:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "orichalcum"          , "|H0:item:23107:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "dwarven"             , "|H0:item:6000:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ebony"               , "|H0:item:6001:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "calcinium"           , "|H0:item:46127:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "galatite"            , "|H0:item:46128:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "quicksilver"         , "|H0:item:46129:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "voidstone"           , "|H0:item:46130:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "rubedite"            , "|H0:item:64489:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "honing stone"        , "|H0:item:54170:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "dwarven oil"         , "|H0:item:54171:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "grain solvent"       , "|H0:item:54172:33:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "tempering alloy"     , "|H0:item:54173:34:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "maple"               , "|H0:item:803:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "oak"                 , "|H0:item:533:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "beech"               , "|H0:item:23121:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "hickory"             , "|H0:item:23122:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "yew"                 , "|H0:item:23123:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "birch"               , "|H0:item:46139:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ash"                 , "|H0:item:46140:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "mahogany"            , "|H0:item:46141:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "nightwood"           , "|H0:item:46142:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ruby ash"            , "|H0:item:64502:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "pitch"               , "|H0:item:54178:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "turpen"              , "|H0:item:54179:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "mastic"              , "|H0:item:54180:33:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "rosin"               , "|H0:item:54181:34:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "adamantite"          , "|H0:item:33252:30:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:0:0|h|h" }
, { "obsidian"            , "|H0:item:33253:30:0:0:0:0:0:0:0:0:0:0:0:0:0:4:0:0:0:0:0|h|h" }
, { "bone"                , "|H0:item:33194:30:0:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:0:0|h|h" }
, { "corundum"            , "|H0:item:33256:30:0:0:0:0:0:0:0:0:0:0:0:0:0:5:0:0:0:0:0|h|h" }
, { "molybdenum"          , "|H0:item:33251:30:13:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0:0|h|h" }
, { "starmetal"           , "|H0:item:33258:30:0:0:0:0:0:0:0:0:0:0:0:0:0:2:0:0:0:0:0|h|h" }
, { "moonstone"           , "|H0:item:33255:30:50:0:0:0:0:0:0:0:0:0:0:0:0:9:0:0:0:0:0|h|h" }
, { "manganese"           , "|H0:item:33257:30:50:0:0:0:0:0:0:0:0:0:0:0:0:3:0:0:0:0:0|h|h" }
, { "flint"               , "|H0:item:33150:30:0:0:0:0:0:0:0:0:0:0:0:0:0:6:0:0:0:0:0|h|h" }
, { "nickel"              , "|H0:item:33254:30:50:0:0:0:0:0:0:0:0:0:0:0:0:34:0:0:0:0:0|h|h" }
, { "palladium"           , "|H0:item:46152:30:0:0:0:0:0:0:0:0:0:0:0:0:0:15:0:0:0:0:0|h|h" }
, { "copper"              , "|H0:item:46149:30:23:0:0:0:0:0:0:0:0:0:0:0:0:17:0:0:0:0:0|h|h" }
, { "argentum"            , "|H0:item:46150:30:16:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h" }
, { "daedra heart"        , "|H0:item:46151:30:50:0:0:0:0:0:0:0:0:0:0:0:0:20:0:0:0:0:0|h|h" }
, { "dwemer frame"        , "|H0:item:57587:30:0:0:0:0:0:0:0:0:0:0:0:0:0:14:0:0:0:0:0|h|h" }
, { "malachite"           , "|H0:item:64689:6:0:0:0:0:0:0:0:0:0:0:0:0:0:28:0:0:0:0:0|h|h" }
, { "charcoal of remorse" , "|H0:item:59922:30:0:0:0:0:0:0:0:0:0:0:0:0:0:29:0:0:0:0:0|h|h" }
, { "goldscale"           , "|H0:item:64687:30:50:0:0:0:0:0:0:0:0:0:0:0:0:33:0:0:0:0:0|h|h" }
, { "laurel"              , "|H0:item:64713:6:50:0:0:0:0:0:0:0:0:0:0:0:0:26:0:0:0:0:0|h|h" }
, { "cassiterite"         , "|H0:item:69555:30:0:0:0:0:0:0:0:0:0:0:0:0:0:22:0:0:0:0:0|h|h" }
, { "auric tusk"          , "|H0:item:71582:30:0:0:0:0:0:0:0:0:0:0:0:0:0:21:0:0:0:0:0|h|h" }
, { "potash"              , "|H0:item:71584:30:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:0:0|h|h" }
, { "rogue's soot"        , "|H0:item:71538:30:0:0:0:0:0:0:0:0:0:0:0:0:0:47:0:0:0:0:0|h|h" }
, { "eagle feather"       , "|H0:item:71738:30:0:0:0:0:0:0:0:0:0:0:0:0:0:25:0:0:0:0:0|h|h" }
, { "lion fang"           , "|H0:item:71742:30:0:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:0:0|h|h" }
, { "dragon scute"        , "|H0:item:71740:30:0:0:0:0:0:0:0:0:0:0:0:0:0:24:0:0:0:0:0|h|h" }
, { "azure plasm"         , "|H0:item:71766:30:50:0:0:0:0:0:0:0:0:0:0:0:0:30:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "quartz"              , "|H0:item:4456:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "diamond"             , "|H0:item:23219:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "sardonyx"            , "|H0:item:30221:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "almandine"           , "|H0:item:23221:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "emerald"             , "|H0:item:4442:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "bloodstone"          , "|H0:item:30219:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "garnet"              , "|H0:item:23171:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "sapphire"            , "|H0:item:23173:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "fortified nirncrux"  , "|H0:item:56862:30:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "chysolite"           , "|H0:item:23203:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "amethyst"            , "|H0:item:23204:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "ruby"                , "|H0:item:4486:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "jade"                , "|H0:item:810:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "turquoise"           , "|H0:item:813:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "carnelian"           , "|H0:item:23165:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "fire opal"           , "|H0:item:23149:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "citrine"             , "|H0:item:16291:30:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "potent nirncrux"     , "|H0:item:56863:30:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, {                                                                                       }
, { "Jora"                , "|H0:item:45855:20:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Porade"              , "|H0:item:45856:20:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jera"                , "|H0:item:45857:20:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jejora"              , "|H0:item:45806:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Odra"                , "|H0:item:45807:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Pojora"              , "|H0:item:45808:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Edora"               , "|H0:item:45809:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jaera"               , "|H0:item:45810:20:26:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Pora"                , "|H0:item:45811:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Denara"              , "|H0:item:45812:125:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rera"                , "|H0:item:45813:127:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Derado"              , "|H0:item:45814:129:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rekura"              , "|H0:item:45815:131:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kura"                , "|H0:item:45816:134:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rejera"              , "|H0:item:64509:308:39:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Repora"              , "|H0:item:68341:366:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "Jode"                , "|H0:item:45817:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Notade"              , "|H0:item:45818:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Ode"                 , "|H0:item:45819:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Tade"                , "|H0:item:45820:20:19:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jayde"               , "|H0:item:45821:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Edode"               , "|H0:item:45822:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Pojode"              , "|H0:item:45823:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rekude"              , "|H0:item:45824:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Hade"                , "|H0:item:45825:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Idode"               , "|H0:item:45826:125:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Pode"                , "|H0:item:45827:127:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kedeko"              , "|H0:item:45828:129:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rede"                , "|H0:item:45829:131:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kude"                , "|H0:item:45830:134:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jehade"              , "|H0:item:64508:308:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Itade"               , "|H0:item:68340:366:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "Dekeipa"             , "|H0:item:45839:20:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Deni"                , "|H0:item:45833:20:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Denima"              , "|H0:item:45836:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Deteri"              , "|H0:item:45842:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Haoko"               , "|H0:item:45841:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Hakeijo"             , "|H0:item:68342:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kaderi"              , "|H0:item:45849:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kuoko"               , "|H0:item:45837:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Makderi"             , "|H0:item:45848:20:26:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Makko"               , "|H0:item:45832:20:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Makkoma"             , "|H0:item:45835:20:36:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Meip"                , "|H0:item:45840:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Oko"                 , "|H0:item:45831:20:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Okoma"               , "|H0:item:45834:20:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Okori"               , "|H0:item:45843:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Oru"                 , "|H0:item:45846:20:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rakeipa"             , "|H0:item:45838:20:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Taderi"              , "|H0:item:45847:20:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "Ta"                  , "|H0:item:45850:20:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Jejota"              , "|H0:item:45851:21:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Denata"              , "|H0:item:45852:22:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Rekuta"              , "|H0:item:45853:23:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Kuta"                , "|H0:item:45854:24:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "Blessed Thistle"     , "|H0:item:30157:31:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Blue Entoloma"       , "|H0:item:30148:31:36:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Bugloss"             , "|H0:item:30160:31:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Columbine"           , "|H0:item:30164:31:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Corn Flower"         , "|H0:item:30161:31:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Dragonthorn"         , "|H0:item:30162:31:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Emetic Russula"      , "|H0:item:30151:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Imp Stool"           , "|H0:item:30156:31:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Lady's Smock"        , "|H0:item:30158:31:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Luminous Russula"    , "|H0:item:30155:31:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Mountain flower"     , "|H0:item:30163:31:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Namira's Rot"        , "|H0:item:30153:31:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Nirnroot"            , "|H0:item:30165:31:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Stinkhorn"           , "|H0:item:30149:31:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Violet Coprinus"     , "|H0:item:30152:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Water Hyacinth"      , "|H0:item:30166:31:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "White Cap"           , "|H0:item:30154:31:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Wormwood"            , "|H0:item:30159:31:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, {                                                                                       }
, { "Natural Water"       , "|H0:item:883:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Clear Water"         , "|H0:item:1187:30:17:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Pristine Water"      , "|H0:item:4570:30:24:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Cleansed Water"      , "|H0:item:23265:30:13:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Filtered Water"      , "|H0:item:23266:30:48:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Purified Water"      , "|H0:item:23267:125:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Cloud Mist"          , "|H0:item:23268:129:46:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Star Dew"            , "|H0:item:64500:134:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }
, { "Lorkhan's Tears"     , "|H0:item:64501:308:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" }


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
--
-- Does NOT know how to ignore outliers. Could add that if I cared that much.
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
        if link  and link ~= "" then
            -- d("name: " .. tostring(name) .. "  link: " .. tostring(link))
            r[link] = History:New(name, link)
        end
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
                    if MOST_RECENT_TS < mm_sale.timestamp then
                        MOST_RECENT_TS = mm_sale.timestamp
                    end
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
        local l       = { name, link }
        if link and link ~= "" then
            local history = HISTORY[link]
            for _, days_ago in ipairs(DAYS_AGO) do
                local avg = history:Average(days_ago)
                table.insert(l, string.format("%d", avg))
            end
            write_list(l)
        else
            write_list(l)
        end
    end
end

function write_header()
    local l = { "# name", "link" }
    for _, days_ago in ipairs(DAYS_AGO) do
        table.insert(l, tostring(days_ago) .. " day average")
    end
    table.insert(l, "# as of " .. iso_date(os.time()))
    write_list(l)
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
HISTORY = init_history()

loop_over_input_files()

write_averages()
