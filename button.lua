local name, QuestItemButton = ...

BINDING_HEADER_PRMKQUESTITEMHEADER = "QuestItemButton"
_G["BINDING_NAME_CLICK PRMKQUESTITEMBUTTON1:LeftButton"] = "Quest Item Button 1"
_G["BINDING_NAME_CLICK PRMKQUESTITEMBUTTON2:LeftButton"] = "Quest Item Button 2"
_G["BINDING_NAME_CLICK PRMKQUESTITEMBUTTON3:LeftButton"] = "Quest Item Button 3"
_G["BINDING_NAME_CLICK PRMKQUESTITEMBUTTON4:LeftButton"] = "Quest Item Button 4"
_G["BINDING_NAME_CLICK PRMKQUESTITEMBUTTON5:LeftButton"] = "Quest Item Button 5"

local denylist = {
	[42233] = true, -- Highmountain
	[42234] = true, -- 
	[42422] = true,
	[48641] = true,
	[50598] = true,
	[50602] = true, -- Talajnis Expedition
	[50603] = true,
	[54180] = true,
	[56120] = true,
	[57565] = true,
	[57567] = true,
}

local function printDebugMsg(...)
	if not QuestItemButtonDB.debug then return end
	local args = {...}

	for i=1, select("#",...) do
		if type(args[i]) == "table" then
			print(table.concat(args[i], " "))
		else
			print(args[i])
		end
	end
end

local function checkIfButtonExists(frame, questLogIndex)
	local buttons = QuestItemButton.activeButtons
	local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(questLogIndex) or {GetQuestLogTitle(questLogIndex)}
	local questID = info.questID or info[8]
	
	if not buttons[questID] then
		printDebugMsg({"No button exists for", questLogIndex, questID})
		if InCombatLockdown() then
			QuestItemButton.acceptedDelayed[questID] = questLogIndex
			
			QuestItemButton:Register(frame, "PLAYER_REGEN_ENABLED")
		else
			QuestItemButton:CreateQuestItemButton(questID, questLogIndex)
		end
	end
end

local function QuestButtonTemplate()
	local num = QuestItemButton.numActiveButtons
	local button = CreateFrame("Button", "PRMKQUESTITEMBUTTON".. num, QuestItemButton.anchorFrame, "QuestItemButtonTemplate")
	button:RegisterForClicks("AnyUp")
	button:SetText(" ")
	
	return button
end

function QuestItemButton:Register(frame, event)
	if not self.registered[event] then
		frame:RegisterEvent(event)
		self.registered[event] = true
	end
end

function QuestItemButton:Unregister(frame, event)
	if self.registered[event] then
		frame:UnregisterEvent(event)
		self.registered[event] = nil
	end
end

function QuestItemButton:CreateQuestItemButtons()
	local numQuests = C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() or GetNumQuestLogEntries()
	local buttons = self.activeButtons
	for index = 1, numQuests do
		local link, texture = GetQuestLogSpecialItemInfo(index)
		local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(index) or {GetQuestLogTitle(index)}
		local questID = info.questID or info[8]
		
		if link and self.numActiveButtons < 5 then
			self.numActiveButtons = self.numActiveButtons + 1
			if QuestUtils_IsQuestWatched and not QuestUtils_IsQuestWatched(questID) then
				C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Manual)
			elseif IsQuestWatched and not IsQuestWatched(index) then
				AddQuestWatch(index)
			end
		
			local itemName = link:match("%[(.+)%]")
			local button = QuestButtonTemplate()
			button:SetAttribute("type", "item")
			button:SetAttribute("item", itemName)
			button:SetPoint("TOP", self.anchorFrame, "BOTTOM", 0, (self.numActiveButtons-1)*(-60))
			button:SetNormalTexture(texture)
			button:Show()
			
			buttons[button] = true
			buttons[questID] = button
			button.questID = questID
			button.index = self.numActiveButtons
			button.questLogIndex = index
			
			local binding = GetBindingKey("CLICK PRMKQUESTITEMBUTTON".. self.numActiveButtons ..":LeftButton")
			if binding then
				button:SetText(binding:gsub("(%w)%w*-?", function(a) return a end))
				button.binding = binding
			end

		end
	end
