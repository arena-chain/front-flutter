# Frontend Implementation Guide: Ranked Tournaments & Invitations

## Overview
This guide details how to implement the "Create Ranked Tournament" feature on the frontend, including friend selection for invitations.

## 1. API Integration

### Tournament Service
Ensure your `TournamentService` (or equivalent) has a method to create a tournament.

```typescript
// tournament.service.ts
import axios from 'axios';

const API_URL = 'http://localhost:3000/tournements'; // Adjust as needed

export const createTournament = async (tournamentData: FormData) => {
  const response = await axios.post(API_URL, tournamentData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};
```

### Friendship Service
You need a service to fetch the user's friends.

```typescript
// friendship.service.ts
export const getFriends = async (userId: string) => {
  const response = await axios.get(`http://localhost:3000/friendship/friends/${userId}`);
  return response.data; // Returns array of friendship objects with populated friend details
};

// Helper to extract friend user from friendship object
export const extractFriend = (friendship: any, currentUserId: string) => {
  return friendship.requesterId._id === currentUserId
    ? friendship.recipientId
    : friendship.requesterId;
};
```

## 2. Tournament Creation Form Component

### State Management
You'll need state for:
- Tournament data (name, gameId, etc.)
- `type`: Set to 'RANKED' (or allow selection).
- `invitedUserIds`: Array of selected friend IDs.
- List of available friends (fetched on mount).

### Steps

1.  **Fetch Friends**: On component mount, fetch the current user's friends.
2.  **Friend Selection UI**:
    - Display a list of friends with checkboxes or a multi-select dropdown.
    - When a friend is selected, add their ID to `invitedUserIds`.
3.  **Form Submission**:
    - Construct `FormData`.
    - Append standard fields (name, startDate, etc.).
    - Append `type` = 'RANKED'.
    - Append `invitedUserIds`. **Note**: Since `FormData` handles arrays differently, you might need to append each ID individually or stringify it if the backend expected a string (backend expects array of strings, NestJS with `multipart/form-data` can handle duplicate keys).
    - **Crucial**: NestJS `FileInterceptor` + Validation often requires array fields to be handled carefully in FormData.

    ```typescript
    const formData = new FormData();
    formData.append('name', data.name);
    // ... other fields
    formData.append('type', 'RANKED');

    // Appending array
    data.invitedUserIds.forEach((id) => {
      formData.append('invitedUserIds[]', id); // or just 'invitedUserIds' depending on your backend parser
    });
    ```
    *Backend Note*: expected `invitedUserIds` property.

## 3. Interfaces

```typescript
export enum TournamentType {
  OFFICIAL = 'OFFICIAL',
  RANKED = 'RANKED',
}

export interface CreateTournamentDto {
  name: string;
  gameId: string;
  type: TournamentType;
  invitedUserIds?: string[];
  // ... other fields
}
```

## 4. Validations
- Ensure `invitedUserIds` contains valid MongoDB ObjectIds.
- User cannot invite themselves (frontend should filter current user out of friends list, though logic handles it).

## 5. Notification Handling
- The backend will automatically create notifications for invited users.
- The invited users will see these in their notification feed (implementation depends on your Notification component).
