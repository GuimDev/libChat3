--[[

This Add-on is not created by, affiliated with or sponsored by ZeniMax
Media Inc. or its affiliates. The Elder Scrolls® and related logos are
registered trademarks or trademarks of ZeniMax Media Inc. in the United
States and/or other countries. All rights reserved.
You can read the full terms at https://account.elderscrollsonline.com/add-on-terms

This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at : 
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode


LibChat2 is a library which must be embedded into an ESO Addon, throught its manifest like this :
path/libChat2/libChat2.lua

LibChat2 require LibStub to work

Last Author: Ayantir --> Version: 9 and inferior

-----

Filename: libChat3.lua
Version: 10
Author: Provision

Mini :
|                           message                         |
|   {___1___} | {Sender} | {___2___} | {Text} | {___3___}   |
| BfAll |      playerLink      |        text        | ..... |

Full :
|            |                    ___1___                    | {Sender} |                    ___2___                    | {Text} |                    ___3___                    |
| Position : |   BeforeAll   | {OptEsoFormat} | BeforeSender |          |  AfterSender  | {OptEsoFormat} |  BeforeText  |        |   AfterText   | {OptEsoFormat} | ............ |
| Index :    | DDS_  | Text_ |                | DDS_ | Text_ |          | Text_ | DDS_  |                | DDS_ | Text_ |        | Text_ | DDS_  |                | ............ |
| Variable : |  channelLink  |                |               playerLink                |                |                 text                  |                | ............ |

 *{OptEsoFormat} = {OptionnalESOUIFormat}

-----

CHAT_SYSTEM does not permit to get 2 libraries running together and using ChatBox, the first loaded into memory will rewrite EVERYTHING and other addons will fail

- If you REWRITE message, you're hugely prompted to use LibChat2, without it, you'll surely kill other chat Addons
	eg: Append some text, rewrite sender name, rewrite colors, etc
	
- DO NOT USE this library if you don't REWRITE the message sent
- If you only APPEND something with a d() or a AddMessage(), you don't need LibChat2


WARNING using registerFormat() : This method should only be called when rewriting from + text + infos (colors, chanCode, etc), please only use this method if your addon REWRITE the WHOLE message
If you need to rewrite From, please only use registerName
If you need to rewrite Text, please only use registerText
If you need to append text somewhere without changing the text sent, please use one of the following methods :
DDSBeforeAll, TextBeforeAll, DDSBeforeSender, TextBeforeSender, TextAfterSender, DDSAfterSender, DDSBeforeText, TextBeforeText, TextAfterText, DDSAfterText

Revisions of libChat

Minor = 1 : libChat-1
Minor = 2 : LibChat2 1.0
Minor = 3 : LibChat2 1.1
Minor = 4 : LibChat2 1.2
Minor = 5 : LibChat2 1.3 (internal release)
Minor = 6 : LibChat2 Justice
Minor = 7 : LibChat2 1.6
Minor = 8 : LibChat2 8
Minor = 9 : LibChat2 9

Minor = 10 : LibChat3 10 <-- Provision Update

Allow several addon listeners on one event (without conflict) :
 - registerName
 - registerText
 - registerAppendDDSBeforeAll
 - registerAppendTextBeforeAll
 - registerAppendDDSBeforeSender
 - registerAppendTextBeforeSender
 - registerAppendDDSAfterSender
 - registerAppendTextAfterSender
 - registerAppendDDSBeforeText
 - registerAppendTextBeforeText
 - registerAppendDDSAfterText
 - registerAppendTextAfterText

Old version : http://www.esoui.com/downloads/info740-libChat2.html

More info : http://www.esoui.com/downloads/__________.html

]]--

local LIB_NAME, LIB_VERSION = "libChat-1.0", 10

local libchat, oldminor = LibStub:NewLibrary(LIB_NAME, LIB_VERSION)
if not libchat then
	return
end

-- local declaration
local PositionList = { "BeforeAll", "BeforeSender", "AfterSender", "BeforeText", "AfterText" }
local IndexList = { "DDS", "Text" }
local functionNameTemplate = "%s%s%s"

local storage = {
	BeforeAll = { DDS = {}, Text = {} },
	BeforeSender = { DDS = {},	Text = {} },
	AfterSender = {	DDS = {}, Text = {} },
	BeforeText = { DDS = {}, Text = {} },
	AfterText = { DDS = {}, Text = {} },
	parser = {
		Name = {},
		Text = {},
		Format = nil -- only one
	}
}

local funcFriendStatus
local funcIgnoreAdd
local funcIgnoreRemove
local funcGroupMemberLeft
local funcGroupTypeChanged

-- Initialize Manager to trace Addons
if not libchat.manager then
	libchat.manager = {}
