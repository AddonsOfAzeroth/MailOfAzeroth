-- Mail of Azeroth by DinX: settings. One page, built with the same calls
-- (Header, Note, Check, Choice, Button) inside the Casters of Azeroth window
-- when that is loaded, else in Blizzard's own settings (AddOns tab).
local _, ns = ...
local MoA = ns.MoA
local L = MoA.L
local S = MoA.Style

local C = MoA:NewModule("Config")

local function cat(key)
	return function() return MoA.db.categories[key] end, function(v) MoA.db.categories[key] = v MoA:Fire("ALTS") end
end

local function confirm(key, text, onYes)
	StaticPopupDialogs[key] = StaticPopupDialogs[key] or { button1 = YES, button2 = NO, timeout = 0,
		whileDead = true, hideOnEscape = true, preferredIndex = 3 }
	StaticPopupDialogs[key].text = text
	StaticPopupDialogs[key].OnAccept = onYes
	StaticPopup_Show(key)
end

local function altList()
	local lines = {}
	for key, a in pairs(MoA.db.alts) do
		local _, why = MoA.Alts:CanReach(key, a)
		local note = (why == "realm" and L["other realm"]) or (why == "faction" and L["other faction"]) or (why == "self" and L["you"]) or nil
		lines[#lines + 1] = key .. (a.bank and ("  |cffffd040(" .. L["bank alt"] .. ")|r") or "")
			.. (note and ("  |cff999999(" .. note .. ")|r") or "") .. "\n   " .. MoA.Alts:ProfessionText(a)
	end
	table.sort(lines)
	return #lines > 0 and table.concat(lines, "\n") or L["No characters yet: log in each of them once."]
end

function C.Build(p)
	p:Header("Mail of Azeroth")
	p:Note(L["At a mailbox a panel shows which reagents can go to which of your characters. Attach, then Send: every mail takes your two clicks, nothing is sent by itself."])
	p:Check(L["Reagents to the character with the matching profession"], L["The highest skill wins. What you use yourself stays with you."], cat("profession"))
	p:Check(L["Trade goods nobody needs to your bank alt"], nil, cat("bank"))
	p:Check(L["Show the panel at the mailbox"], L["Also with the minimap button."], function() return MoA.db.showPanel end,
		function(v) MoA.db.showPanel = v and true or false MoA.Mailbox:PaintMinimap() end)
	p:Check(L["Minimap button"], L["Takes effect after /reload."], function() return not MoA.db.minimap.hide end,
		function(v) MoA.db.minimap.hide = not v end)
	p:Check(L["This character is my bank alt"], nil, function()
		local a = MoA.db.alts[MoA.Me()]
		return a and a.bank
	end, function(v)
		local a = MoA.db.alts[MoA.Me()]
		if a then a.bank = v and true or nil MoA:Fire("ALTS") end
	end)
	p:Gap()
	p:Header(L["Your characters"])
	p:Note(altList())
	p:Gap()
	p:Choice(L["Language"], { { "auto", L["Automatic"] }, { "enUS", "English" }, { "nlNL", "Nederlands" } },
		function() return MoA.db.language end, function(v) MoA.db.language = v end)
	p:Gap()
	p:Button(L["Forget my item rules"], function()
		confirm("MAILOFAZEROTH_RULES", L["Forget all items you chose to keep or send somewhere?"], function()
			wipe(MoA.db.rules)
			MoA:Fire("ALTS")
			MoA:Print(L["Item rules forgotten."])
		end)
	end, 180)
end

---------------------------------------------------------------------------
-- Standalone: a small page with the same calls, in Blizzard's settings
---------------------------------------------------------------------------
local Page = {}
Page.__index = Page

function Page:Header(text)
	local t = S:Font(self.frame, 14)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetText(text)
	t:SetTextColor(unpack(S.colors.accent))
	self.y = self.y - 26
end

function Page:Note(text)
	local t = S:Font(self.frame, 11)
	t:SetPoint("TOPLEFT", 16, self.y)
	t:SetWidth(520)
	t:SetJustifyH("LEFT")
	t:SetTextColor(unpack(S.colors.muted))
	t:SetText(text)
	self.y = self.y - math.max(18, t:GetStringHeight() + 8)
end

function Page:Gap(h) self.y = self.y - (h or 8) end

function Page:Check(label, tip, get, set)
	local b = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
	b:SetPoint("TOPLEFT", 12, self.y)
	b:SetChecked(get() and true or false)
	b:SetScript("OnClick", function(btn) set(btn:GetChecked() and true or false) end)
	local t = S:Font(self.frame, 12)
	t:SetPoint("LEFT", b, "RIGHT", 4, 0)
	t:SetText(label)
	if tip then
		b:SetScript("OnEnter", function(btn)
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			GameTooltip:SetText(tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	self.y = self.y - 28
end

-- a button that steps through the options
function Page:Choice(label, opts, get, set)
	local t = S:Font(self.frame, 12)
	t:SetPoint("TOPLEFT", 16, self.y - 4)
	t:SetText(label)
	local b
	local function paint()
		local cur = get()
		for _, o in ipairs(opts) do if o[1] == cur then b.text:SetText(o[2] .. "  >") end end
	end
	b = self:Button("", function()
		local cur, i = get(), 1
		for k, o in ipairs(opts) do if o[1] == cur then i = k end end
		set(opts[i % #opts + 1][1])
		paint()
	end, 160, 180)
	paint()
end

function Page:Button(label, onClick, width, x)
	local b = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
	b:SetSize(width or 160, 22)
	b:SetPoint("TOPLEFT", x or 16, self.y)
	S:Backdrop(b, 1)
	b.text = S:Font(b, 12)
	b.text:SetPoint("CENTER")
	b.text:SetText(label)
	b:SetScript("OnEnter", function() b:SetBackdropBorderColor(unpack(S.colors.accent)) end)
	b:SetScript("OnLeave", function() b:SetBackdropBorderColor(0, 0, 0, 1) end)
	b:SetScript("OnClick", onClick)
	self.y = self.y - 30
	return b
end

local category
local function standalone()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")
	panel:Hide()
	local page = setmetatable({ frame = panel, y = -16 }, Page)
	C.Build(page)
	category = Settings.RegisterCanvasLayoutCategory(panel, "Mail of Azeroth")
	Settings.RegisterAddOnCategory(category)
end

function MoA:ToggleConfig()
	local c = MoA:Casters()
	if c and c.ToggleConfig and type(c.Config) == "table" and c.Config.Show then
		pcall(c.ToggleConfig, c, true)
		if c.Config.pages and c.Config.pages.moa then pcall(c.Config.Show, c.Config, "moa") end
		return
	end
	if category and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID()) end
end

-- pages are built when they are first shown, after the alts are known
function C:OnEnable()
	local c = MoA:Casters()
	if c then
		c.configPages = type(c.configPages) == "table" and c.configPages or {}
		for _, d in ipairs(c.configPages) do if d.key == "moa" then return end end
		table.insert(c.configPages, { key = "moa", label = L["Mail"], group = "Mail of Azeroth", build = C.Build })
	else
		standalone()
	end
end
