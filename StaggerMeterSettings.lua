local function EnableSettingsWindow(frame)
    -- Enable mouse interaction with the frame
    frame:EnableMouse(true)
    for _, child in ipairs({frame:GetChildren()}) do
        if child:IsObjectType("Button") or child:IsObjectType("CheckButton") then
            child:SetEnabled(true)  -- Enable all buttons, checkboxes, etc.
        end
    end
end

local function DisableSettingsWindow(frame)
    -- Disable mouse interaction with the frame
    frame:EnableMouse(false)
    for _, child in ipairs({frame:GetChildren()}) do
        if child:IsObjectType("Button") or child:IsObjectType("CheckButton") then
            child:SetEnabled(false)  -- Disable all buttons, checkboxes, etc.
        end
    end
end

local function CreateSettingsWindow()
    local frame = CreateFrame("Frame", "StaggerMeter_SettingsWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 250)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText("StaggerMeter Settings")

    -- Label for moving frame option
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", frame, "TOP", 0, -30)
    label:SetText("Move Stagger frame position (w/ LMB):")

    -- Set Keybind
    local setKeyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    setKeyButton:SetSize(200, 30)
    setKeyButton:SetPoint("TOP", label, "BOTTOM", 0, -10)
    setKeyButton:SetText(StaggerMeter_Settings.moveKey ~= "" and "Key(s): " .. StaggerMeter_Settings.moveKey or "Set Key")

    -- Save Button
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(200, 30)
    saveButton:SetPoint("TOP", setKeyButton, "BOTTOM", 0, -10)
    saveButton:SetText("Save Keybinding")
    saveButton:SetEnabled(false)

    local keyCaptureInProgress = false
    local keyCount = 0

    local function StartKeyCapture()
        keyCount = 0
        StaggerMeter_Settings.moveKey = ""
        setKeyButton:SetText("Press up to 3 keys...")
        setKeyButton:SetEnabled(false)
        saveButton:SetEnabled(false)

        keyCaptureInProgress = true

        local function OnKeyDown(_, key)
            local keyString = key:upper()

            if keyString == "ESCAPE" or keyString == "BACKSPACE" or keyString == "ENTER" or keyString == "TAB" then
                return
            end

            if keyCount >= 3 then
                return
            end

            -- Escape special characters
            if StaggerMeter_Settings.moveKey == "" or not StaggerMeter_Settings.moveKey:match(keyString) then
                if keyCount > 0 then
                    StaggerMeter_Settings.moveKey = StaggerMeter_Settings.moveKey .. "-" .. keyString
                else
                    StaggerMeter_Settings.moveKey = keyString
                end
                keyCount = keyCount + 1
            end

            setKeyButton:SetText("Key(s): " .. StaggerMeter_Settings.moveKey)

            if keyCount > 0 then
                saveButton:SetEnabled(true)
            end
        end

        frame:SetScript("OnKeyDown", OnKeyDown)
        frame:EnableKeyboard(true)
    end

    setKeyButton:SetScript("OnClick", function(self)
        if keyCaptureInProgress then
            StartKeyCapture()
        else
            StartKeyCapture()
        end
    end)

    saveButton:SetScript("OnClick", function()
        if StaggerMeter_Settings.moveKey ~= "" then
            print("Keybinding saved: " .. StaggerMeter_Settings.moveKey)
        else
            print("No keybinding set.")
        end

        setKeyButton:SetEnabled(true)
        setKeyButton:SetText("Key(s): " .. StaggerMeter_Settings.moveKey)
        saveButton:SetEnabled(false)
        keyCaptureInProgress = false
        frame:SetScript("OnKeyDown", nil)
        frame:EnableKeyboard(false)
    end)

    -- Current HP damage % vs Stagger % Checkbox
    local healthPercentageCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    healthPercentageCheckbox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 60)  -- Position the checkbox just above the close button
    healthPercentageCheckbox.text = healthPercentageCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthPercentageCheckbox.text:SetPoint("BOTTOM", healthPercentageCheckbox, "TOP", 0, 5)  -- Position it above the checkbox, with a small gap
    healthPercentageCheckbox.text:SetText("Show incoming damage (as percentage of your current health):")

    healthPercentageCheckbox:SetChecked(StaggerMeter_Settings.showIncomingOverMaxHP)

    healthPercentageCheckbox:SetScript("OnClick", function(self)
        StaggerMeter_Settings.showIncomingOverMaxHP = self:GetChecked()
    end)

    -- Note Text
    local noteText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteText:SetPoint("TOP", healthPercentageCheckbox, "BOTTOM", 0, -5)
    noteText:SetText("Note: Colour of the bar will still represent Stagger severity")
    noteText:SetJustifyH("CENTER")
    noteText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    -- Close Button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    closeButton:SetScript("OnClick", function()
        if InCombatLockdown() then
            print("Cannot close settings window while in combat.")
            return
        end

        if StaggerMeter_Settings.moveKey ~= "" then
            print("Keybinding saved on close: " .. StaggerMeter_Settings.moveKey)
        else
            print("No keybinding set.")
        end
        frame:Hide()
    end)

    -- Event handling for entering and leaving combat
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Disable settings window when entering combat
            DisableSettingsWindow(frame)
            frame:Hide()
            print("StaggerMeter settings window automatically closed because you entered combat.")
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Enable settings window when leaving combat
            EnableSettingsWindow(frame)
            frame:Show()  -- Ensure the window shows when combat ends
        end
    end)

    -- Initial display of the settings window
    frame:Show()
end

SLASH_STAGGERMETER1 = "/smsm"
SlashCmdList["STAGGERMETER"] = function()
    -- Prevent opening the settings window while in combat
    if InCombatLockdown() then
        print("Cannot open StaggerMeter settings while in combat.")
        return
    end

    -- Create or show the settings window
    if not StaggerMeter_SettingsWindow then
        CreateSettingsWindow()
    else
        StaggerMeter_SettingsWindow:Show()
    end
end
