-- Mail of Azeroth by DinX: the panel next to the mailbox. One row per
-- character with what it gets; its button takes two clicks per mail: the first
-- attaches up to 12 stacks and fills in the name, the second sends. Nothing
-- happens without your click. Right-click an item: keep it from now on.
local _, ns = ...
local MoA = ns.MoA
local L = MoA.L
local S = MoA.Style

local M = MoA:NewModule("Mailbox")

local W, ROW_H, PAD, MAX_ROWS, ICONS = 300, 44, 8, 6, 8
local MAX_ATTACH = ATTACHMENTS_MAX_SEND or 12

local plan, order = {}, {}
local pending -- { key = "Name-Realm", name = "Name" } once attached, until sent

local function sendFrameOpen()
	return SendMailFrame and SendMailFrame:IsShown()
end

local function attachedCount()
	local n = 0
	if not GetSendMailItem then return 0 end
	for i = 1, MAX_ATTACH do
		if GetSendMailItem(i) then n = n + 1 end
	end
	return n
end

-- first click: attach the stacks for this character and fill in its name
local function attach(key)
	local p = plan[key]
	if not p or InCombatLockdown() then return end
	if not sendFrameOpen() and MailFrameTab2 then MailFrameTab2:Click() end
	if not sendFrameOpen() then return end
	if attachedCount() > 0 then
		MoA:Print(L["There are already items attached. Send or clear them first."])
		return
	end
	local slot = 0
	for _, it in ipairs(p.items) do
		if slot >= MAX_ATTACH then break end
		slot = slot + 1
		C_Container.PickupContainerItem(it.bag, it.slot)
		ClickSendMailItemButton(slot)
		if CursorHasItem and CursorHasItem() then ClearCursor() end
	end
	local name = MoA.Alts.MailName(key)
	if SendMailNameEditBox then SendMailNameEditBox:SetText(name) end
	if SendMailSubjectEditBox then SendMailSubjectEditBox:SetText(L["Reagents"]) end
	pending = { key = key, name = name }
	M:Render()
end

