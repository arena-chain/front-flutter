# Scouter Feature – Full Implementation Spec

> Single reference document for implementing the scouter feature on web. Covers API, models, flows, and local fallback.

---

## 1. Overview

The scouter module lets scouts:
- **Browse players** from catalog/leaderboard
- **Create reports** on players (rating, strengths, weaknesses, notes, role)
- **Manage watchlist** (prospects: WATCHLIST, PROSPECT, ELITE_PROSPECT, SIGNED)
- **Recommend players** to organizations

---

## 2. API Base & Auth

| Item | Value |
|------|-------|
| Base URL | `http://localhost:3000` (or your backend) |
| Auth | Bearer token in `Authorization` header |
| Content-Type | `application/json` |

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

---

## 3. API Endpoints

### 3.1 Catalog & Games

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/catalog` | List games (Valorant, League of Legends, etc.) |

**Response:** `[{ "_id": "...", "title": "...", "genre": "..." }]`

---

### 3.2 Scouter Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/scouter/me/:userId` | Get scouter profile |

**Response:**
```json
{
  "_id": "...",
  "userId": "...",
  "level": "REGIONAL",
  "notes": null,
  "evaluatedPlayerIds": ["..."]
}
```

---

### 3.3 Players

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/scouter/players` | List all players |
| GET | `/api/scouter/players/:playerId` | Player detail |
| GET | `/api/scouter/players/:playerId/matches` | Player matches |
| GET | `/api/scouter/leaderboard?gameId=:gameId` | Leaderboard for a game |
| PATCH | `/api/scouter/:scouterUserId/scouted/:playerProfileId` | Add player to evaluated list |
| GET | `/api/scouting/players/filter?gameId=&tier=&country=&hasTeam=&prospectLevel=&priority=` | Filter players |

**Player Detail Response:**
```json
{
  "_id": "profile_id",
  "userId": { "_id": "user_id", "nickname": "...", "email": "...", "country": "..." },
  "elo": 1500,
  "rank": "...",
  "tier": "DIAMOND",
  "region": "...",
  "isPro": false,
  "stats": {},
  "teamId": { "_id": "...", "name": "...", "logo": "..." }
}
```

**Note:** `userId` can be a populated object or a plain string ID.

---

### 3.4 Reports

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/scouting/reports/scouter/:scouterId` | My reports |
| GET | `/api/scouting/reports/player/:playerId` | Reports for a player |
| POST | `/api/scouting/reports` | Create report |
| PATCH | `/api/scouting/reports/:id` | Update report |
| DELETE | `/api/scouting/reports/:id` | Delete report |

**Create Report Body:**
```json
{
  "scouterId": "...",
  "playerId": "...",
  "playerNickname": "Optional for local display",
  "rating": 75,
  "strengths": "...",
  "weaknesses": "...",
  "notes": "...",
  "recommendedRole": "IGL",
  "matchId": "optional"
}
```

**Report Response:**
```json
{
  "_id": "...",
  "scouterId": "...",
  "playerId": { "_id": "...", "nickname": "..." },
  "matchId": null,
  "rating": 75,
  "strengths": "...",
  "weaknesses": "...",
  "notes": "...",
  "recommendedRole": "IGL",
  "createdAt": "2026-03-02T..."
}
```

---

### 3.5 Watchlist (Prospects)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/scouting/prospects?prospectLevel=&priority=` | List prospects |
| GET | `/api/scouting/prospects/player/:playerId` | Prospect for a player |
| POST | `/api/scouting/prospects` | Add/update prospect |

**Upsert Prospect Body:**
```json
{
  "scouterId": "...",
  "playerId": "...",
  "playerNickname": "Optional for local display",
  "prospectLevel": "WATCHLIST",
  "priority": "MEDIUM"
}
```

**Prospect Levels:** `WATCHLIST` | `PROSPECT` | `ELITE_PROSPECT` | `SIGNED` | `UNKNOWN`  
**Priority:** `LOW` | `MEDIUM` | `HIGH`

**Prospect Response:**
```json
{
  "_id": "...",
  "playerId": { "_id": "...", "nickname": "..." },
  "prospectLevel": "WATCHLIST",
  "priority": "MEDIUM",
  "lastUpdated": "2026-03-02T..."
}
```

**Remove from watchlist:** Upsert with `prospectLevel: "UNKNOWN"`.

---

### 3.6 Recommendations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/scouting/recommendations/scouter/:scouterId` | My recommendations |
| GET | `/api/scouting/recommendations/player/:playerId` | Recommendations for a player |
| POST | `/api/scouting/recommendations` | Create recommendation |

**Create Body:**
```json
{
  "scouterId": "...",
  "playerId": "...",
  "organizationId": "...",
  "recommendationLevel": "CONSIDER",
  "message": "..."
}
```

**Recommendation Levels:** `CONSIDER` | `STRONGLY_RECOMMEND` | `MUST_SIGN`  
**Status:** `PENDING` | `ACCEPTED` | `REJECTED`

---

## 4. Data Models

### 4.1 ScoutingReport

