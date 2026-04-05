# Scouter: Player Profile + Highlights + History (Mobile/Frontend Integration)

## What this screen should show
For a given **playerUserId**, a scouter can view:
1. Player profile data (elo, rank, stats, Riot link status)
2. Player match history
3. Player highlights (video clips)
4. Scouting data related to that player (reports, prospect status, recommendations, watchlist)
5. Optional: rank history / progression

## Base URL
Backend REST base URL (default used in the Electron app):
`http://localhost:3000/api`

In all examples below, append paths like `/player/...`.

## Required identifiers
1. `playerUserId`: the `User._id` for the player (not the scouter profile id)
2. `scouterUserId`: the `User._id` for the current scouter (needed for scouter-specific actions like watchlist check)

## Endpoints (Backend)

### 1) Player profile (stats)
`GET /scouter/players/:playerUserId`

Returns the `PlayerProfile` document fields such as:
- `userId`, `elo`, `rank`, `stats`, `riotLinkStatus`, `riotPuuid`, `riotGameName`, etc.

**Important:** this endpoint does *not* return `nickname/avatar/country`.
To get those, use either `GET /scouter/players` (list) or scouting endpoints that populate `playerId` with identity fields.

### 2) Player match history
`GET /scouter/players/:playerUserId/matches`

Returns an array of `Match` documents relevant to the player.
Backend logic:
- Finds the seasons/teams where the player appears via `SeasonRoster`
- Fetches matches for those seasons
- Filters matches where `team1Id == roster.teamId` or `team2Id == roster.teamId`

Notes for UI:
- Each match has `scheduledStart`, `status`, `team1Id`, `team2Id`, `games[]`, etc.
- Team names are not included by this endpoint; you may show raw ids or resolve team names separately.

### 3) Player highlights (video clips) - available via `/highlights`
Backend highlights are stored as:
- `Highlight.video` (populated with `title/url/thumbnailUrl/duration`)
- `Highlight.creator` (a `User`)

However, there is **no endpoint** like `GET /highlights?creatorId=...`.

So the integration pattern is:
1. `GET /highlights`
2. Filter client-side where `highlight.creator` matches `playerUserId`
   - Since the controller does `populate('creator', ...)` with `username/email/avatar`, the response typically includes `highlight.creator._id`.

Endpoints:
- `GET /highlights`
- `GET /highlights/video/:videoId` (optional)

Client-side filtering example logic:
```js
highlights.filter(h => String(h.creator?._id || h.creator) === String(playerUserId))
```

### 4) Scouting data related to the player

#### Scouting reports
`GET /scouting/reports/player/:playerId`

Populates:
- `playerId` with `nickname/email/country`
- `matchId` (if the report is linked to a match)
- `scouterId` with `nickname/email`

#### Prospect status
`GET /scouting/prospects/player/:playerId`

#### Recommendations
`GET /scouting/recommendations/player/:playerId`

#### Watchlist entries (for any scouter)
`GET /scouting/watchlist/player/:playerId`

If you only want to know whether the **current scouter** has this player in their watchlist:
- `GET /scouting/watchlist/check?scouterId=<scouterUserId>&playerId=<playerUserId>`

### 5) Optional rank progression (recommended for scouter screens)

Player ranks:
- `GET /rank/user/:userId/all` (all game ranks across the platform)

Rank history for one game:
- `GET /rank/history/:userId/:gameId?limit=50`

Notes:
- `GET /rank/me/all` exists but requires JWT (`AuthGuard('jwt')`).

## How to implement the screen (suggested request flow)

1. Identity & profile header
   - `GET /scouter/players` (list) and find the matching player by id to get `nickname/avatar/country`
   - `GET /scouter/players/:playerUserId` to get `elo/rank/stats/riotLinkStatus`

2. History tab
   - `GET /scouter/players/:playerUserId/matches`

3. Highlights tab
   - `GET /highlights`
   - filter client-side by `highlight.creator._id == playerUserId`

4. Scouting tab (data related to the player)
   - `GET /scouting/reports/player/:playerUserId`
   - `GET /scouting/prospects/player/:playerUserId`
   - `GET /scouting/recommendations/player/:playerUserId`
   - `GET /scouting/watchlist/player/:playerUserId`
   - optionally: `GET /scouting/watchlist/check?scouterId=...&playerId=...`

5. (Optional) Charts
   - `GET /rank/user/:playerUserId/all`
   - if you want a progression chart for one game: `GET /rank/history/:playerUserId/:gameId`

## CURL examples

### Player profile
```bash
curl "$API_BASE_URL/scouter/players/$PLAYER_USER_ID"
```

### Player match history
```bash
curl "$API_BASE_URL/scouter/players/$PLAYER_USER_ID/matches"
```

### Highlights (client-side filtering)
```bash
curl "$API_BASE_URL/highlights"
```

### Scouting reports
```bash
curl "$API_BASE_URL/scouting/reports/player/$PLAYER_USER_ID"
```

### Prospect status
```bash
curl "$API_BASE_URL/scouting/prospects/player/$PLAYER_USER_ID"
```

### Recommendations
```bash
curl "$API_BASE_URL/scouting/recommendations/player/$PLAYER_USER_ID"
```

### Watchlist
```bash
curl "$API_BASE_URL/scouting/watchlist/player/$PLAYER_USER_ID"
```

### Watchlist check (for a given scouter)
```bash
curl "$API_BASE_URL/scouting/watchlist/check?scouterId=$SCOUTER_USER_ID&playerId=$PLAYER_USER_ID"
```

## Backend logic notes (things you may want to improve)
1. Player highlights are not filterable server-side.
   - If you want a more efficient integration, a backend change could add: `GET /highlights?creatorId=...` (or `GET /highlights/player/:playerId`).
2. `GET /scouter/players/:playerUserId` returns profile stats but not identity fields.
   - For UI convenience, a backend change could populate user identity fields in that endpoint.

