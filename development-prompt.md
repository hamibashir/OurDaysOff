# Our Days Off — Complete Development Prompt

## 1. Role

You are the lead full-stack engineer responsible for designing and implementing **Our Days Off**, a privacy-first schedule matching and social coordination web application.

Build the application as a production-quality system, not a prototype or throwaway demo.

The initial client is a **Next.js web/PWA application**, but the backend must be designed as a **frontend-independent REST API** so that a future **Flutter mobile application** can use the exact same backend without requiring major architectural changes.

---

# 2. Product Overview

**Our Days Off** helps friends, families, coworkers, and shift-based teams find suitable times to meet when everyone has different schedules.

Users maintain their private schedules.

The system calculates derived availability.

Users can create private circles and compare availability without unnecessarily exposing private work information.

The core product flow is:

```text
Personal Schedule
        ↓
Availability Calculation
        ↓
Private Circle
        ↓
Schedule Comparison
        ↓
Common Free Time
        ↓
Meet Suggestions
        ↓
Poll / Plan
        ↓
RSVP
        ↓
Calendar Export
```

The most important principle is:

> Raw personal schedules remain private. Circles should consume only the minimum availability information required by their configured privacy rules.

---

# 3. Required Technology Stack

## Frontend

Use:

* Next.js
* TypeScript
* App Router
* Tailwind CSS
* shadcn/ui
* Responsive design
* PWA support
* Service Worker
* IndexedDB for selected offline data

Do NOT replace Next.js with React-only, Vue, Angular, Svelte, or another framework.

Do NOT replace Tailwind/shadcn/ui with another UI system.

---

# 4. Backend

Use:

* PHP 8.2+
* Laravel
* REST API
* Laravel Sanctum
* Laravel Eloquent ORM
* Laravel Form Requests
* Laravel Policies/Gates
* Laravel Services/Actions
* Laravel migrations
* Laravel queues where required
* Laravel rate limiting

The backend must be completely independent from the Next.js frontend.

Do not put business-critical logic only inside Next.js.

---

# 5. Database

Use:

* MySQL 8+ or compatible MariaDB supported by the hosting environment.

Use Laravel migrations for the entire database schema.

Do NOT use Supabase.

Do NOT introduce PostgreSQL unless explicitly instructed.

Do NOT create unnecessary tables or database functions.

Target approximately 12–16 core tables initially.

---

# 6. Hosting Target

The application must be designed to work with a typical cPanel hosting environment.

Expected deployment:

```text
Frontend
Next.js
      ↓
Static export where required
      ↓
cPanel hosting

Backend
Laravel/PHP
      ↓
MySQL
```

The architecture must support two frontend deployment modes:

### Preferred

Next.js static export when the cPanel environment does not support a persistent Node.js server.

### Optional

Next.js Node.js deployment if the hosting provider supports it.

Do not make the backend dependent on Next.js server-side execution.

The Laravel API should work independently through:

```text
https://api.example.com/api/v1/...
```

or an equivalent `/api/v1` deployment.

---

# 7. Architecture Principle

Use this architecture:

```text
                    Our Days Off
                         │
              ┌──────────┴──────────┐
              │                     │
          Next.js Web           Future Flutter
              │                     │
              └──────────┬──────────┘
                         │
                     REST API
                         │
                      Laravel
                         │
              ┌──────────┼──────────┐
              │          │          │
            MySQL      OpenAI     Storage
              │
              ▼
      Availability Engine
              │
       ┌──────┼───────┐
       ▼      ▼       ▼
    Circles  Plans   Activity
```

The API is the contract between clients and the backend.

---

# 8. Future Flutter Requirement

This is mandatory.

Do not design anything specifically around browser behavior.

Every important feature must be available through the REST API.

The future Flutter client should be able to perform:

```text
Authentication
Profile management
Schedule CRUD
Shift templates
Availability
Circle management
Circle membership
Invitations
Plans
Polls
Locations
Votes
RSVPs
Activity
Devices
Notifications
```