-- second click: send what is attached
local function send()
	if not pending or InCombatLockdown() then return end
	if attachedCount() == 0 then pending = nil M:Render() return end
	SendMail(pending.name, (SendMailSubjectEditBox and SendMailSubjectEditBox:GetText()) or L["Reagents"], "")
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------
local function itemIcon(parent)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(18, 18)
	b.tex = b:CreateTexture(nil, "ARTWORK")
	b.tex:SetAllPoints()
	b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.count = S:Font(b, 9)
	b.count:SetPoint("BOTTOMRIGHT", 1, -1)
	b:RegisterForClicks("RightButtonUp")
	b:SetScript("OnEnter", function(self)
		if not self.id then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(self.id)
		GameTooltip:AddLine(L["Right-click: keep this item from now on."], 0.6, 0.65, 0.71, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:SetScript("OnClick", function(self)
		if not self.id then return end
		MoA.db.rules[self.id] = "keep"
		MoA:Print(L["Kept from now on: %s. Change it in /moa."]:format((C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(self.id)) or self.id))
		M:Refresh()
	end)
	return b
end

function M:Build()
	local f = CreateFrame("Frame", "MailOfAzerothPanel", UIParent, "BackdropTemplate")
	S:Backdrop(f, 0.95)
	f:SetWidth(W)
	f:SetFrameStrata("HIGH")
	f:Hide()
	local title = S:Font(f, 13)
	title:SetPoint("TOPLEFT", PAD, -7)
	title:SetText("Mail of Azeroth")
	title:SetTextColor(unpack(S.colors.accent))
	f.note = S:Font(f, 10)
	f.note:SetPoint("TOPLEFT", PAD, -24)
	f.note:SetWidth(W - PAD * 2)
	f.note:SetJustifyH("LEFT")
	f.note:SetTextColor(unpack(S.colors.muted))
	f.rows = {}
	for i = 1, MAX_ROWS do
		local r = CreateFrame("Frame", nil, f)
		r:SetSize(W - PAD * 2, ROW_H)
		r:SetPoint("TOPLEFT", PAD, -40 - (i - 1) * (ROW_H + 2))
		r.name = S:Font(r, 12)
		r.name:SetPoint("TOPLEFT", 0, -2)
		r.why = S:Font(r, 10)
		r.why:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
		r.why:SetTextColor(unpack(S.colors.muted))
		r.icons = {}
		for k = 1, ICONS do
			local ic = itemIcon(r)
			ic:SetPoint("BOTTOMLEFT", (k - 1) * 20, 2)
			r.icons[k] = ic
		end
		r.more = S:Font(r, 10)
		r.more:SetPoint("BOTTOMLEFT", ICONS * 20 + 2, 6)
		r.more:SetTextColor(unpack(S.colors.muted))
		r.btn = CreateFrame("Button", nil, r, "BackdropTemplate")
		r.btn:SetSize(84, 22)
		r.btn:SetPoint("RIGHT", 0, -4)
		S:Backdrop(r.btn, 1)
		r.btn.text = S:Font(r.btn, 11)
		r.btn.text:SetPoint("CENTER")
		r.btn:SetScript("OnEnter", function(b) b:SetBackdropBorderColor(unpack(S.colors.accent)) end)
		r.btn:SetScript("OnLeave", function(b) b:SetBackdropBorderColor(0, 0, 0, 1) end)
		r.btn:SetScript("OnClick", function(b)
			if pending and pending.key == b.key then send() else attach(b.key) end
		end)
		r:Hide()
		f.rows[i] = r
	end
	self.frame = f
end

local WHY = { profession = "uses it", bank = "bank alt", rule = "your rule" }

function M:Render()
	local f = self.frame
	if not f then return end
	local n = 0
	for i, key in ipairs(order) do
		local r = f.rows[i]
		if not r then break end
		local p = plan[key]
		n = i
		r.name:SetText(MoA.Alts.MailName(key))
		local why = p.items[1] and WHY[p.items[1].why]
		r.why:SetText(why and L[why] or "")
		for k, ic in ipairs(r.icons) do
			local it = p.items[k]
			if it then
				ic.id = it.id
				ic.tex:SetTexture(it.icon)
				ic.count:SetText(it.count > 1 and it.count or "")
				ic:Show()
			else
				ic.id = nil
				ic:Hide()
			end
		end
		r.more:SetText(#p.items > ICONS and ("+" .. (#p.items - ICONS)) or "")
		local isPending = pending and pending.key == key
		r.btn.key = key
		r.btn.text:SetText(isPending and L["Send"] or L["Attach"])
		r.btn.text:SetTextColor(unpack(isPending and S.colors.accent or S.colors.text))
		r:Show()
	end
	for i = n + 1, MAX_ROWS do f.rows[i]:Hide() end
	if n == 0 then
		f.note:SetText(next(MoA.Alts:Reachable()) and L["Nothing to send."]
			or L["Log in your other characters once, so Mail of Azeroth knows their professions."])
	else
		f.note:SetText(L["Attach, then Send: one mail per two clicks."])
	end
	f:SetHeight(n == 0 and 48 or (40 + n * (ROW_H + 2) + PAD))
	f:ClearAllPoints()
	if MailFrame then f:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, 0) else f:SetPoint("CENTER") end
end

function M:Refresh()
	if not (self.frame and self.frame:IsShown()) then return end
	plan = MoA.Rules:Plan()
	wipe(order)
	for key in pairs(plan) do order[#order + 1] = key end
	table.sort(order)
	if pending and not plan[pending.key] and attachedCount() == 0 then pending = nil end
	self:Render()
end

function M:OnEnable()
	self:Build()
	MoA:On("MAIL_SHOW", function()
		pending = nil
		M.frame:Show()
		M:Refresh()
	end)
	MoA:On("MAIL_CLOSED", function()
		pending = nil
		M.frame:Hide()
	end)
	MoA:On("MAIL_SEND_SUCCESS", function()
		pending = nil
		C_Timer.After(0.3, function() M:Refresh() end)
	end)
	MoA:On("BAG_UPDATE_DELAYED", function() if not pending then M:Refresh() end end)
	MoA:Listen("ALTS", function() M:Refresh() end)
end
