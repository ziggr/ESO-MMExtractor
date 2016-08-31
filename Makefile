.PHONY: extractor matprices

matprices:
	lua MMMatPrices.lua
	pbcopy < MMMatPrices.txt
	echo "Paste into Google Sheets MMImport tab."

extractor:
	lua MMExtractor.lua

