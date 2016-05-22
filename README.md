A few Lua scripts that know how to read [Master Merchant](http://www.esoui.com/downloads/info928-MasterMerchant.html) data.

Typically you'd clone this repo into

    Elder Scrolls Online/live/AddOns/MMExtractor/

So that the scripts can reach up and over to find Master Merchant's data:

    ../../SavedVariables/MMnnData/MMnnData.lua


## MMExtractor.lua

Extracts every sales record from Master Merchant and exports the entire database as a giant tab-delimited text file.

## MMMatPrices.lua

Export 10-day and 30-day averages for crafting materials.