end

-- Returns ZOS CustomerService Icon if needed
local function showCustomerService(isCustomerService)

	if(isCustomerService) then
		return "|t16:16:EsoUI/Art/ChatWindow/csIcon.dds|t"
	end
	
	return ""
	
end

-- Listens for EVENT_CHAT_MESSAGE_CHANNEL event from ZO_ChatSystem
function libchat:MessageChannelReceiver(channelID, from, text, isCustomerService, fromDisplayName)
	local output = {
		BeforeAll = { DDS = "", Text = "" },
		BeforeSender = { DDS = "", Text = "" },
		AfterSender = { DDS = "", Text = "" },
		BeforeText = { DDS = "", Text = "" },
		AfterText = { DDS = "", Text = "" }
	}

	local message
	local originalFrom = from
	local originalText = text
	
	-- Get channel information
	local ChanInfoArray = ZO_ChatSystem_GetChannelInfo()
	local info = ChanInfoArray[channelID]
	
	if not info or not info.format then
		return
	end

	for _, position in ipairs(PositionList) do
		for _, index in ipairs(IndexList) do
			-- Function to append
			local callbacks = storage[position][index]

			for _, func in ipairs(callbacks) do
				local str = func(channelID, from, text, isCustomerService, fromDisplayName)
				output[position][index] = output[position][index] .. str
			end
		end
	end

	-- Function to affect From
	for _, func in ipairs(storage.parser.Name) do
		from = func(channelID, from, isCustomerService, fromDisplayName)
	end
	if not from then return end

	-- Function to format text
	for _, func in ipairs(storage.parser.Text) do
		text = func(channelID, from, text, isCustomerService, fromDisplayName)
	end
	if not text then return end
	
	-- Function to format message
	if storage.parser.Format then
		message = storage.parser.Format(channelID, from, text, isCustomerService, fromDisplayName, originalFrom, originalText, output.BeforeAll.DDS, output.BeforeAll.Text, output.BeforeSender.DDS, output.BeforeSender.Text, output.AfterSender.Text, output.AfterSender.DDS, output.BeforeText.DDS, output.BeforeText.Text, output.AfterText.Text, output.AfterText.DDS)
		if not message then return end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
		
		-- Create channel link
		local channelLink
		if info.channelLinkable then
			local channelName = GetChannelName(info.id)
			channelLink = ZO_LinkHandler_CreateChannelLink(channelName)
		end
		
		-- Create player link
		local playerLink
		if info.playerLinkable and not from:find("%[") then
			playerLink = output.BeforeSender.DDS .. output.BeforeSender.Text .. ZO_LinkHandler_CreatePlayerLink((from)) .. output.AfterSender.Text .. output.AfterSender.DDS
		else
			playerLink = output.BeforeSender.DDS .. output.BeforeSender.Text .. from .. output.AfterSender.Text .. output.AfterSender.DDS
		end
		
		text = output.BeforeText.DDS .. output.BeforeText.Text .. text .. output.AfterText.Text .. output.AfterText.DDS
		
		-- Create default formatting
		if channelLink then
			message = output.BeforeAll.DDS .. output.BeforeAll.Text .. zo_strformat(info.format, channelLink, playerLink, text)
		else
			message = output.BeforeAll.DDS .. output.BeforeAll.Text .. zo_strformat(info.format, playerLink, text, showCustomerService(isCustomerService))
		end
	end
	
	return message, info.saveTarget
	
end

-- Listens for EVENT_FRIEND_PLAYER_STATUS_CHANGED event from ZO_ChatSystem
local function libChatFriendPlayerStatusChangedReceiver(displayName, characterName, oldStatus, newStatus)
	
	-- If function registrered in Addon, code will run
	local friendStatusMessage
	
	if funcFriendStatus then
		friendStatusMessage = funcFriendStatus(displayName, characterName, oldStatus, newStatus)
		if friendStatusMessage then
			return friendStatusMessage
		else
			return
		end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
	
		local wasOnline = oldStatus ~= PLAYER_STATUS_OFFLINE
		local isOnline = newStatus ~= PLAYER_STATUS_OFFLINE
		
		-- DisplayName is linkable
		local displayNameLink = ZO_LinkHandler_CreateDisplayNameLink(displayName)
		-- CharacterName is linkable
		local characterNameLink = ZO_LinkHandler_CreateCharacterLink(characterName)
		
		-- Not connected before and Connected now (no messages for Away/Busy)
		if(not wasOnline and isOnline) then
			-- Return
			return zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_ON, displayNameLink, characterNameLink)
		-- Connected before and Offline now
		elseif(wasOnline and not isOnline) then
			return zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayNameLink, characterNameLink)
		end
		
	end
	
