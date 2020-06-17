# jitsi-logging-plugin

**PT-BR**

Plugin para o Prosody (Jitsi) para logging das entradas e saídas dos usuários em uma determinada sala. Utilizado para gerar uma lista de presença para ensino a distancia, e utilizado em conjunto com o plugin do Moodle, de onde vem as informações como curso. turma nome do aluno e etc, porem, e de fácil adaptação para outra "fonte" de dados, contanto que as informações cheguem via JWT.

Esse pequeno modulo age basicamente como um man in the middle, recebendo as Informações atraves do JWT, anexando o JID e as enviando para outro serviço.

**EN-US**

Plugin for Prosody (Jitsi) for logging user logins and logouts in a given room. Used to generate a presence list for distance learning, and used in conjunction with the Moodle plugin, where the Information comes from such as the course. class, student name and etc, however, the code can be easily adapted to another "source" of data, as long as the Information arrives via JWT.

This small module basically acts as a man in the middle, receiving the information through the JWT, attaching the JID and sending it to another service.

## Installation

> WARNING: WORK IN PROGRESS 

Before the install of this plugin make sure you have your Jitsi using authentication by JWT (aka secure domain).


- 1. Copy the lua file to the Jitsi Prosody plugins folder, usually `/usr/share/jitsi-meet/prosody-plugins/`.
- 2. Open `/etc/prosody/conf.d/[YOUR DOMAIN].cfg.lua`, edit the conferance.[YOUR DOMAIN] component to add **presence_logger**. Change this line `modules_enabled = { [EXISTING MODULES] }` TO `modules_enabled = { [EXISTING MODULES]; "token_moderation" }`
- 3. Restart prosody service.

Your config file shoud look like that:

```lua
--- a lot of lines above
Component "conference.jitsi.domain.tld" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "token_verification";
        "token_moderation";
        "presence_logger"; -- this plugin
    }
    admins = { "focus@auth.jitsi.domain.tld" }
    muc_room_locking = false
    muc_room_default_public_jids = true
--- a lot of lines below
```


## Usage

Include the necessary information in JWT payload.

Token body should look something like this:

```javascript
{
  "context": {
    "user": {
      "avatar": "https://domain.tld/image.jpg",
      "name": "Bryan",
      "email": "",
      "id": ""
    },
    "group": ""
  },
  "courseid": 1,
  "groupid": "2543",
  "email": "bryan@domain.tld",
  "aud": "jitsi",
  "iss": "moodle",
  "sub": "jitsi.domain.tld",
  "room": "520_1_Python_Intro",
  "exp": 1592485089,
  "moderator": true
}
```

The `context` section is main used by Jitsi as "metadata", the rest is sended by Moodle (in my case) on the JWT body to send to another service.


## TODO

- [ ] Variable URL for request
- [ ] Callback on request
- [ ] Code review
- [ ] Variable payload
- [ ] Healthcheck user (something like Speakerstats)

## Thanks

- Jitsi Team (For [Jitsi](https://github.com/jitsi/jitsi-meet) and [mod_token_verification.lua](https://github.com/jitsi/jitsi-meet/blob/master/resources/prosody-plugins/mod_token_verification.lua))

- [nvonahsen](https://github.com/nvonahsen) and [Seekerofpie](https://github.com/Seekerofpie) for [mod_token_moderation.lua](https://github.com/nvonahsen/jitsi-token-moderation-plugin)