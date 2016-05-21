.PHONY: extractor matprices

extractor:
	lua MMExtractor.lua

matprices:
	lua MMMatPrices.lua
