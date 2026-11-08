-- Mail of Azeroth by DinX: your characters. Each one is remembered when you
-- log it in: class, faction, realm, level and its professions (skill lines).
local _, ns = ...
local MoA = ns.MoA
local L = MoA.L
local Safe = MoA.Safe

local A = MoA:NewModule("Alts")

-- skill line IDs (the same on every client language)
A.PROF = {
	ALCHEMY = 171, BLACKSMITHING = 164, ENCHANTING = 333, ENGINEERING = 202, HERBALISM = 182,
	LEATHERWORKING = 165, MINING = 186, SKINNING = 393, TAILORING = 197, JEWELCRAFTING = 755,
	INSCRIPTION = 773, COOKING = 185, FIRST_AID = 129, FISHING = 356,
}
-- for clients without GetProfessions: English skill names to skill lines
local BY_NAME = {
	Alchemy = 171, Blacksmithing = 164, Enchanting = 333, Engineering = 202, Herbalism = 182,
	Leatherworking = 165, Mining = 186, Skinning = 393, Tailoring = 197, Jewelcrafting = 755,
	Inscription = 773, Cooking = 185, ["First Aid"] = 129, Fishing = 356,
}
local NAMES = {}
for name, id in pairs(BY_NAME) do NAMES[id] = name end
A.Names = NAMES

-- { [skillLine] = rank } for the character you play now
local function readProfessions()
	local out = {}
	if GetProfessions and GetProfessionInfo then
		local list = { GetProfessions() }
		for i = 1, 6 do
			local idx = list[i]
			if idx then
				local ok, name, _, rank, _, _, _, line = pcall(GetProfessionInfo, idx)
				line = ok and Safe(line, nil)
				if type(line) == "number" then out[line] = Safe(rank, 0) end
			end
		end
	end
	if not next(out) and GetNumSkillLines and GetSkillLineInfo then
		for i = 1, GetNumSkillLines() do
			local name, header, _, rank = GetSkillLineInfo(i)
			local line = not header and BY_NAME[name]
			if line then out[line] = rank or 0 end
		end
	end
	return out
end

function A:Update()
	local me, realm = MoA.Me()
	if not me then return end
	local a = MoA.db.alts[me] or {}
	a.class = select(2, UnitClass("player"))
	a.faction = UnitFactionGroup("player")
	a.realm = realm
	a.level = UnitLevel("player")
	local profs = readProfessions()
	if next(profs) then a.profs = profs end
	a.profs = a.profs or {}
	MoA.db.alts[me] = a
	MoA:Fire("ALTS")
end

-- your other characters that can get mail from this one (same realm and faction)
function A:Reachable()
	local me, realm = MoA.Me()
	local faction = UnitFactionGroup("player")
	local out = {}
	for key, a in pairs(MoA.db.alts) do
		if key ~= me and a.realm == realm and a.faction == faction then out[key] = a end
	end
	return out
end

function A:ProfessionText(a)
	local parts = {}
	for line, rank in pairs(a.profs or {}) do
		parts[#parts + 1] = (L[NAMES[line] or tostring(line)]) .. " " .. tostring(rank)
	end
	table.sort(parts)
	return #parts > 0 and table.concat(parts, ", ") or L["no professions"]
end

-- the name to type in the mail ("Name" on your own realm)
function A.MailName(key)
	local me, realm = MoA.Me()
	local name, r = key:match("^(.-)%-(.*)$")
	if name and r == realm then return name end
	return key
end

function A:OnEnable()
	self:Update()
	MoA:On("SKILL_LINES_CHANGED", function() A:Update() end)
	MoA:On("PLAYER_LEVEL_UP", function() C_Timer.After(1, function() A:Update() end) end)
	MoA:On("TRADE_SKILL_SHOW", function() A:Update() end)
end
