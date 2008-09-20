--[[----------------------------------------------------------------------------------
	Broker_XPRate Core
	
	TODO:   impliment kills and click handler
           
------------------------------------------------------------------------------------]]

local UPDATEPERIOD = 1

local elapsed = 0
local starttime = 0
local totalgained = 0
local difftilllevel = 0
local lasttotal = 0
local tipshown

Broker_XPRate = LibStub("AceAddon-3.0"):NewAddon("Broker_XPRate", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_XPRate")
local frame = CreateFrame("frame")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("Broker_XPRate", {
    icon = "Interface\\Icons\\INV_Misc_Coin_02",
    OnClick = function(clickedframe, button)
        InterfaceOptionsFrame_OpenToFrame(Broker_XPRate.optionsframe)
    end,
})

local function round(num, idp)
	local mult = 10^(idp or 2)
	return math.floor(num * mult + 0.5) / mult
end

local function formattime(stamp)
	local days = math.floor(stamp/86400)
	if days > 0 then returnstring = returnstring .. days .. " days " else days = 0 end
	local hours = math.floor((stamp - days*86400)/3600)
	if strlen(tostring(hours)) == 1 then hours = "0" .. hours end
	local minutes = math.floor((stamp - days*86400 - hours*3600)/60)
	if strlen(tostring(minutes)) == 1 then minutes = "0" .. minutes end
	return returnstring .. hours .. ":" .. minutes
end

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function GetAvgXP()
	if totalgained == 0 then return 0 end
	return totalgained/(time() - starttime)
end

local function GetTimeToLevel()
	local avg = GetAvgXP()
	if avg == 0 then return "~" end
	local ttl = 1/(GetAvgXP()/difftilllevel)
	return formattime(ttl)
end

function dataobj:OnEnter()	tipshown = self
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()
	
	GameTooltip:AddLine("Broker_XPRate")
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["XP till next level:"], difftilllevel, 1,1,1, 1,1,1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["XP per hour:"] , round(GetAvgXP()*3600,0), 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine(L["XP per kill:"], "Not Implimented", 1,1,1, 1,1,1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(string.format(L["%s time to level"], GetTimeToLevel()))
	GameTooltip:AddLine(string.format(L["%s kills to level"], "Not Implimented"))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["LEFT-CLICK to toggle text options"])
	GameTooltip:AddLine(L["CTRL-CLICK to reset session"])
    
	GameTooltip:Show()
end

function dataobj:OnLeave()
    GameTooltip:Hide()
	tipshown = nil
end

local function resetsession()
	totalgained = 0
	starttime = time()
end

function dataobj.OnClick(self, button)
	if IsControlKeyDown() and button == "LeftButton" then
		resetsession()
	elseif button == "LeftButton" then
		if Broker_XPRate.db.profile.display == 1 then
			Broker_XPRate.db.profile.display = 2
		else
			Broker_XPRate.db.profile.display = 1
		end
	end
end

frame:SetScript("OnUpdate", function(self, elap)
	elapsed = elapsed + elap
	if elapsed < UPDATEPERIOD then return end
	elapsed = 0
	if Broker_XPRate.db.profile.display == 1 then
		dataobj.text = string.format(L["%s to level"], GetTimeToLevel(), 0)
	else
		dataobj.text = string.format(L["%s kills to level"], "Not Implimented")
	end

	if tipshown then dataobj.OnEnter(tipshown) end
end)

local function UpdateDifftilllevel()
	difftilllevel = UnitXPMax("player") - UnitXP("player")
end

local function GetDiff()
	local oldtotal = lasttotal
	lasttotal = UnitXP("player")
	if (lasttotal - oldtotal <= 0) then
		lasttotal = lasttotal + difftilllevel
	end
	UpdateDifftilllevel()
	return lasttotal - oldtotal
end

function Broker_XPRate:PLAYER_XP_UPDATE()
	totalgained = totalgained + GetDiff()
end

--Setup functions

function Broker_XPRate:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("Broker_XPRateDB", {}, "Default")
    self.db:RegisterDefaults({
        profile = {
			display = 1,
        },
    })
end

function Broker_XPRate:OnEnable()
	starttime = time() --save timestamp of when enabled
	lasttotal = UnitXP("player")
	UpdateDifftilllevel()
	self:RegisterEvent("PLAYER_XP_UPDATE")
end