end

function QuestItemButton:CreateQuestItemButton(questID, questLogIndex)
	local questLogIndex = questLogIndex or (C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)) or (GetQuestLogIndexByID and GetQuestLogIndexByID(questID))
	if not questLogIndex then return end
	
	local link, texture = GetQuestLogSpecialItemInfo(questLogIndex)
	
	if link then
		printDebugMsg("Create quest item button.", {"QuestID; ", questID, "QuestIndex:", questLogIndex, "QuestItemLink:", link})
		local itemName = link and link:match("%[(.+)%]") or "Bucket of Slicky Water"
		local buttons = self.activeButtons
		local inactive = self.inactiveButtons
		
		if #inactive > 0 then
			table.sort(inactive, function(a, b) print(a.index, b.index) end)
			printDebugMsg({"Number of inactive buttons:", #inactive}, "Use inactive button")
			
			local button = inactive[#inactive]
			button:SetAttribute("item", itemName)
			button:SetNormalTexture(texture)
			button:SetPoint("TOP", self.anchorFrame, "BOTTOM", 0, (button.index-1)*(-60))
			button:Show()
			
			buttons[button] = true
			buttons[questID] = button
			button.questID = questID
			button.questLogIndex = questLogIndex
			
			self.numActiveButtons = self.numActiveButtons + 1
			inactive[#inactive] = nil
		else
			printDebugMsg("Create new button")
			
			self.numActiveButtons = self.numActiveButtons + 1
			local numActiveButtons = self.numActiveButtons
			
			local button = QuestButtonTemplate()
			button:SetAttribute("type", "item")
			button:SetAttribute("item", itemName)
			button:SetPoint("TOP", self.anchorFrame, "BOTTOM", 0, (numActiveButtons-1)*(-60))
			button:SetNormalTexture(texture)
			button:Show()

			buttons[button] = true
			buttons[questID] = button
			button.questID = questID		
			button.index = numActiveButtons
			button.questLogIndex = questLogIndex
			
			local binding = GetBindingKey("CLICK PRMKQUESTITEMBUTTON"..numActiveButtons..":LeftButton")
			if binding then
				button:SetText(binding:gsub("(%w)%w*-?", function(a) return a end))
				button.binding = binding
			end
		end
	end
end

function QuestItemButton:ReleaseQuestItemButton(questID)
	local buttons = self.activeButtons
	local button = buttons[questID]
	
	if button then
		button:ClearAllPoints()
		button:Hide()
		
		tinsert(self.inactiveButtons, button)
		
		button.questID = nil
		button.questLogIndex = nil
		buttons[button] = nil
		buttons[questID] = nil
		
		self.numActiveButtons = self.numActiveButtons - 1
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)

	if event == "ADDON_LOADED" and ... == name then
		QuestItemButtonDB = QuestItemButtonDB or {}
		local db = QuestItemButtonDB
	
		QuestItemButton.activeButtons = {}
		QuestItemButton.inactiveButtons = {}
		QuestItemButton.acceptedDelayed = {}
		QuestItemButton.turnedInDelayed = {}
		QuestItemButton.registered = {}
		QuestItemButton.numActiveButtons = 0
		
		local anchorFrame = CreateFrame("Button", "PRMKQUESTITEMANCHOR", UIParent)
		QuestItemButton.anchorFrame = anchorFrame
		anchorFrame:SetMovable(false)
		anchorFrame:EnableMouse(false)
		anchorFrame:RegisterForDrag("LeftButton")
		anchorFrame:SetScript("OnDragStart", anchorFrame.StartMoving)
		anchorFrame:SetScript("OnDragStop", function() 
			anchorFrame:StopMovingOrSizing()
			anchorFrame:SetUserPlaced(true)
			db.point, _, db.relativePoint, db.xOffset, db.yOffset = anchorFrame:GetPoint()
		end)
		anchorFrame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.xOffset or 0, db.yOffset or 0)
		anchorFrame:SetSize(100, 30)
		anchorFrame:SetNormalFontObject("GameFontNormal")
		anchorFrame:Show()
		
		self:RegisterEvent("QUEST_ACCEPTED")
		self:RegisterEvent("QUEST_REMOVED")
		self:RegisterEvent("QUEST_LOG_UPDATE")
		self:RegisterEvent("BAG_UPDATE_COOLDOWN")
		
	elseif event == "QUEST_LOG_UPDATE" then
		if not InCombatLockdown() then
			C_Timer.After(0.5, function()
				QuestItemButton:CreateQuestItemButtons() 
				print("|cffff00ff[QuestItemButton]|r loaded.") 
				
				hooksecurefunc("QuestObjectiveItem_Initialize", function(itemButton, questLogIndex) 
					checkIfButtonExists(frame, questLogIndex)
				end)
			end)
		
			self:RegisterEvent("UPDATE_BINDINGS")
			self:UnregisterEvent("QUEST_LOG_UPDATE")
		end
	elseif event == "UPDATE_BINDINGS" then
		local buttons = QuestItemButton.activeButtons
		
		for button in pairs(buttons) do
			local binding = GetBindingKey("CLICK " .. button:GetName() .. ":LeftButton")
			if binding and binding ~= button.binding then
				button:SetText(binding:gsub("(%w)%w*-?", function(a) return a end))
				button.binding = binding
			end
		end
	elseif event == "QUEST_ACCEPTED" then
		local questLogIndex, questID = ...
		
		if not questID then
			questID = questLogIndex
			questLogIndex = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
		end
		
		if not denylist[questID] then
			if InCombatLockdown() then
				QuestItemButton:Register(self, "PLAYER_REGEN_ENABLED")
				QuestItemButton.acceptedDelayed[questID] = questLogIndex
				printDebugMsg({"IN COMBAT", "Delay function."}) 
			else
				printDebugMsg({GetTime(), "QUEST_ACCEPTED", questLogIndex or "", questID})
				QuestItemButton:CreateQuestItemButton(questID, questLogIndex)
				QuestItemButtonDB.accepted = questLogIndex
			end
		end
	elseif event == "QUEST_REMOVED" then
		local questID = ...
		local buttons = QuestItemButton.activeButtons
		
		if InCombatLockdown() then
			QuestItemButton:Register(self, "PLAYER_REGEN_ENABLED")
			QuestItemButton.turnedInDelayed[questID] = true
		elseif buttons[questID] then
			QuestItemButton:ReleaseQuestItemButton(questID)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		QuestItemButton:Unregister(self, "PLAYER_REGEN_ENABLED")
	
		for questID in pairs(QuestItemButton.turnedInDelayed) do
			printDebugMsg({"Check button after combat", questID})
			QuestItemButton:ReleaseQuestItemButton(questID)
		end
		
		for questID, questLogIndex in pairs(QuestItemButton.acceptedDelayed) do
			printDebugMsg({"Check quest after combat", questID, questLogIndex})
			QuestItemButton:CreateQuestItemButton(questID, questLogIndex)
		end
		
		QuestItemButton.acceptedDelayed = {}
		QuestItemButton.turnedInDelayed = {}
	elseif event == "BAG_UPDATE_COOLDOWN" then
		for button in pairs(QuestItemButton.activeButtons) do
			if type(button) == "table" then
				local start, duration, enable = GetQuestLogSpecialItemCooldown(button.questLogIndex)
				--printDebugMsg({"Check Cooldown:", GetTime(), button.questLogIndex, start, duration, enable})
				if start and start > 0 then
					button.Cooldown:SetDrawEdge(true)
					button.Cooldown:SetCooldown(start, duration)
				end
			end
		end
	end
end)