without requiring Next.js.

Avoid returning frontend-specific HTML or UI structures from Laravel.

Return clean JSON resources.

Example:

```json
{
  "data": {
    "id": 123,
    "title": "Dinner",
    "start_at": "2026-10-10T18:00:00+05:00",
    "end_at": "2026-10-10T21:00:00+05:00",
    "timezone": "Asia/Karachi"
  }
}
```

---

# 9. Development Philosophy

Follow these rules throughout the project:

1. Keep the architecture simple.
2. Avoid premature abstraction.
3. Avoid unnecessary dependencies.
4. Do not create duplicate representations of the same data.
5. Keep raw schedule data as the source of truth.
6. Derive availability from schedules.
7. Keep availability calculations deterministic.
8. Enforce security on the backend.
9. Never trust frontend authorization.
10. Never expose secret API keys to the frontend.
11. Write reusable services rather than giant controllers.
12. Use migrations rather than manually modifying the database.
13. Write tests for business-critical scheduling logic.
14. Keep the API stable and documented.
15. Do not introduce features that are not required by the specification.

---

# 10. Core Database Model

Start with the following tables.

## users

Laravel authentication user.

Fields:

```text
id
name
email
password
timezone
handle
handle_visibility
created_at
updated_at
```

---

## user_devices

For future multi-device support.

```text
id
user_id
device_name
device_type
device_identifier
last_seen_at
created_at
updated_at
```

Do not store unnecessary device information.

---

## shift_templates

Reusable shift definitions.

```text
id
user_id
name
start_time
end_time
is_overnight
color
created_at
updated_at
```

Examples:

```text
Early
Late
Night
Standby
Off
```

Users can create their own templates.

---

## schedule_entries

This is the primary source of truth.

```text
id
user_id
shift_template_id nullable
date
start_time
end_time
timezone
entry_type
label nullable
notes nullable
is_overnight
source
created_at
updated_at
```

Possible `entry_type`:

```text
work
personal
leave
off
other
```

Do not create a separate `days_off` source-of-truth table.

Days off should be derived from schedule information.

---

## availability_overrides

For manual availability changes.

```text
id
user_id
date
start_time
end_time
status
reason nullable
created_at
updated_at
```

Possible status:

```text
available
unavailable
```

---

## circles

```text
id
owner_id
name
handle nullable
discoverability
created_at
updated_at
```

Discoverability:

```text
private
searchable
```

---

## circle_members

```text
id
circle_id
user_id
role
member_type
visibility
status
joined_at
created_at
updated_at
```

Role:

```text
owner
admin
member
```

Member type:

```text
working
viewer
```

Visibility:

```text
free_busy
shifts
details
```

Status:

```text
pending
active
removed
```

---

## circle_invites

```text
id
circle_id
created_by
invite_code
expires_at
max_uses nullable
uses
created_at
```

Support invite links and QR-code-compatible invite codes.

---

## plans

A finalized or active meetup/event.

```text
id
circle_id
created_by
title
description nullable
event_type
start_at
end_at
timezone
status
created_at
updated_at
```

Event types:

```text
social
meal
travel
other
```

Status:

```text
draft
polling
confirmed
cancelled
completed
```

---

## plan_members

```text
id
plan_id
user_id
rsvp_status
responded_at nullable
created_at
updated_at
```

RSVP:

```text
attending
tentative
declined
pending
```

---

## plan_options

For date/time polls.

```text
id
plan_id
start_at
end_at
timezone
created_at
```

---

## plan_locations

```text
id
plan_id
name
address nullable
latitude nullable
longitude nullable
notes nullable
created_by
created_at
```

---

## plan_location_votes

```text
id
plan_location_id
user_id
created_at
```

Prevent duplicate votes through a database constraint.

---

## activity_events

Generic circle activity feed.

```text
id
circle_id
actor_id
event_type
entity_type
entity_id nullable
metadata JSON nullable
created_at
```

Examples:

