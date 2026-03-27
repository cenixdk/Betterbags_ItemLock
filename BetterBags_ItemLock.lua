local addonName, ns = ...
local BetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")
local events = BetterBags:GetModule('Events')

local merchantProtectionActive = false
local lastRenderedBag = nil
local hoveredLockButton = nil

-- 1. Initialize Database
local function InitializeDB()
    if not BetterBags_LockedItems then
        BetterBags_LockedItems = {}
    end
end

-- 2. Create the Padlock Overlay
local function GetOrCreateLockIcon(button)
    if not button.LockIcon then
        button.LockIcon = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.LockIcon:SetTexture("Interface\\BUTTONS\\LockButton-Locked-Up")
        button.LockIcon:SetSize(20, 20)
        button.LockIcon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    end
    return button.LockIcon
end

local ToggleItemLock -- forward declaration (RefreshMerchantOverlays needs it before its definition)

-- 3. Toggle Lock Logic
local function GetItemKey(itemData)
    local loc = ItemLocation:CreateFromBagAndSlot(itemData.bagid, itemData.slotid)
    if loc and C_Item.DoesItemExist(loc) then
        local guid = C_Item.GetItemGUID(loc)
        if guid then return guid end
    end
    return itemData.slotkey
end

-- 5. Merchant sell prevention via overlay frame (intercepts right-click before it reaches the secure button)
local function GetOrCreateMerchantOverlay(button)
    if button.merchantOverlay then return button.merchantOverlay end
    local overlay = CreateFrame("Button", nil, button)
    overlay:SetAllPoints()
    overlay:RegisterForClicks("RightButtonUp")
    overlay:SetScript("OnClick", function()
        UIErrorsFrame:AddMessage("Item is LOCKED and cannot be sold!", 1, 0, 0)
    end)
    overlay:SetScript("OnEnter", function()
        local onEnter = button:GetScript("OnEnter")
        if onEnter then onEnter(button) end
    end)
    overlay:SetScript("OnLeave", function()
        local onLeave = button:GetScript("OnLeave")
        if onLeave then onLeave(button) end
    end)
    overlay:Hide()
    button.merchantOverlay = overlay
    return overlay
end

local function RefreshMerchantOverlays()
    if not lastRenderedBag then return end
    InitializeDB()
    for _, item in pairs(lastRenderedBag.currentView:GetItemsByBagAndSlot()) do
        local data = item:GetItemData()
        local button = item.button
        local key = GetItemKey(data)
        if merchantProtectionActive and BetterBags_LockedItems[key] then
            local overlay = GetOrCreateMerchantOverlay(button)
            overlay:SetFrameLevel(button:GetFrameLevel() + 20)
            -- Forward Alt+Click so the item can still be unlocked while merchant is open
            overlay:SetScript("OnMouseDown", function(self, mouseButton)
                if IsAltKeyDown() and mouseButton == "LeftButton" then
                    ToggleItemLock(button, item:GetItemData())
                    RefreshMerchantOverlays()
                end
            end)
            overlay:Show()
        else
            if button.merchantOverlay then
                button.merchantOverlay:SetScript("OnMouseDown", nil)
                button.merchantOverlay:Hide()
            end
        end
    end
end

local merchantFrame = CreateFrame("Frame")
merchantFrame:RegisterEvent("MERCHANT_SHOW")
merchantFrame:RegisterEvent("MERCHANT_CLOSED")
merchantFrame:SetScript("OnEvent", function(_, event)
    merchantProtectionActive = (event == "MERCHANT_SHOW")
    RefreshMerchantOverlays()
end)

ToggleItemLock = function(button, itemData)
    local key = GetItemKey(itemData)
    local link = itemData.containerInfo.hyperlink
    local locked

    if BetterBags_LockedItems[key] then
        BetterBags_LockedItems[key] = nil
        print("|cFFFF0000[ItemLock] Unlocked:|r " .. link)
        locked = false
    else
        BetterBags_LockedItems[key] = true
        print("|cFF00FF00[ItemLock] Locked:|r " .. link)
        locked = true
    end

    -- Update lock icon immediately
    local icon = GetOrCreateLockIcon(button)
    if locked then icon:Show() else icon:Hide() end

    -- Refresh overlays so the OnMouseDown script is correctly set/cleared
    if merchantProtectionActive then
        RefreshMerchantOverlays()
    end
end

-- 4. Hook into BetterBags Rendering
events:RegisterMessage('bag/Rendered', function(_, bag)
    InitializeDB()
    lastRenderedBag = bag
    for _, item in pairs(bag.currentView:GetItemsByBagAndSlot()) do
        local data = item:GetItemData()
        local icon = GetOrCreateLockIcon(item.button)
        local key = GetItemKey(data)

        if BetterBags_LockedItems[key] then
            icon:Show()
        else
            icon:Hide()
        end

        -- Always update key on button so the tooltip hook can read it
        item.button.lockItemKey = key

        if not item.button.lockHooked then
            item.button:HookScript("OnMouseDown", function(self, button)
                if IsAltKeyDown() and button == "LeftButton" then
                    ToggleItemLock(self, item:GetItemData())
                end
            end)
            item.button:HookScript("OnEnter", function(self)
                hoveredLockButton = self
            end)
            item.button:HookScript("OnLeave", function() hoveredLockButton = nil end)
            item.button.lockHooked = true
        end
    end
    RefreshMerchantOverlays()
end)


-- 7. Tooltip hint — hooks OnShow so it fires regardless of how BetterBags populates the tooltip
local addingHint = false
GameTooltip:HookScript("OnShow", function(tooltip)
    if addingHint then return end
    local owner = tooltip:GetOwner()
    if not owner then return end
    -- owner is BetterBags' wrapper frame; the actual item button is owner.button
    local button = (owner.lockHooked and owner) or (owner.button and owner.button.lockHooked and owner.button)
    if not button then return end
    InitializeDB()
    addingHint = true
    if BetterBags_LockedItems[button.lockItemKey] then
        tooltip:AddLine("|cFFFFD700Alt+Click|r to unlock", 1, 1, 1)
    else
        tooltip:AddLine("|cFFFFD700Alt+Click|r to lock", 1, 1, 1)
    end
    tooltip:Show()
    addingHint = false
end)

-- 6. Disenchanting Prevention
local deFrame = CreateFrame("Frame")
deFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
deFrame:SetScript("OnEvent", function(_, _, unit, target, _, spellID)
    if unit == "player" and (spellID == 13262) then -- 13262 is Disenchant
        -- Loop through bags to find the item being targeted and block if locked
        -- (This requires matching the target name to the locked GUID)
    end
end)
