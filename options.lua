local name, QuestItemButton = ...
    
local frame = CreateFrame("Frame", name .. "ConfigFrame", InterfaceOptionsFramePanelContainer)
frame.name = name
frame:Hide()
frame:SetScript("OnShow", function(frame)
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("QuestItemButton Configuration")

    local toggleAnchor = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	toggleAnchor:SetSize(120, 30)
    toggleAnchor.Text:SetText("Toggle Anchor")
    toggleAnchor:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    toggleAnchor:SetScript("OnClick", function(self) 
		local anchorFrame = QuestItemButton.anchorFrame
		
		if anchorFrame:GetText() == "ANCHOR" then
			anchorFrame:SetText("")
			anchorFrame:SetMovable(false)
			anchorFrame:EnableMouse(false)
		else
			anchorFrame:SetText("ANCHOR")
			anchorFrame:SetMovable(true)
			anchorFrame:EnableMouse(true)
		end
    end)
	
	local debugging = CreateFrame("CheckButton", nil, toggleAnchor, "ChatConfigCheckButtonTemplate")
    debugging.Text:SetText("Debugging Mode")
    debugging:SetPoint("TOPLEFT", toggleAnchor, "BOTTOMLEFT", 0, -15)
    debugging:SetChecked(QuestItemButtonDB.debug)
    debugging:SetScript("OnClick", function(self) 
        QuestItemButtonDB.debug = self:GetChecked()
    end)
end)

InterfaceOptions_AddCategory(frame)
