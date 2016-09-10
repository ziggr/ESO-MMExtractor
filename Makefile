.PHONY: extractor matprices

matprices:
	lua MMMatPrices.lua
	pbcopy < MMMatPrices.txt
	echo "Paste into Google Sheets MMImport tab."

extractor:
	lua MMExtractor.lua

mm:
	lua mm.lua "|H1:item:30158:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" "|H1:item:30164:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" "|H1:item:30160:31:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"