```text
member_joined
schedule_updated
poll_created
poll_vote_added
plan_created
rsvp_updated
location_added
```

---

## notifications

Keep this simple initially.

```text
id
user_id
type
title
body
data JSON nullable
read_at nullable
created_at
```

---

# 11. Availability Engine

This is the core business logic.

Implement it independently from controllers.

Suggested structure:

```text
app/
└── Domain/
    └── Availability/
        ├── AvailabilityEngine.php
        ├── IntervalCalculator.php
        ├── ShiftCalculator.php
        ├── RecoveryCalculator.php
        ├── BufferCalculator.php
        ├── MealWindowCalculator.php
        ├── AvailabilityMatcher.php
        └── AvailabilityRanker.php
```

The engine must be deterministic.

Input:

```text
schedule entries
date range
recovery rules
travel buffers
meal rules
manual overrides
preferences
```

Output:

```text
availability intervals
```

Example:

```json
{
  "date": "2026-10-10",
  "blocks": [
    {
      "start": "10:00",
      "end": "17:00",
      "status": "available"
    }
  ]
}
```

---

# 12. Overnight Shift Handling

Correctly support:

```text
22:00 → 06:00
```

This means the shift starts on one calendar date and finishes on the next.

Never incorrectly treat it as:

```text
06:00 → 22:00
```

All interval calculations must account for date boundaries.

---

# 13. Recovery Rules

Allow configurable post-shift recovery.

Example:

```text
Night Shift
22:00 → 06:00

Recovery:
8 hours

Unavailable until:
14:00
```

Recovery should be calculated automatically but must be configurable.

Do not hardcode assumptions such as everyone needing the same recovery period.

---

# 14. Travel Buffers

Allow users to configure a buffer before/after work.

Example:

```text
Travel before work: 30 min
Travel after work: 45 min
```

The engine should expand busy intervals accordingly.

---

# 15. Meal Windows

Support optional preferences:

```text
Breakfast
00:00 → 12:00

Lunch
12:00 → 16:00

Dinner
16:00 → 24:00
```

Do not make meal windows mandatory.

They should influence ranking/preferences rather than arbitrarily mark a user unavailable unless explicitly configured.

---

# 16. Manual Availability Overrides

Manual overrides take precedence over automatically derived availability.

Example:

```text
Automatically free:
14:00 → 18:00

User override:
16:00 → 17:00 unavailable
```

Final:

```text
14:00 → 16:00 available
16:00 → 17:00 unavailable
17:00 → 18:00 available
```

---

# 17. Circle Privacy

This is a critical security requirement.

A user can have one private schedule and belong to multiple circles.

Example:

```text
Private Schedule
       │
       ├── Family
       ├── Friends
       └── Work Team
```

Do not duplicate schedules for each circle.

Each circle has its own visibility setting.

---

# 18. Visibility Levels

## Free/Busy

Members see:

```text
Available
Busy
```

but not the reason.

## Shifts

Members see:

```text
Work
22:00 → 06:00
```

but not private notes or custom details.

## Details

Members may see:

```text
Night Shift
22:00 → 06:00
Notes...
```

Backend authorization must enforce these levels.

Never rely on frontend hiding.

---

# 19. Working vs Viewer

Working members participate in availability calculations.

Viewer members do not affect:

```text
Everyone Free
```

calculations.

Viewers can:

```text
view plans
view discussions
RSVP if appropriate
```

but do not automatically become required participants in scheduling calculations.

---

# 20. Common Availability

Implement:

```text
findCommonAvailability()
```

It should accept availability intervals from multiple users and return intersections.

Example:

```text
Person A:
10:00–18:00

Person B:
13:00–20:00

Person C:
15:00–19:00

Result:
15:00–18:00
```

---

# 21. Meet Suggestions

Implement a ranking system.

Consider:

```text
number of available working members
duration
preferred time
meal preferences
travel buffers
user preferences
```

Do not expose an arbitrary numerical score to users.

Instead show human-readable reasons:

