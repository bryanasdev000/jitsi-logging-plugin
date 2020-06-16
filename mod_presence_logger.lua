-- Token authentication
-- Copyright (C) 2015 Atlassian

-- Code spaghetti between mod_token_verification.lua (Jitsi Team),
-- mod_token_moderation (nvonahsen and Seekerofpie) and my own code

-- Objetivo
-- Repassar as informacoes do token JWT decodadas para o microservico

-- Prosody internal lib
local log = module._log;
local host = module.host;
local st = require "util.stanza";
local is_admin = require "core.usermanager".is_admin;
local time = require "util.time";
-- External lib
local json = require "cjson";
local basexx = require "basexx";
local http = require "net.http";

-- TODO
-- timestamp UTC
-- Enviar requisicao POST
-- Status code da requisicao
-- LICENSE
-- FUTURE TODO
-- healthcheck do user (Speakerstats)
-- jid


-- module init
log("debug", "Presence logger - init");
-- module init


-- token context
local parentHostName = string.gmatch(tostring(host), "%w+.(%w.+)")();
if parentHostName == nil then
	log("error", "Presence logger - Failed to start - unable to get parent hostname");
	return;
end

local parentCtx = module:context(parentHostName);
if parentCtx == nil then
	log("error",
		"Presence logger - Failed to start - unable to get parent context for host: %s",
		tostring(parentHostName));
	return;
end

local token_util = module:require "token/util".new(parentCtx);
-- token context


-- no token configuration
if token_util == nil then
	log("errror","Presence logger - Failed to start, no token configuration enabled")
    return;
end
-- no token configuration


log("debug",
	"Presence logger - host: %s - starting MUC token verifier app_id: %s app_secret: %s allow empty: %s",
	tostring(host), tostring(token_util.appId), tostring(token_util.appSecret),
	tostring(token_util.allowEmptyToken));

local function response_check(response_body, response_code, response)
	log("info","REGISTER CALLBACK");
	return true;
end

local function presence_log(session, stanza, action)
	log("info", "Presence logger - token: %s, session room: %s",
		tostring(session.auth_token),
		tostring(session.jitsi_meet_room));

	-- token not required for admin users
	local user_jid = stanza.attr.from;
	if is_admin(user_jid) then
		log("debug", "Presence logger - Token not required from admin user: %s", user_jid);
		return nil;
	end
	-- token not required for admin users

    log("info",
        "Presence logger - Checking token for user: %s, room: %s ", user_jid, stanza.attr.to);
	--[[
	if not token_util:verify_room(session, stanza.attr.to) then
        log("info", "Presence logger - Token %s not allowed to join: %s",
            tostring(session.auth_token), tostring(stanza.attr.to));
        session.send(
            st.error_reply(
                stanza, "cancel", "not-allowed", "Room and token mismatched"));
        return false; -- we need to just return non nil
	end
	]]--

	log("info","Presence logger - allowed: %s to enter/create room: %s", user_jid, stanza.attr.to);

	-- JWT decode	
	local dotFirst = session.auth_token:find("%.");
	if dotFirst then
		local dotSecond = session.auth_token:sub(dotFirst + 1):find("%.");
		if dotSecond then
			local bodyB64 = session.auth_token:sub(dotFirst + 1, dotFirst + dotSecond - 1);
			local body = json.decode(basexx.from_url64(bodyB64));
			log("info", "REGISTER Sala %s", tostring(body["room"]));
			log("info", "REGISTER Email %s", tostring(body["email"]));
			log("info", "REGISTER GroupID %s", tostring(body["groupid"]));
			log("info", "REGISTER CourseID %s", tostring(body["courseid"]));
			log("info", "REGISTER User %s", tostring(body["context"]["user"]["name"]));
			log("info", "REGISTER Timestamp UTC %d",time.now());
			log("info", "REGISTER Action %s", tostring(action));
			local options = {
				headers = {
					["Content-Type"] = "application/json";
				};
				body = string.format('{"sala":"%s","email":"%s","turma":%d,"curso":%d,"aluno":"%s","timestamp":%d,"action":"%s"}',tostring(body["room"]),tostring(body["email"]),tostring(body["groupid"]),tostring(body["courseid"]),tostring(body["context"]["user"]["name"]),time.now(),tostring(action));
			}; 
			req = http.request("https://teste-lua-jitsi.free.beeceptor.com/my/api/path",options,log());
			return true;
			-- Work with callback status code != 200		
		end;
	else
		log("error","Presence logger - Failed to decode JWT");
	end;
	-- JWT decode	
end

-- hooks
module:hook("muc-occupant-joined", function(event)
	local origin, stanza, action = event.origin, event.stanza, "login";
	return presence_log(origin, stanza, action);
end);

module:hook("muc-occupant-pre-leave", function(event)
	local origin, room, stanza, action = event.origin, event.room, event.stanza, "logout";
	return presence_log(origin, stanza, action);
end);
-- hooks
