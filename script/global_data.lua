
---@class NetworkData
---@field icon? SpritePath
---@field tip? string 

---@class CombinatorData
---@field provider boolean
---@field requester boolean
---@field ltn-provider-threshold number?
---@field ltn-provider-stack_threshold number?
---@field ltn-requester-threshold number?
---@field ltn-requester-stack-threshold number?

---@class Replacement
---@field combinator_data CombinatorData
---@field no_auto_disable boolean
---@field pos MapPosition
---@field tick uint
---@field name string

local global_data = {}

function global_data.init()
  ---@type PlayerTable[]
  global.players = {}
  ---@type NetworkData[]
  global.network_descriptions = {}
  ---@type CombinatorData[]
  global.combinators = {}
  ---@type Replacement[][]
  global.replacements = {}
end

return global_data