```text
Great time for everyone
3 members available
3-hour window
```

---

# 22. Magic Hour

"Magic Hour" is a derived UX concept, not a database entity.

It represents an especially suitable overlapping availability window.

Implement it through the availability ranking service.

Do not create a `magic_hours` table.

---

# 23. Personal Compare Sets

Initially keep compare sets client-side.

A user should be able to temporarily select:

```text
Alice
Bob
Charlie
```

and compare their availability without creating a circle.

Do not persist compare sets unless required later.

---

# 24. AI Rota Import

Support:

```text
Image
PDF
Excel
Manual
```

But all importers must produce the same normalized structure.

Architecture:

```text
Image
PDF
Excel
Manual
  │
  ▼
NormalizedScheduleEntry[]
  │
  ▼
Validation
  │
  ▼
Preview
  │
  ▼
User Confirmation
  │
  ▼
Database
```

Never:

```text
AI → Database
```

without user review.

---

# 25. AI API

Use Laravel as the secure intermediary.

```text
Next.js
   ↓
POST /api/v1/imports/rota
   ↓
Laravel
   ↓
OpenAI
   ↓
Structured JSON
   ↓
Validation
   ↓
Preview
```

The OpenAI API key must only exist on the backend.

Never expose it to the browser.

Do not hardcode the model name throughout the application.

Store configurable AI model settings in environment/configuration.

---

# 26. Import Validation

Before inserting imported schedules, check:

```text
valid date
valid time
overnight validity
duplicate entries
overlapping entries
existing manual entries
missing fields
invalid shift labels
```

Display a preview:

```text
Date       Shift       Start    End
-------------------------------------
Oct 05     Early       07:00    15:00
Oct 06     Late        15:00    23:00
Oct 07     Night       22:00    06:00
```

Allow the user to edit entries before confirmation.

---

# 27. API Design

Use:

```text
/api/v1
```

Organize routes:

```text
/api/v1/auth
/api/v1/profile

/api/v1/schedules
/api/v1/shift-templates
/api/v1/availability

/api/v1/circles
/api/v1/circles/{circle}

/api/v1/invites

/api/v1/plans
/api/v1/plans/{plan}/rsvp
/api/v1/plans/{plan}/locations
/api/v1/plans/{plan}/votes

/api/v1/imports
/api/v1/devices
/api/v1/notifications
```

Use consistent JSON responses.

---

# 28. Laravel Architecture

Avoid fat controllers.

Use:

```text
Controller
   ↓
Form Request
   ↓
Service / Action
   ↓
Model / Repository where useful
   ↓
Database
```

Example:

```text
ScheduleController
      ↓
CreateScheduleEntryAction
      ↓
ScheduleEntry
```

For complex logic:

```text
AvailabilityController
      ↓
AvailabilityService
      ↓
AvailabilityEngine
```

---

# 29. Authentication

Use Laravel Sanctum.

Support initially:

* registration
* login
* logout
* current user
* session/token management
* password reset if using passwords

Design the API so authentication can later support mobile clients.

Do not create a custom authentication system unnecessarily.

---

# 30. Device Management

Support:

```text
device name
device type
last seen
revoke device
```

Future Flutter devices should be supported without database changes.

Device pairing can use short-lived 6-character codes.

Requirements:

```text
single use
expiration
rate limiting
server-side validation
```

The pairing code is not itself an authentication credential.

---

# 31. Handles

Allow optional public handles:

```text
@hamza
```

Requirements:

```text
unique
case-insensitive
validated
reserved-word protection
```

Do not expose private profile information through handle search.

---

# 32. Circle Discovery

Support:

```text
private
searchable
```

Private circles should only be joinable through invitations.

Searchable circles can expose minimal public information.

Joining should require appropriate approval/authorization.

---

# 33. Invitations

Support:

```text
invite link
invite code
QR-compatible code
```

Do not require QR generation as a backend feature initially.

A frontend can render the invite URL as a QR code later.

---

# 34. Plans

A plan represents a real event.