| Field | Type | Notes |
|-------|------|-------|
| id | string | `_id` |
| scouterId | string | |
| playerId | string \| object | Populated: `{ _id, nickname }` |
| matchId | string? | |
| rating | number | 0–100 |
| strengths | string? | |
| weaknesses | string? | |
| notes | string? | |
| recommendedRole | string? | IGL, Duelist, Support, etc. |
| createdAt | string? | ISO 8601 |

**Helpers:** `playerNickname`, `playerIdStr` (extract from playerId).

---

### 4.2 ProspectStatus

| Field | Type | Notes |
|-------|------|-------|
| id | string | `_id` |
| playerId | string | Raw ID |
| playerIdRaw | string \| object | Populated: `{ _id, nickname }` |
| prospectLevel | string | WATCHLIST, PROSPECT, ELITE_PROSPECT, SIGNED, UNKNOWN |
| priority | string? | LOW, MEDIUM, HIGH |
| lastUpdated | string? | ISO 8601 |

**Helpers:** `playerNickname` (from playerIdRaw).

---

### 4.3 PlayerDetail

| Field | Type | Notes |
|-------|------|-------|
| id | string | Profile `_id` |
| rawUserId | string | User ID fallback |
| userId | object? | `{ _id, nickname, email, country }` |
| elo | number | |
| rank | string? | |
| tier | string? | DIAMOND, PLATINUM, etc. |
| region | string? | |
| isPro | boolean | |
| stats | object? | |
| team | object? | `{ _id, name, logo }` |

**Helper:** `effectiveUserId` = userId.id ?? rawUserId.

---

### 4.4 Recommendation

| Field | Type | Notes |
|-------|------|-------|
| id | string | |
| scouterId | string | |
| playerId | string \| object | |
| organizationId | string \| object | Populated: `{ name }` |
| recommendationLevel | string | |
| message | string? | |
| status | string | PENDING, ACCEPTED, REJECTED |
| createdAt | string? | |

---

## 5. Local Storage Fallback

When the API fails, use local storage (e.g. `localStorage` on web).

### 5.1 Reports

- **Key:** `scouting_reports`
- **Format:** JSON array of report objects
- **IDs:** Use `local_<timestamp>` for new reports
- **Delete:** Only allow delete when `id.startsWith('local_')` for local items

### 5.2 Prospects

- **Key:** `scouting_prospects`
- **Format:** JSON array of prospect objects
- **IDs:** Use `local_<timestamp>` for new prospects
- **Upsert:** Update by `playerId`; create if not found

### 5.3 Fallback Logic

```
Try API → on failure → use local storage
```

For `deleteReport`: if API fails and id starts with `local_`, delete from local storage.

---

## 6. UI Flows

### 6.1 Reports

1. **List:** Group by Today / This Week / Older
2. **Search:** By player nickname
3. **Tap report** → Report detail screen (rating, strengths, weaknesses, notes, role, date)
4. **From report detail:** "View Player" → Player profile
5. **Create report:** From player profile → form (rating, role, strengths, weaknesses, notes)
6. **Delete:** Swipe or long-press → confirm

### 6.2 Watchlist

1. **Tabs:** WATCHLIST | PROSPECT | ELITE | SIGNED
2. **Tap item** → Player profile
3. **Level menu:** Change level or remove from watchlist
4. **Add to watchlist:** From player profile → set prospect level + priority

### 6.3 Player Profile

- Header: nickname, tier, elo
- Tabs: Overview | Matches | Reports
- Actions: Create Report, Recommend, Set prospect level (watchlist)

### 6.4 Navigation Summary

| From | Tap | To |
|------|-----|-----|
| Reports list | Report card | Report detail |
| Report detail | View Player | Player profile |
| Watchlist | Prospect card | Player profile |
| Player profile | Report | Create report form |
| Player profile | Prospect level | Save to watchlist |

---

## 7. Recommended Roles (Report)

`Duelist`, `IGL`, `Support`, `Lurker`, `Rifler`, `AWPer`, `Jungler`, `Carry`, `Tank`, `Controller`, `Sentinel`, `Initiator`

---

## 8. Error Handling

- Hide raw API errors (e.g. "Cannot GET /api/...")
- Show user-friendly messages: "Unable to load", "Please try again"
- Use local fallback for reports and prospects when API fails

---

## 9. Files Reference (Flutter)

| Layer | Path |
|-------|------|
| API | `lib/core/api/feature_scouter/scouter_api.dart` |
| Models | `lib/core/models/feature_scouter/scouter_models.dart` |
| Repository | `lib/core/repositories/feature_scouter/scouter_repository.dart` |
| Local storage | `lib/core/storage/local_scouting_storage.dart` |
| Reports tab | `lib/screens/scouter/ui/scouter_reports_tab.dart` |
| Report detail | `lib/screens/scouter/ui/report_detail_screen.dart` |
| Watchlist tab | `lib/screens/scouter/ui/scouter_watchlist_tab.dart` |
| Player detail | `lib/screens/scouter/ui/scouter_player_detail_screen.dart` |
| Create report | `lib/screens/scouter/ui/create_report_bottom_sheet.dart` |
| Recommendations | `lib/screens/scouter/ui/scouter_recommendations_tab.dart` |

---

*Last updated: March 2026*
