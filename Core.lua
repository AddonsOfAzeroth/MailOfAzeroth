-- Mail of Azeroth by DinX: send reagents to the alt with the matching
-- profession, the rest to your bank alt. Nothing is sent by itself: at the
-- mailbox every mail takes your clicks (attach, then send).
local ADDON, ns = ...

local MoA = CreateFrame("Frame", "MailOfAzerothCore")
ns.MoA = MoA
_G.MailOfAzeroth = MoA

MoA.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or "?"
MoA.modules = {}

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------
local accountDefaults = {
	language = "auto",
	font = "roboto",
	fontOutline = false,
	alts = {},          -- ["Name-Realm"] = { class, faction, realm, level, profs = { [skillLine] = rank }, bank = bool }
	rules = {},         -- [itemID] = "Name-Realm": always send this item there (or "keep")
	showPanel = true,   -- the panel next to the mailbox (minimap button toggles it)
	minimap = { angle = 200, hide = false },
	categories = {      -- what goes out automatically (as a suggestion) per kind of reagent
		profession = true, -- to the alt with the matching profession
		bank = true,       -- trade goods nobody needs to the bank alt
	},
}

local charDefaults = {
	bars = { locked = true },
	points = {},
}

MoA.SCHEMA = 1

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			merge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

---------------------------------------------------------------------------
-- Printing, events, modules
---------------------------------------------------------------------------
function MoA:Print(...)
	print("|cff69ccf0Mail of Azeroth|r:", ...)
end

local handlers = {}
function MoA:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		local ok = pcall(self.RegisterEvent, self, event)
		if not ok then handlers[event] = nil return end
	end
	table.insert(handlers[event], fn)
end

MoA:SetScript("OnEvent", function(self, event, ...)
	local list = handlers[event]
	if list then
		for i = 1, #list do list[i](event, ...) end
	end
end)

function MoA:NewModule(name)
	local m = { name = name }
	self.modules[#self.modules + 1] = m
	self[name] = m
	return m
end

local callbacks = {}
function MoA:Listen(msg, fn)
	callbacks[msg] = callbacks[msg] or {}
	table.insert(callbacks[msg], fn)
end
function MoA:Fire(msg, ...)
	for _, fn in ipairs(callbacks[msg] or {}) do fn(...) end
end

local issecret = issecretvalue or function() return false end
MoA.IsSecret = issecret
function MoA.Safe(v, default)
	if issecret(v) then return default end
	if v == nil then return default end
	return v
end

-- this character as "Name-Realm"
function MoA.Me()
	local name, realm = UnitFullName("player")
	realm = realm or (GetNormalizedRealmName and GetNormalizedRealmName()) or GetRealmName()
	return name and (name .. "-" .. (realm or "")) or nil, realm
end

-- Casters of Azeroth when it is loaded, else nil.
function MoA:Casters()
	local c = _G.CastersOfAzeroth or _G.CasterKit
	if type(c) == "table" and type(c.char) == "table" then return c end
end

function MoA:FramesLocked()
	local c = self:Casters()
	if c and type(c.char.bars) == "table" then return c.char.bars.locked ~= false end
	return self.char.bars.locked
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
MoA:On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	MailOfAzerothDB = type(MailOfAzerothDB) == "table" and MailOfAzerothDB or {}
	MailOfAzerothCharDB = type(MailOfAzerothCharDB) == "table" and MailOfAzerothCharDB or {}
	merge(MailOfAzerothDB, accountDefaults)
	merge(MailOfAzerothCharDB, charDefaults)
	MoA.db = MailOfAzerothDB
	MoA.char = MailOfAzerothCharDB
	MoA.db.schemaVersion = MoA.SCHEMA
	local c = MoA:Casters()
	MoA.Style:LoadFont(c and c.db or MoA.db)
	for _, m in ipairs(MoA.modules) do
		if m.OnInit then pcall(m.OnInit, m) end
	end
end)

MoA:On("PLAYER_LOGIN", function()
	for _, m in ipairs(MoA.modules) do
		if m.OnEnable then
			local ok, err = pcall(m.OnEnable, m)
			if not ok then MoA:Print("|cffff5555" .. m.name .. ":|r " .. tostring(err)) end
		end
	end
end)

SLASH_MAILOFAZEROTH1 = "/moa"
SLASH_MAILOFAZEROTH2 = "/mailofazeroth"
SlashCmdList.MAILOFAZEROTH = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	local L = MoA.L
	if msg == "" or msg == "config" or msg == "settings" then
		MoA:ToggleConfig()
	elseif msg == "bank" then
		local me = MoA.Me()
		local a = MoA.db.alts[me]
		if a then
			a.bank = not a.bank
			MoA:Print(a.bank and L["This character is now your bank alt."] or L["This character is no longer your bank alt."])
			MoA:Fire("ALTS")
		end
	elseif msg == "alts" then
		for key, a in pairs(MoA.db.alts) do
			MoA:Print(key .. (a.bank and (" (" .. L["bank alt"] .. ")") or "") .. ": " .. MoA.Alts:ProfessionText(a))
		end
	else
		MoA:Print(L["/moa: settings. /moa bank: this character is (not) your bank alt. /moa alts: your characters."])
	end
end

-- Report which function Blizzard blocked (taint), so it can be fixed.
do
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_ACTION_BLOCKED")
	f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	f:SetScript("OnEvent", function(_, event, addon, func)
		if addon ~= ADDON then return end
		C_Timer.After(3, function() MoA:Print("|cffff5555blocked:|r " .. tostring(func)) end)
	end)
end