Example:

```text
Dinner
Saturday
7:00 PM
Restaurant XYZ
```

Support:

```text
title
description
event type
date/time
timezone
location
members
RSVP
status
```

---

# 35. Polls

Allow a plan to have multiple date/time options.

Members vote:

```text
Yes
Maybe
No
```

Prevent duplicate votes.

Show aggregate results.

Allow creator/admin to convert a selected option into the confirmed plan time.

---

# 36. Location Voting

Allow multiple location options.

Example:

```text
Restaurant A
Restaurant B
Restaurant C
```

Members can vote.

Prevent duplicate votes.

Allow creator/admin to select the final location.

---

# 37. Activity Feed

Create generic activity events.

Examples:

```text
Hamza created a plan
Ali RSVP'd
Sara added a location
Ahmed voted
```

Do not store duplicate activity data that can already be derived from primary entities unless required for historical audit purposes.

---

# 38. Notifications

Build a basic notification abstraction.

Potential notification types:

```text
circle_invite
plan_created
poll_created
rsvp_changed
location_vote
plan_updated
```

Initially support in-app notifications.

Email/push notifications can be added later.

Do not introduce an external notification service unless required.

---

# 39. Realtime

Do not build WebSockets initially.

Use API refresh/polling where necessary.

For example:

```text
circle activity
poll results
RSVP updates
```

can refresh when the user opens the screen or periodically.

Design the code so realtime can be added later.

---

# 40. Offline Support

Implement PWA functionality.

Use:

```text
Service Worker
IndexedDB
```

Cache:

```text
application assets
recent schedule
recent availability
upcoming plans
basic circle data
```

Do not blindly cache sensitive API responses forever.

Clear private local data on logout where appropriate.

---

# 41. Calendar Export

Implement client-side `.ics` generation.

The backend should provide the finalized event information.

The frontend generates:

```text
VEVENT
DTSTART
DTEND
SUMMARY
DESCRIPTION
LOCATION
UID
```

Correctly handle time zones and daylight-saving rules.

Do not permanently convert local event times to UTC and then lose the original timezone context.

Store:

```text
start_at
end_at
timezone
```

---

# 42. Frontend Architecture

Use feature-oriented organization:

```text
frontend/
├── app/
├── components/
├── features/
│   ├── auth/
│   ├── schedule/
│   ├── availability/
│   ├── circles/
│   ├── plans/
│   ├── profile/
│   └── notifications/
├── lib/
├── hooks/
├── services/
├── types/
└── public/
```

Avoid putting everything in:

```text
app/page.tsx
```

---

# 43. API Client

Create a centralized API client.

Example conceptual API:

```text
api.get()
api.post()
api.put()
api.patch()
api.delete()
```

Handle:

```text
authentication
errors
JSON parsing
timeouts
401
403
422
429
500
```

Do not scatter raw `fetch()` calls throughout components.

---

# 44. TypeScript Types

Create types corresponding to API resources:

```text
User
Device
ShiftTemplate
ScheduleEntry
AvailabilityBlock
Circle
CircleMember
Invite
Plan
PlanOption
PlanLocation
Notification
ActivityEvent
```

Keep API response types separate from UI-specific types where useful.

---

# 45. UI Design

Use:

* Next.js
* Tailwind
* shadcn/ui

Create a polished, modern scheduling application.

Prioritize:

```text
clarity
readability
spacing
responsive layout
accessibility
fast interactions
```

Do not make the interface visually generic or look like an admin dashboard.

The product should feel like a consumer scheduling/social application.

Avoid unnecessary decorative elements.

Do not use:

* neon green accents
* green glowing borders
* excessive gradients
* decorative monospace fonts
* excessive icon-only controls
* rocket emojis
* lightning-bolt emojis
* generic "AI SaaS" visual patterns
* eyebrow text
* unnecessary badges everywhere

Use icons only when they improve comprehension.

---

# 46. Core Screens

Build these screens:

## Authentication