end

-- Listens for EVENT_IGNORE_ADDED event from ZO_ChatSystem
local function libChatIgnoreAddedReceiver(displayName)
	
	-- If function registrered in Addon, code will run
	local ignoreAddMessage
	
	if funcIgnoreAdd then
		ignoreAddMessage = funcIgnoreAdd(displayName)
		if ignoreAddMessage then
			return ignoreAddMessage
		else
			return
		end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
		
		-- DisplayName is linkable
		local displayNameLink = ZO_LinkHandler_CreateDisplayNameLink(displayName)
		ignoreAddMessage = zo_strformat(SI_FRIENDS_LIST_IGNORE_ADDED, displayNameLink)
		
	end
	
	return ignoreAddMessage
	
end

-- Listens for EVENT_IGNORE_REMOVED event from ZO_ChatSystem
local function libChatIgnoreRemovedReceiver(displayName)
	
	-- If function registrered in Addon, code will run
	local ignoreRemoveMessage
	
	if funcIgnoreRemove then
		ignoreRemoveMessage = funcIgnoreRemove(displayName)
		if ignoreRemoveMessage then
			return ignoreRemoveMessage
		else
			return
		end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
		
		-- DisplayName is linkable
		local displayNameLink = ZO_LinkHandler_CreateDisplayNameLink(displayName)
		ignoreRemoveMessage = zo_strformat(SI_FRIENDS_LIST_IGNORE_REMOVED, displayNameLink)
		
	end
	
	return ignoreRemoveMessage
	
end

