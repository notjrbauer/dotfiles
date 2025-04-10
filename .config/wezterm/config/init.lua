local wezterm = require('wezterm')

---@class Config
---@field options table
local Config = {}
Config.__index = Config

---Initialize Config
---@return Config
function Config:init()
  return setmetatable({ options = {} }, self)
end

---Append to `Config.options`
---@param new_options table new options to append
---@return Config
function Config:append(new_options)
  for k, v in pairs(new_options) do
    if self.options[k] ~= nil then
      wezterm.log_warn(
        string.format("Duplicate config option detected for key '%s': old = %s, new = %s", k, tostring(self.options[k]), tostring(v))
      )
      goto continue
    end
    self.options[k] = v
    ::continue::
  end
  return self
end

return Config