```text
Login
Register
Forgot Password
```

## Main

```text
Dashboard
```

Dashboard should show:

```text
next days off
upcoming plans
best upcoming availability
circle activity
```

---

## Schedule

```text
Schedule Calendar
Day View
Schedule Entry
Shift Templates
Import Rota
Availability Preview
```

---

## Circles

```text
My Circles
Create Circle
Join Circle
Circle Details
Members
Circle Availability
Circle Activity
```

---

## Compare

```text
Select People
Date Range
Availability Comparison
Suggested Times
```

---

## Plans

```text
Plans
Plan Details
Create Plan
Date Poll
Location Voting
RSVP
```

---

## Profile

```text
Profile
Handle
Privacy
Devices
Account Settings
```

---

# 47. Dashboard UX

The dashboard should answer the user's main question immediately:

> "When can I actually meet people?"

Show:

```text
Next available windows
Upcoming plans
Recent circles
Schedule status
```

Avoid overwhelming the user with raw schedule data.

---

# 48. Schedule UX

Make schedule entry extremely fast.

User should be able to:

```text
tap date
choose shift
save
```

Support templates.

Example:

```text
Early
07:00–15:00

Late
15:00–23:00

Night
22:00–06:00
```

---

# 49. Responsive Design

Must work well on:

```text
mobile browser
tablet
desktop
```

The future Flutter app will handle native mobile UX separately.

Do not attempt to make the Next.js UI identical to Flutter.

Keep the backend/API identical.

---

# 50. Accessibility

Follow reasonable WCAG practices.

Include:

```text
keyboard navigation
focus states
semantic HTML
accessible labels
sufficient contrast
screen-reader-friendly controls
```

Do not use color as the only indication of availability.

For example:

```text
Available
Busy
Tentative
```

should have text labels in addition to visual indicators.

---

# 51. Error Handling

Backend:

```text
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Validation Error
429 Rate Limited
500 Server Error
```

Return consistent JSON.

Frontend should convert technical errors into useful user-facing messages.

Never show raw SQL/PHP errors to users.

---

# 52. Security

Implement:

```text
authentication
authorization
RLS-equivalent Laravel Policies
CSRF protection where applicable
CORS restrictions
rate limiting
input validation
output filtering
secure password hashing
secure file validation
upload size limits
MIME validation
API authentication
```

Never trust:

```text
user_id
circle_id
role
visibility
member_type
```

sent by the client.

Derive permissions from authenticated server-side relationships.

---

# 53. File Upload Security

For rota uploads:

```text
allow only expected formats
validate MIME
limit size
randomize stored filename
store outside executable PHP paths where possible
delete temporary files
```

Never execute uploaded files.

---

# 54. AI Security

Never send unnecessary personal information to the AI service.

Only send the document/image required for extraction.

Never send:

```text
password
session token
private authentication information
unrelated profile information
```

Keep OpenAI credentials server-side.

---

# 55. Database Integrity

Add appropriate:

```text
foreign keys
unique constraints
indexes
check constraints where supported
timestamps
```

Important indexes:

```text
schedule_entries(user_id, date)
circle_members(circle_id, user_id)
plan_members(plan_id, user_id)
plan_locations(plan_id)
notifications(user_id, read_at)
activity_events(circle_id, created_at)
```

Prevent duplicate memberships and votes at the database level.

---

# 56. Timezone Strategy

Timezone handling is extremely important.

Every user should have a default timezone.

Example:

```text
Asia/Karachi
```

Schedules should retain the relevant timezone.

Events should retain:

```text
start_at
end_at
timezone
```

The API should use ISO 8601 representations.

Never assume the server's timezone equals the user's timezone.

---

# 57. Testing

Write automated tests for the availability engine.

At minimum test:

```text
normal shift
overnight shift
midnight boundary
multiple shifts
overlapping shifts
recovery
travel buffer
manual override
timezone
DST transition
meal preferences
multiple users
zero overlap
full-day availability
```

Also test:

```text
circle privacy
circle membership
working/viewer behavior
plan permissions
RSVP permissions
duplicate votes
invite expiration
device revocation
```

---

# 58. Availability Test Example

Input:

```text
User A:
07:00–15:00

User B:
13:00–21:00

User C:
15:00–19:00
```

Expected overlap:

```text
15:00–19:00
```

The test must verify this exact interval.

---

# 59. API Documentation

Create API documentation from the beginning.

Document:

```text
endpoint
method
authentication
request body
response
validation errors
permissions
```

Use OpenAPI/Swagger if practical.

The API documentation will become the contract for the future Flutter application.

---

# 60. Environment Variables

Never hardcode secrets.

Example:

```text
APP_ENV
APP_KEY
APP_URL

DB_HOST
DB_PORT
DB_DATABASE
DB_USERNAME
DB_PASSWORD

SANCTUM_STATEFUL_DOMAINS

OPENAI_API_KEY
OPENAI_MODEL

FRONTEND_URL
```

Use `.env.example`.

Never commit `.env`.

---

# 61. Development Phases

Build in phases.

## Phase 1 — Foundation

Implement:

```text
Laravel project
Next.js project
MySQL
authentication
API structure
database migrations
basic UI shell
```

---

## Phase 2 — Schedule System

Implement:

```text
shift templates
schedule entries
calendar
manual schedule management
timezone support
```

---

## Phase 3 — Availability Engine

Implement:

```text
interval calculations
overnight shifts
recovery
buffers
overrides
common availability
tests
```

This is a critical milestone.

---

## Phase 4 — Circles

Implement:

```text
create circle
join circle
invite
members
working/viewer
privacy levels
```

---

## Phase 5 — Matching

Implement:

```text
circle availability
personal compare
suggested windows
ranking
Magic Hour
```

---

## Phase 6 — Plans

Implement:

```text
create plan
RSVP
date polls
location options
location votes
activity feed
```

---

## Phase 7 — AI Import

Implement:

```text
image import
PDF import
Excel import
AI extraction
validation
preview
confirmation
```

---

## Phase 8 — PWA

Implement:

```text
manifest
service worker
IndexedDB
offline viewing
cache strategy
```

---

## Phase 9 — Devices & Notifications

Implement:

```text
device management
device revocation
notifications
```

---

## Phase 10 — Production Hardening

Perform:

```text
security review
API review
database indexes
performance testing
responsive testing
accessibility review
deployment documentation
```

---

# 62. Development Order

Do NOT build all screens simultaneously.

Follow this order:

```text
1. Backend foundation
2. Database
3. Authentication
4. Schedule API
5. Availability engine
6. Availability tests
7. Next.js schedule UI
8. Circles
9. Matching
10. Plans
11. Polls
12. AI import
13. Offline
14. Notifications
15. Production hardening
```

---

# 63. Git Strategy

Make small logical commits.

Examples:

```text
feat(auth): add Laravel Sanctum authentication
feat(schedule): add schedule entries
feat(availability): add overnight interval handling
feat(circles): add circle membership
feat(plans): add RSVP system
feat(import): add rota preview
fix(availability): correct midnight boundary
```

Do not make huge commits containing unrelated features.

---

# 64. Code Quality Rules

Avoid:

```text
giant components
giant controllers
duplicated logic
magic numbers
hardcoded user IDs
hardcoded API URLs
hardcoded secrets
business logic inside JSX
business logic duplicated between frontend/backend
```

Prefer:

```text
small components
domain services
typed APIs
constants
validation schemas
reusable utilities
clear naming
```

---

# 65. Important Architectural Rule

The frontend may calculate availability for instant UI feedback, but the backend must remain the authoritative source for protected/circle availability.

Do not allow a modified browser request to expose another user's private schedule.

The server must determine:

```text
who is requesting
which circle
which members
what visibility they have
what information can be returned
```

before generating the response.

---

# 66. API Response Privacy

For a `free_busy` member, the API should never return:

```text
shift label
notes
private reason
```