-- Listens for EVENT_GROUP_MEMBER_LEFT event from ZO_ChatSystem
local function libChatGroupMemberLeftReceiver(characterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
	
	-- If function registrered in Addon, code will run
	local groupMemberLeftMessage
	
	if funcGroupMemberLeft then
		groupMemberLeftMessage = funcGroupMemberLeft(characterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
		if groupMemberLeftMessage then
			return groupMemberLeftMessage
		else
			return
		end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
		if reason == GROUP_LEAVE_REASON_KICKED and isLocalPlayer and actionRequiredVote then
			groupMemberLeftMessage = GetString(SI_GROUP_ELECTION_KICK_PLAYER_PASSED)
		end
		
	end
	
	return groupMemberLeftMessage
	
end

-- Listens for EVENT_GROUP_TYPE_CHANGED event from ZO_ChatSystem
local function libChatGroupTypeChangedReceiver(largeGroup)
	
	-- If function registrered in Addon, code will run
	local GroupTypeChangedMessage
	
	if funcGroupTypeChanged then
		GroupTypeChangedMessage = funcGroupTypeChanged(largeGroup)
		if GroupTypeChangedMessage then
			return GroupTypeChangedMessage
		else
			return
		end
	else
	
		-- Code to run with libChat loaded and Addon not registered to libchat - IT MUST BE ~SAME~ AS ESOUI -
		
        if largeGroup then
            return GetString(SI_CHAT_ANNOUNCEMENT_IN_LARGE_GROUP)
        else
            return GetString(SI_CHAT_ANNOUNCEMENT_IN_SMALL_GROUP)
        end
		
	end
	
end

local function registerFunction(callback, funcToUse, position, index, ...)

	if funcToUse == "registerName" then
		table.insert(storage.parser.Name, callback)
	elseif funcToUse == "registerText" then
		table.insert(storage.parser.Text, callback)
	elseif funcToUse == "registerFormat" then
		storage.parser.Format = callback
	elseif funcToUse == "registerAppend" then
		table.insert(storage[position][index], callback)
		funcToUse = "registerAppend" .. index .. position
	-- old
	elseif funcToUse == "registerFriendStatus" then
		funcFriendStatus = callback
	elseif funcToUse == "registerIgnoreAdd" then
		funcIgnoreAdd = callback
	elseif funcToUse == "registerIgnoreRemove" then
		funcIgnoreRemove = callback
	elseif funcToUse == "registerGroupMemberLeft" then
		funcGroupMemberLeft = callback
	elseif funcToUse == "registerGroupTypeChanged" then
		funcGroupTypeChanged = callback
	end
	
	if not libchat.manager[funcToUse] then
		libchat.manager[funcToUse] = {}
	end
	
	-- Adding the registration to manager
	local addonName = select(1, ...)
	-- AddonName registered!
	if addonName then
		if type(addonName) == "string" then
			table.insert(libchat.manager[funcToUse], addonName)
		else
			table.insert(libchat.manager[funcToUse],"Anonymous AddOn")
		end
	-- AddonName not set, so.. Anonymous
	else
		table.insert(libchat.manager[funcToUse],"Anonymous AddOn")
	end
end

-- Register a function to be called to modify MessageChannel Sender Name
function libchat:registerName(func, ...)
	registerFunction(func, "registerName", nil, nil, ...)
end

-- Register a function to be called to modify MessageChannel Text
function libchat:registerText(func, ...)
	registerFunction(func, "registerText", nil, nil, ...)
end

-- Register a function to be called to format MessageChannel whole Message
function libchat:registerFormat(func, ...)
	registerFunction(func, "registerFormat", nil, nil, ...)
end

-- register functions to be called to format MessageChannel Message
local function createMyFunction(funcPrefix, position, index)
    local functionName = functionNameTemplate:format(funcPrefix, index, position)
    libchat[functionName] = function(self, func, ...)
        registerFunction(func, funcPrefix, position, index, ...)
    end
end

-- libchat:registerAppendDDSBeforeAll, libchat:registerAppendTextBeforeAll, libchat:registerAppendDDSBeforeSender, libchat:registerAppendTextBeforeSender,
-- libchat:registerAppendDDSAfterSender, libchat:registerAppendTextAfterSender, libchat:registerAppendDDSBeforeText, libchat:registerAppendTextBeforeText,
-- libchat:registerAppendDDSAfterText, libchat:registerAppendTextAfterText
for _, position in ipairs(PositionList) do
    for _, index in ipairs(IndexList) do
        createMyFunction("registerAppend", position, index)
    end
end

-- Register a function to be called to format FriendStatus Message
function libchat:registerFriendStatus(func, ...)
	registerFunction(func, "registerFriendStatus", nil, nil, ...)
end

-- Register a function to be called to format IgnoreAdd Message
function libchat:registerIgnoreAdd(func, ...)
	registerFunction(func, "registerIgnoreAdd", nil, nil, ...)
end

-- Register a function to be called to format IgnoreRemove Message
function libchat:registerIgnoreRemove(func, ...)
	registerFunction(func, "registerIgnoreRemove", nil, nil, ...)
end

-- Register a function to be called to format GroupTypeChanged Message
function libchat:registerGroupMemberLeft(func, ...)
	registerFunction(func, "registerGroupMemberLeft", nil, nil, ...)
end

-- Register a function to be called to format GroupTypeChanged Message
function libchat:registerGroupTypeChanged(func, ...)
	registerFunction(func, "registerGroupTypeChanged", nil, nil, ...)
end

local function libchatdebug()
	
	local message
	
	CHAT_SYSTEM:AddMessage("---- libchat2 debug ----")
	CHAT_SYSTEM:AddMessage("Note : 2 addons registering same method will provoke conflicts")
	
	for keymanager, subarray in pairs(libchat.manager) do
		message = keymanager .. " set with addon "
		if keymanager == "registerFormat" then 
			message = message .. "WARNING : method overwrite Sender name and Message !"
		end
		for addonIndex, addonName in ipairs(subarray) do message = message .. " #" .. addonIndex .. " " .. addonName .. "," end
		CHAT_SYSTEM:AddMessage(message)
	end
	
	CHAT_SYSTEM:AddMessage("---- end of libchat2 debug ----")
	
end
 
SLASH_COMMANDS["/libchat"] = libchatdebug

-- AddEventHandler to ZO_ChatSystem with same name than the original one cause the Event triggers library instead of ESOUI
ZO_ChatSystem_AddEventHandler(EVENT_CHAT_MESSAGE_CHANNEL, function(...) return libchat:MessageChannelReceiver(...) end)
ZO_ChatSystem_AddEventHandler(EVENT_FRIEND_PLAYER_STATUS_CHANGED, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_IGNORE_ADDED, libChatIgnoreAddedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_IGNORE_REMOVED, libChatIgnoreRemovedReceiver)

ZO_ChatSystem_AddEventHandler(EVENT_GROUP_MEMBER_LEFT, libChatGroupMemberLeftReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_GROUP_TYPE_CHANGED, libChatGroupTypeChangedReceiver)

--[[

Not Yet

ZO_ChatSystem_AddEventHandler(EVENT_SERVER_SHUTDOWN_INFO, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_BROADCAST, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_QUEUE_FOR_CAMPAIGN_RESPONSE, libChatFriendPlayerStatusChangedReceiver)

ZO_ChatSystem_AddEventHandler(EVENT_STUCK_ERROR_ON_COOLDOWN, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_STUCK_ERROR_ALREADY_IN_PROGRESS, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_STUCK_ERROR_IN_COMBAT, libChatFriendPlayerStatusChangedReceiver)
ZO_ChatSystem_AddEventHandler(EVENT_STUCK_ERROR_INVALID_LOCATION, libChatFriendPlayerStatusChangedReceiver)
]]--
