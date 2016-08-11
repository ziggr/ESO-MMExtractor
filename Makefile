.PHONY: extractor matprices

matprices:
	lua MMMatPrices.lua

extractor:
	lua MMExtractor.lua

