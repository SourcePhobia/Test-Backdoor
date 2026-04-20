# Roblox Backdoor System

A lightweight Roblox server side command execution system with external authentication, dynamic remote obfuscation, and secure Lua execution.

---

##  Features

- External authentication via HTTP
- Per-player authorization system
- Command handler (`lua`, `help`, `cmds`)
- Obfuscated RemoteFunction with auto-rebuild
- Runtime Lua execution (server-side)
- Self-healing remote instance

---

##  Structure Overview

### HTTP Module
Handles communication with your external backend.

- isAuthorized(userId)  
  Checks if a player is allowed to execute commands.

---

### Authentication Module
Tracks and validates authenticated players.

- authenticateUser(player)  
  Verifies and caches authorization.

- deauthenticateUser(player)  
  Removes player from authenticated list.

---

### Command System

#### Available Commands:

| Command | Usage | Description |
|--------|------|-------------|
| lua    | lua <script> | Executes Lua code |
| help   | help [command] | Shows help info |
| cmds   | cmds | Lists all commands |

#### Dispatch Flow:

```lua
Commands.dispatch(player, command, payload)
```

---

### Remote System

- Creates a RemoteFunction with a randomized Unicode name
- Automatically rebuilds if:
  - Deleted
  - Parent changes
- Helps prevent tampering

#### Key Methods:

- Remote.new(parent)
- Remote:get()
- Remote:destroy()

---

##  How It Works

1. Server starts and initializes:
   - RemoteFunction
   - Player hooks

2. When a player joins:
   - Authentication check is performed via API

3. Client invokes remote:
   - Command is dispatched
   - Authorization is verified
   - Command executes

---

##  API Endpoints

Base URL:
https://webhost-production.up.railway.app

### Endpoints:

- /authenticate?userId=<id>  
  Returns:
  { "authorized": true }

- /init?placeId=<placeId>&jobId=<jobId>  
  Used for server initialization

---

##  Security Notes

- Executing Lua from users is dangerous
- Only allow trusted users
- Validate everything server-side
- Remote obfuscation is not real security

---

##  Dependencies

Roblox services used:
- Players
- ReplicatedStorage
- HttpService

---

##  Setup

1. Enable HTTP Requests in Roblox  
   Game Settings → Security → Allow HTTP Requests

2. Deploy your backend

3. Insert the script into a ServerScript

---

##  Example Usage

```lua
local remote = ReplicatedStorage:FindFirstChildOfClass("RemoteFunction")

local result = remote:InvokeServer("lua", "return 2 + 2")
print(result) -- 4 (if authorized)
```

---

## License

This backdoor system is proprietary software. Any unauthorized modification, distribution, or use is strictly prohibited and may result in legal action.

**Created by:** SourcePhobia  
**Version:** 1.0.0  
**License:** Non-modifiable

## Support

For any issues or questions regarding the `Test-Backdoor` script, please reach out to the author: **SourcePhobia**.

<p align="center">
        <img src="https://raw.githubusercontent.com/mayhemantt/mayhemantt/Update/svg/Bottom.svg" alt="Github Stats" />
</p>
