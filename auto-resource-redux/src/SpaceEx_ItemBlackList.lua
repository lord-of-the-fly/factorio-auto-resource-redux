local Storage = {}
local DomainStore = require "src.DomainStore";
local ItemPriorityManager = require "src.ItemPriorityManager"
local R = require "src.RichText"
local Util = require "src.Util"

-- Don't take filled cannon capsules because they cannot be used elsewhere
local blacklisted_item_types = {
  ["Delivery cannon capsule:"] = true
}
