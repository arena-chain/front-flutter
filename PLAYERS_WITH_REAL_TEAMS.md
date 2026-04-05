# Players Directory (Users + Role + Real Team)

## What you want
See in one place:
1. All **real users** in your database (with their `role`)
2. Only the **players** (optional filter: `role === 'player'`)
3. For a chosen **season**, show which **real team** each player is on

## Why we need the Season Roster
Teams do not directly store “player -> team” in a single global endpoint.
The backend stores this relationship in `SeasonRoster`:
- `SeasonRoster.teamId`
- `SeasonRoster.playerIds[]`

So the reliable way to know “player’s real team” is:
`GET /season-rosters/by-season?seasonId=...`

## Endpoints you will use

### 1) List real users (includes role)
`GET /users`

Returns: array of `User` objects (role is available as `user.role`).

### 2) List teams (for team details)
`GET /teams`
or `GET /teams/:id`

### 3) Get players grouped by team for a specific season
`GET /season-rosters/by-season?seasonId=<seasonId>`

Returns: array of `SeasonRoster` objects.
Each roster contains:
- `seasonId`
- `teamId`
- `playerIds[]`

This endpoint also **populates** `playerIds` (so the returned `playerIds` are the user objects, not only IDs).

## Recommended implementation flow

### Step 1: Pick a `seasonId`
How you pick it is up to your UI, for example:
- from `GET /seasons?leagueId=<leagueId>`

### Step 2: Fetch roster for that season
```bash
curl "$API_BASE_URL/season-rosters/by-season?seasonId=$SEASON_ID"
```

### Step 3: (Optional) Fetch all users and filter by role
If you want “all players in database”, do:
```bash
curl "$API_BASE_URL/users"
```
Filter client-side by:
- `user.role === 'player'`

### Step 4: Build the “player -> team” mapping from rosters
For each roster entry:
- `teamId = roster.teamId`
- for each `player in roster.playerIds`:
  - output `{ playerUserId: player._id, nickname: player.nickname, role: player.role, teamId }`

Then fetch team details:
```bash
curl "$API_BASE_URL/teams"
```
and join by `team._id == teamId`.

## Example JSON output shape (suggested)
```json
[
  {
    "playerUserId": "USER_ID",
    "nickname": "ShadowStrike",
    "role": "player",
    "team": { "teamId": "TEAM_ID", "name": "Team Phantom", "organizationName": "..." }
  }
]
```

## Notes / gotchas
1. A player can belong to a team depending on the selected `seasonId`.  
   If you want “current team”, you still need to choose which season you call.
2. `/users` includes **all roles** (`player`, `team_manager`, `admin`, `referee`, `scouter`), so you must filter by `role`.
3. If a player is not in any roster for the selected season, they will not appear in the “player -> team” join.

## Quick curl set (minimal)
```bash
# 1) Season roster (player -> team mapping)
curl "$API_BASE_URL/season-rosters/by-season?seasonId=$SEASON_ID"

# 2) Team details
curl "$API_BASE_URL/teams"

# 3) (Optional) users list for role filtering
curl "$API_BASE_URL/users"
```

