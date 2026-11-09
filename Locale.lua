-- Mail of Azeroth by DinX: translations. Code uses English strings as keys: L["Text"].
local _, ns = ...
local MoA = ns.MoA

local NL = {}
MoA.translations = { nlNL = NL }

-- Looked up at use time, so the saved language (loaded later) applies.
MoA.L = setmetatable({}, {
	__index = function(_, key)
		local lang = MoA.db and MoA.db.language or "auto"
		if lang == "auto" then -- follow Casters of Azeroth, else the client
			local c = MoA.Casters and MoA:Casters()
			lang = (c and c.db and c.db.language ~= "auto" and c.db.language) or (GetLocale() == "nlNL" and "nlNL") or "enUS"
		end
		local t = MoA.translations[lang]
		return t and t[key] or key
	end,
})

for k, v in pairs({
	-- slash
	["This character is now your bank alt."] = "Dit karakter is nu je bank-alt.",
	["This character is no longer your bank alt."] = "Dit karakter is niet langer je bank-alt.",
	["bank alt"] = "bank-alt",
	["/moa: settings. /moa bank: this character is (not) your bank alt. /moa alts: your characters."] = "/moa: instellingen. /moa bank: dit karakter is (niet) je bank-alt. /moa alts: je karakters.",
	["no professions"] = "geen beroepen",
	-- mailbox
	["There are already items attached. Send or clear them first."] = "Er zijn al items bijgevoegd. Verstuur of verwijder ze eerst.",
	["Reagents"] = "Reagents",
	["Right-click: keep this item from now on."] = "Rechtsklik: dit item voortaan houden.",
	["Kept from now on: %s. Change it in /moa."] = "Voortaan gehouden: %s. Aanpassen in /moa.",
	["uses it"] = "gebruikt het",
	["your rule"] = "jouw regel",
	["Send"] = "Versturen",
	["Attach"] = "Bijvoegen",
	["Nothing to send."] = "Niets te versturen.",
	["Your other characters are on another realm or faction: mail can't reach them from here."] = "Je andere karakters staan op een andere realm of factie: mail kan hen van hieruit niet bereiken.",
	["other realm"] = "andere realm",
	["other faction"] = "andere factie",
	["you"] = "jij",
	["Log in your other characters once, so Mail of Azeroth knows their professions."] = "Log je andere karakters één keer in, zodat Mail of Azeroth hun beroepen kent.",
	["Attach, then Send: one mail per two clicks."] = "Bijvoegen, dan Versturen: één mail per twee klikken.",
	-- settings
	["Mail"] = "Mail",
	["At a mailbox a panel shows which reagents can go to which of your characters. Attach, then Send: every mail takes your two clicks, nothing is sent by itself."] = "Bij een mailbox toont een paneel welke reagents naar welk karakter kunnen. Bijvoegen, dan Versturen: elke mail kost twee klikken van jou, niets wordt vanzelf verstuurd.",
	["Reagents to the character with the matching profession"] = "Reagents naar het karakter met het passende beroep",
	["The highest skill wins. What you use yourself stays with you."] = "De hoogste skill wint. Wat je zelf gebruikt, blijft bij jou.",
	["Trade goods nobody needs to your bank alt"] = "Trade goods die niemand nodig heeft naar je bank-alt",
	["This character is my bank alt"] = "Dit karakter is mijn bank-alt",
	["Your characters"] = "Je karakters",
	["No characters yet: log in each of them once."] = "Nog geen karakters: log ze elk één keer in.",
	["Language"] = "Taal",
	["Automatic"] = "Automatisch",
	["Forget my item rules"] = "Mijn item-regels vergeten",
	["Forget all items you chose to keep or send somewhere?"] = "Alle items vergeten die je wilde houden of ergens naartoe sturen?",
	["Item rules forgotten."] = "Item-regels vergeten.",
	["Frames locked."] = "Kaders vergrendeld.",
	["Hide until the next mailbox. The minimap button turns the panel off for good."] = "Verbergen tot de volgende mailbox. Met de minimapknop zet je het paneel helemaal uit.",
	["The mail panel shows at the mailbox."] = "Het mailpaneel verschijnt bij de mailbox.",
	["The mail panel is off. Click the minimap button to turn it on."] = "Het mailpaneel staat uit. Klik op de minimapknop om het aan te zetten.",
	["Panel at the mailbox: on"] = "Paneel bij de mailbox: aan",
	["Panel at the mailbox: off"] = "Paneel bij de mailbox: uit",
	["Click: panel on/off"] = "Klik: paneel aan/uit",
	["Right-click: settings"] = "Rechtsklik: instellingen",
	["Show the panel at the mailbox"] = "Het paneel tonen bij de mailbox",
	["Also with the minimap button."] = "Ook met de minimapknop.",
	["Minimap button"] = "Minimapknop",
	["Takes effect after /reload."] = "Werkt na /reload.",
}) do NL[k] = v end
