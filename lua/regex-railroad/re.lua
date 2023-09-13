local success, _ = pcall(require, "lpeg")
local re = success and require("re") or require("lulpeg").re

return re
