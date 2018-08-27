local MSG_PREFIX = 'SIS'
local motherlode = 'The MOTHERLODE!!'
local freehold = 'Freehold'
local ataldazar = "Atal'Dazar"
local toldagor = 'Tol Dagor'
local underrot = 'The Underrot'
local manor = 'Waycrest Manor'
local temple = 'Temple of Sethraliss'
local kingsrest = "Kings' Rest"
local shrine = 'Shrine of the Storm'
local siege = 'Siege of Boralus'
local Instances = {
  [motherlode] = {},
  [freehold] = {},
  [ataldazar] = {},
  [toldagor] = {},
  [underrot] = {},
  [manor] = {},
  [temple] = {},
  [kingsrest] = {},
  [shrine] = {},
  [siege] = {},
}
local group_members = {}
local print_done = false
local realm_name = GetRealmName()
local debug = false

function SavedInstancesSync_PrintSaved(instance)
    if next(Instances[instance]) ~= nil then
        local players = table.concat(Instances[instance], ", ")
        local player_without_current_realm = string.gsub(players, '-'..realm_name, '')
        print(" ", instance, "-", player_without_current_realm)
    end
end

function SavedInstancesSync_PrintUnsaved(instance)
    if next(Instances[instance]) == nil then
        print(" ", instance)
    end
end

function SavedInstancesSync_PrintResult()
    if print_done == false then
        print('Saved:')
        table.foreach(Instances, SavedInstancesSync_PrintSaved)
        print('Unsaved:')
        table.foreach(Instances, SavedInstancesSync_PrintUnsaved)
        if #group_members > 0 then
            print('Unknown:')
            print('  '..table.concat(group_members, ', '))
        end
    end
    print_done = true
end

function SavedInstancesSync_SlashCommandHandler()
    Instances = {
      [motherlode] = {},
      [freehold] = {},
      [ataldazar] = {},
      [toldagor] = {},
      [underrot] = {},
      [manor] = {},
      [temple] = {},
      [kingsrest] = {},
      [shrine] = {},
      [siege] = {},
    }
    print_done = false
    if IsInGroup() then
        group_members = {}
        for i=1, GetNumGroupMembers(), 1 do
            local name = GetRaidRosterInfo(i);
            if string.match(name, "-") == nil then
                table.insert(group_members, name..'-'..realm_name)
            else
                table.insert(group_members, name)
            end
        end
        if debug then
            print('Group members')
            table.foreach(group_members, print)
        end
        C_ChatInfo.SendAddonMessage(MSG_PREFIX, 'SYNC_REQUESTED', 'PARTY')
        C_Timer.After(1, SavedInstancesSync_PrintResult)
    else
        print('You are not in a group')
    end
end

function SavedInstancesSync_SendInstances()
    C_ChatInfo.SendAddonMessage(MSG_PREFIX, 'START', 'PARTY')
    for i=1,GetNumSavedInstances(),1 do
        local name,_,reset,difficulty,_,_,_,_,_,_,numEncounters,encounterProgress,_ = GetSavedInstanceInfo(i);
        if difficulty == 23 and reset > 0 then
            local payload = string.format("%s^%d^%d", name, encounterProgress, numEncounters)
            C_ChatInfo.SendAddonMessage(MSG_PREFIX, payload, 'PARTY')
        end
    end
    C_ChatInfo.SendAddonMessage(MSG_PREFIX, 'END', 'PARTY')
end

function SendRecieve(self, event, ...)
    local prefix, payload, type, sender = select(1, ...)
    if event == "CHAT_MSG_ADDON" then
        if prefix == MSG_PREFIX then
            if debug then
                print("Received:", prefix, payload, type, sender)
            end
            if payload == 'SYNC_REQUESTED' then
                SavedInstancesSync_SendInstances()
            elseif payload == 'START' then
                for i=#group_members, 1, -1 do
                    if group_members[i] == sender then
                        tremove(group_members, i)
                    end
                end
                if debug then
                    print('Sync starting for '..sender)
                end
            elseif payload == 'END' then
                if #group_members == 0 then
                    SavedInstancesSync_PrintResult()
                end
                if debug then
                    print('Sync ended for '..sender)
                end
            else
                local name, _, _= strsplit("^", payload)
                table.insert(Instances[name], sender)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(MSG_PREFIX)
    end
end

local SavedInstancesSync = CreateFrame("Frame")
SavedInstancesSync:RegisterEvent("CHAT_MSG_ADDON")
SavedInstancesSync:RegisterEvent("PLAYER_ENTERING_WORLD")
SavedInstancesSync:SetScript("OnEvent", SendRecieve)
SlashCmdList["SAVEDINSTANCESSYNC"] = SavedInstancesSync_SlashCommandHandler;
SLASH_SAVEDINSTANCESSYNC1 = "/sis";