even if the frontend promises not to display them.

Return only what is allowed.

Example:

```json
{
  "date": "2026-10-10",
  "start": "15:00",
  "end": "18:00",
  "status": "available"
}
```

---

# 67. Do Not Overbuild

Do NOT initially implement:

```text
native mobile app
WebSockets
complex push infrastructure
Google Calendar OAuth
Apple Calendar OAuth
Microsoft Calendar OAuth
payments
subscriptions
AI chat assistant
large social feed
public social profiles
complex recommendation AI
microservices
Redis unless actually needed
Docker requirement
Kubernetes
```

Build the core product first.

---

# 68. Future Flutter Compatibility

The backend should eventually support:

```text
Next.js Web
      │
      ├──── REST API ──── Laravel
      │                      │
Flutter Mobile
      │
      └──── REST API ────────┘
```

The Flutter application must not require a separate backend.

Avoid browser-only assumptions in API design.

---

# 69. Definition of Done

A feature is not complete merely because the UI exists.

Each feature should include:

```text
database
migration
model
validation
authorization
API endpoint
API response
frontend integration
error handling
tests where applicable
responsive UI
```

For important scheduling features, automated tests are mandatory.

---

# 70. Agent Working Instructions

Before implementing:

1. Inspect the existing repository.
2. Identify existing code and architecture.
3. Do not delete working functionality without understanding it.
4. Create a development plan.
5. Identify architectural conflicts.
6. Implement incrementally.
7. Run tests after major changes.
8. Fix errors before moving forward.
9. Keep the code production-quality.
10. Document important architectural decisions.

If the repository already contains an implementation of a feature, improve/refactor it instead of blindly duplicating it.

---

# 71. UI Development Instructions

Before building each major screen:

1. Define its purpose.
2. Define the primary user action.
3. Define required states.
4. Define loading state.
5. Define empty state.
6. Define error state.
7. Define mobile layout.
8. Define desktop layout.

Every important screen must handle:

```text
loading
success
empty
error
```

---

# 72. Final Product Priorities

Prioritize the following in order:

```text
1. Privacy
2. Correct availability calculations
3. Simple schedule management
4. Reliable circle matching
5. Fast plan creation
6. Clean UX
7. API quality
8. Offline usability
9. AI convenience
```

The application should feel simple to the user even though the scheduling engine is technically sophisticated.

---

# 73. Final Architecture

The final system should resemble:

```text
                         OUR DAYS OFF
                              │
                   ┌──────────┴──────────┐
                   │                     │
                Next.js              Future Flutter
                   │                     │
                   └──────────┬──────────┘
                              │
                         REST API v1
                              │
                           Laravel
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
        Auth              Domain Logic          API
          │                   │
          │            ┌──────┴──────┐
          │            │             │
          │       Availability     Plans
          │          Engine
          │            │
          └────────────┼────────────────────────┐
                       │                        │
                     MySQL                  OpenAI
                       │
                   File Storage
```

The core domain remains:

```text
Schedule
   ↓
Availability
   ↓
Matching
   ↓
Circles
   ↓
Plans
```

Keep this architecture stable even when Flutter is introduced later.

---

# 74. First Task

Before writing substantial code:

### Step 1

Inspect the current repository and identify:

```text
existing frontend
existing backend
existing database
existing components
existing authentication
existing schedule logic
existing deployment configuration
```

### Step 2

Produce a concise implementation plan containing:

```text
current architecture
proposed architecture
files to create
files to modify
database migrations
API endpoints
frontend routes
availability-engine design
testing strategy
deployment strategy
```

### Step 3

Do not begin implementing until the plan is internally consistent.

Then implement Phase 1 and continue incrementally.

Do not ask unnecessary questions when reasonable technical decisions can be made from this specification.

When a requirement is ambiguous, choose the simplest architecture that preserves:

```text
privacy
security
future Flutter compatibility
cPanel compatibility
maintainability
```

# END OF DEVELOPMENT PROMPT