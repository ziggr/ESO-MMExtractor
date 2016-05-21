IN_FILE_PATH  = "../../SavedVariables/MM00Data.lua"
OUT_FILE_PATH = "./MMExtractor.csv"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))
