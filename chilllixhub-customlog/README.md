# chilllixhub-customlog

Standalone FiveM logging resource for **QBCore** servers.  
Sends Discord webhook embeds and okokChat announcements for the following events:

| Event | What fires it | Discord channel | Chat |
|---|---|---|---|
| Player Connected | returning character selected | `playerActivity` webhook | "Welcome back [name]!" |
| Player Disconnected | player dropped / left | `playerActivity` webhook | – |
| New Citizen Arrived | new character created | `playerActivity` webhook | "New citizen has arrived. Welcome [name]!" |
| Player Died | `isdead` metadata set to `true` | `playerDeath` webhook | – |
| Job Changed | job / grade actually changed | `jobActivity` webhook | – |

---

## Setup

### 1. Fill in your webhooks (`config.lua`)

```lua
Config.Webhooks = {
    playerActivity = 'https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN',
    playerDeath    = 'https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN',
    jobActivity    = 'https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN',
}
```

> **Tip:** `playerDeath` and `jobActivity` can point to the **same** URL if you want all logs in one channel.  
> Add more keys to `Config.Webhooks` and update `Config.LogWebhooks` if you want more separation.

### 2. Add to `server.cfg` in the correct order

```cfg
ensure qb-core
ensure qb-multicharacter
# ... other resources ...
ensure chilllixhub-customlog
```

`chilllixhub-customlog` must start **after** `qb-core` and `qb-multicharacter`.

---

## Do I need to restart the whole server?

**No.** You only need to start this one resource.

### Option A — Add it to `server.cfg` (recommended)

Add `ensure chilllixhub-customlog` after `qb-multicharacter` in your `server.cfg`.  
The resource will then auto-start with the server every time.  
A **full server restart** is only needed the very first time if you choose this option.

### Option B — Live start without restarting (txAdmin / server console)

If the server is already running you can start the resource live:

```
start chilllixhub-customlog
```

or use the txAdmin **Resources** tab → click **Start**.

> **Important:** when started live the resource will begin logging from that moment.  
> Any players who are already online when you start it will have their job cached  
> correctly because the resource reads from `QBCore.Functions.GetPlayer` on the  
> next event that fires for them (e.g., job change).  
> Players who connect *after* you start the resource will be fully logged.

---

## Optional — okokChat integration

If `okokChat` is running, connection and new-citizen events are automatically  
broadcast as server chat messages.  If `okokChat` is **not** running the resource  
skips chat announcements silently — no errors.

---

## Optional — External death cause reporting

Other resources (e.g. `qb-ambulancejob`) can provide a more detailed death  
cause by triggering the server event directly:

```lua
TriggerServerEvent('chilllixhub-customlog:server:playerDied', 'GSW to the head')
```
