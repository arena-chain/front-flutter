# ArenaChain Player Leagues (Mobile Integration Doc)

## Goal
Show a mobile/player screen where users can browse:
1. **Leagues**
2. **Matches** for a selected season (scheduled/ongoing/completed)
3. **“Rest”** (league table) => this is implemented by **standings**

## Base URL
Backend REST base URL is:
`http://localhost:3000/api`

In production, change the base URL in your mobile app configuration (example keys: `API_BASE_URL`).

## Authentication (when needed)
The endpoints below are mostly public.

Use JWT only if you want **“my leagues”** (player registered leagues):
- `GET /leagues/my-registrations` **requires** `Authorization: Bearer <accessToken>`

Header format:
`Authorization: Bearer <accessToken>`

> The other endpoints (`/leagues`, `/seasons`, `/matches`, `/standings`) do not require auth in the current backend controllers.

## Endpoints to call

### 1) List all leagues
`GET /leagues`

Response: array of `League`

### 2) List seasons for a league
`GET /seasons?leagueId=<leagueId>`

Response: array of `Season`

### 3) List matches for a season
Use the matches controller filtering via query parameters:

`GET /matches?seasonId=<seasonId>[&status=<status>][&from=<ISODateOrYYYY-MM-DD>]`

Useful `status` values:
- `SCHEDULED`
- `ONGOING`
- `COMPLETED`
- `FORFEIT`
- `CANCELLED`

Response: array of `Match`

### 4) “Rest” / league table (standings)
`GET /standings?seasonId=<seasonId>[&stageId=<stageId>][&groupId=<groupId>]`

Response: array of `Standings` rows, each one contains `rank`, `points`, wins/losses, etc.

## Data mapping (what to display)

### League card fields (suggested)
- `_id` (leagueId)
- `name`
- `gameId` (or resolve game name client-side if you already have catalog)
- `level` (INTERNATIONAL / CONTINENTAL / NATIONAL / REGIONAL)
- `regionFilter` + `regionValue`
- `status` (UPCOMING / ONGOING / FINISHED)

### Season detail fields
- `_id` (seasonId)
- `name`
- `startDate`, `endDate`, `registrationDeadline`
- `status` (PLANNED / ONGOING / FINISHED)

### Match list fields
- `_id` (matchId)
- `scheduledStart` (display as date/time)
- `status`
- `team1Id`, `team2Id` (resolve team names client-side if your UI needs names)
- `team1GamesWon`, `team2GamesWon` (when match is completed/forfeit)
- `games[]` (per-map/game results, fields depend on the backend submission)

### “Rest” / standings table fields
Each row includes:
- `rank`
- `teamId`
- `played`, `wins`, `draws`, `losses`, `forfeits`
- `points`
- `scoreFor`, `scoreAgainst`, `gameDiff` (tiebreakers)

## Example requests

### Fetch leagues
```bash
curl "$API_BASE_URL/leagues"
```

### Fetch your registered leagues
```bash
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$API_BASE_URL/leagues/my-registrations"
```

### Fetch seasons for a league
```bash
curl "$API_BASE_URL/seasons?leagueId=$LEAGUE_ID"
```

### Fetch matches for a season (upcoming)
```bash
curl "$API_BASE_URL/matches?seasonId=$SEASON_ID&status=SCHEDULED"
```

### Fetch “rest” (standings)
```bash
curl "$API_BASE_URL/standings?seasonId=$SEASON_ID"
```

## Client requirements (what the mobile app must have)
1. **API base URL config** (mobile environment: dev/staging/prod)
2. **JWT storage** (only needed for `/leagues/my-registrations`)
3. **Date parsing** for `scheduledStart`, `startDate`, `endDate`, etc. (treat them as ISO strings)
4. Optional: **team name resolution** (because matches/standings reference teams by `teamId`)

## Suggested UI flow
1. Load leagues (`GET /leagues` or `/leagues/my-registrations`)
2. When user selects a league, load seasons (`GET /seasons?leagueId=...`)
3. When user selects a season:
   - load matches (`GET /matches?seasonId=...`)
   - load standings (`GET /standings?seasonId=...`)
4. Render:
   - tabs: “Matches” / “Rest”
   - optionally filter matches by `status`

