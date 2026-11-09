-- Mail of Azeroth by DinX: who gets what. A reagent goes to your character
-- with the matching profession (the highest skill wins), unless you have that
-- profession yourself. Trade goods nobody needs go to your bank alt. Your
-- own rules per item ("always to ...", "keep") come first.
local _, ns = ...
local MoA = ns.MoA
local Safe = MoA.Safe

local R = MoA:NewModule("Rules")

local TRADE_GOODS, QUEST = 7, 12
-- trade goods subclass -> professions that use it
local P = MoA.Alts.PROF
local USES = {
	[1] = { P.ENGINEERING },                                  -- parts
	[4] = { P.JEWELCRAFTING },                                -- jewelcrafting
	[5] = { P.TAILORING, P.FIRST_AID },                       -- cloth
	[6] = { P.LEATHERWORKING },                               -- leather
	[7] = { P.BLACKSMITHING, P.ENGINEERING, P.JEWELCRAFTING }, -- metal and stone
	[8] = { P.COOKING },                                      -- meat and other cooking
	[9] = { P.ALCHEMY, P.INSCRIPTION },                       -- herbs
	[12] = { P.ENCHANTING },                                  -- enchanting
	[16] = { P.INSCRIPTION },                                 -- inscription
}
R.USES = USES

local function info(itemID)
	if C_Item and C_Item.GetItemInfoInstant then
		local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
		return classID, subclassID
	end
	if GetItemInfoInstant then
		local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
		return classID, subclassID
	end
end

local function bestFor(lines, alts)
	local best, bestRank
	for key, a in pairs(alts) do
		for _, line in ipairs(lines) do
			local rank = a.profs and a.profs[line]
			if rank and (not bestRank or rank > bestRank) then best, bestRank = key, rank end
		end
	end
	return best
end

-- the character this item should go to, or nil (keep it)
function R:Target(itemID, alts, mine)
	local rule = MoA.db.rules[itemID]
	if rule == "keep" then return end
	if rule and alts[rule] then return rule, "rule" end
	local classID, sub = info(itemID)
	if classID == QUEST or classID ~= TRADE_GOODS then return end
	local cats = MoA.db.categories
	local lines = USES[sub]
	if lines and cats.profession then
		-- you use it yourself: keep it
		for _, line in ipairs(lines) do if mine.profs and mine.profs[line] then return end end
		local key = bestFor(lines, alts)
		if key then return key, "profession" end
	end
	if cats.bank then
		for key, a in pairs(alts) do if a.bank then return key, "bank" end end
	end
end

-- which of your characters (or you) uses this item for a profession, or nil.
-- Casters of Azeroth asks this before selling an item you marked as junk.
function R:WhoUses(itemID)
	local classID, sub = info(itemID)
	local lines = classID == TRADE_GOODS and USES[sub]
	if not lines then return end
	local me = MoA.Me()
	local mine = MoA.db.alts[me]
	for _, line in ipairs(lines) do
		if mine and mine.profs and mine.profs[line] then return me end
	end
	return bestFor(lines, MoA.Alts:Reachable())
end

local BAGS = { 0, 1, 2, 3, 4, 5 }

-- what to send from your bags now: { [key] = { items = { {bag, slot, id, count, icon} }, stacks = n } }
function R:Plan()
	local plan = {}
	local me = MoA.Me()
	local mine = MoA.db.alts[me] or {}
	local alts = MoA.Alts:Reachable()
	if not next(alts) or not (C_Container and C_Container.GetContainerNumSlots) then return plan end
	for _, bag in ipairs(BAGS) do
		local n = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, n do
			local it = C_Container.GetContainerItemInfo(bag, slot)
			local id = it and Safe(it.itemID, nil)
			if id and not Safe(it.isBound, false) then
				local key, why = self:Target(id, alts, mine)
				if key then
					local p = plan[key] or { items = {}, stacks = 0 }
					p.items[#p.items + 1] = { bag = bag, slot = slot, id = id, count = Safe(it.stackCount, 1) or 1,
						icon = it.iconFileID, why = why }
					p.stacks = p.stacks + 1
					plan[key] = p
				end
			end
		end
	end
	return plan
end
