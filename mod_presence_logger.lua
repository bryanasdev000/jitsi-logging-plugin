-- Code spaghetti between mod_token_verification.lua (Jitsi Team),
-- mod_token_moderation (nvonahsen and Seekerofpie) and my own code.


-- Prosody internal lib
local log = module._log;
local host = module.host;
local st = require "util.stanza";
local is_admin = require "core.usermanager".is_admin;
local time = require "util.time";
local http = require "net.http";
-- External lib
local json = require "cjson";
local basexx = require "basexx";


-- TODO
-- Status code da requisicao + callback
-- License
-- Internationalization
-- FUTURE TODO
-- Healthcheck do user (Speakerstats)


-- module init
log("debug", "Presence logger - init");
-- module init


-- callback
local function response_check(response_body, response_code, response)
  log("info","REGISTER CALLBACK");
end
-- callback


-- main guy
local function presence_log(session, stanza, action, datetime)
  if session.auth_token then
    log("info", "Presence logger - token: %s, session room: %s",
    tostring(session.auth_token),
    tostring(session.jitsi_meet_room));
    log("info","Presence logger - user: %s entered room: %s", stanza.attr.from, stanza.attr.to);
    -- JWT + req magic
    local dotFirst = session.auth_token:find("%.");
    if dotFirst then
      local dotSecond = session.auth_token:sub(dotFirst + 1):find("%.");
      if dotSecond then
        local bodyB64 = session.auth_token:sub(dotFirst + 1, dotFirst + dotSecond - 1);
        local body = json.decode(basexx.from_url64(bodyB64));
        log("info", "Presence logger - REGISTER Sala %s", tostring(body.room));
        log("info", "Presence logger - REGISTER CourseID %s", tostring(body.courseid));
        log("info", "Presence logger - REGISTER GroupID %s", tostring(body.groupid));
        log("info", "Presence logger - REGISTER User %s", tostring(body.context.user.name));
        log("info", "Presence logger - REGISTER JID %s", tostring(stanza.attr.from));
        log("info", "Presence logger - REGISTER Email %s", tostring(body.email));
        log("info", "Presence logger - REGISTER Timestamp UTC %d",datetime);
        log("info", "Presence logger - REGISTER Action %s", tostring(action));
        local options = {
          headers = {
            ["Content-Type"] = "application/json";
          };
          body = string.format('{"sala":"%s","curso":%d,"turma":%d,"aluno":"%s",jid":"%s","email":"%s","timestamp":%d,"action":"%s"}',
          tostring(body.room), tostring(body.courseid), tostring(body.groupid), tostring(body.context.user.name),
          tostring(stanza.attr.from), tostring(body.email), datetime, tostring(action));
        };
        req = http.request("https://teste-lua-jitsi.free.beeceptor.com/my/api/path",options,response_check());
        return true;
      else
        log("error","Presence logger - Failed to decode JWT - Second part");
      end
    else
      log("error","Presence logger - Failed to decode JWT - First part");
    end;
  else
    if stanza.attr.to:find("focus") then
      log("info", "Presence logger - Jicofo starting room: %s", tostring(stanza.attr.to));
    else
      log("info", "Presence logger - No token available in session: %s for user: %s ",
      tostring(stanza.attr.to), tostring(stanza.attr.from));
    end;
  end;
  -- JWT + req magic
end
-- main guy


-- hooks
module:hook("muc-occupant-joined", function(event)
local origin, stanza, action, datetime = event.origin, event.stanza, "login", time.now();
return presence_log(origin, stanza, action, datetime);
end);

module:hook("muc-occupant-pre-leave", function(event)
local origin, room, stanza, action, datetime = event.origin, event.room, event.stanza, "logout", time.now();
return presence_log(origin, stanza, action, datetime);
end);
-- hooks
