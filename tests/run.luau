-- Runs every test file: lune run tests/run  (from the repo root)
local process = require("@lune/process")

local failed = 0
failed += require("./kit")
print("")
failed += require("./plugin")
print("")
failed += require("./smoke")
process.exit(if failed > 0 then 1 else 0)
