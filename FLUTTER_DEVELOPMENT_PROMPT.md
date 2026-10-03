# OUR DAYS OFF — MASTER FLUTTER (ANDROID & iOS) DEVELOPMENT PROMPT

> **Target Audience:** Autonomous AI Coding Agent / Senior Flutter Engineer  
> **Project Scope:** Full cross-platform mobile application (iOS & Android) built with Flutter matching 100% of features from the existing Next.js web application and connected to the Laravel REST API backend.  
> **Workspace Location:** `mobile/` (relative to project root)  
> **API Backend:** Laravel 11+ REST API running on PHP 8.2+ (`backend/`)

---

## 1. System Role & Autonomous Execution Directives

You are the **Lead Mobile Software Engineer** and **Flutter Solutions Architect** responsible for creating **Our Days Off Mobile** from scratch to production-ready release on **iOS and Android**.

### Core Directives for the AI Agent:
1. **Follow the Phased Roadmap Sequentially:** Implement each phase step-by-step. Do not skip phases or introduce half-baked placeholders (`// TODO: implement later` is strictly prohibited).
2. **Match Web Parity 1:1:** Every feature present in the web application (Schedule, Fast-tap shift stamping, Month/Day/Rota views, Circles, Matching Engine, Overlap Heatmaps, Meetup Plans with Polling & Chat, Location Voting, AI Rota Camera Import, Notifications, Companion Device Pairing, and Admin Panel) must be implemented with native mobile UX.
3. **Strict Architecture & Clean Code:** Follow Feature-First Clean Architecture using **Flutter Riverpod** for state management, **Dio** for HTTP networking with Sanctum Bearer token interceptors, **flutter_secure_storage** for auth tokens, **Hive** for offline caching, and **GoRouter** with ShellRoute for bottom navigation.
4. **Platform Fidelity (iOS & Android):** The app must feel native on both platforms. Support iOS pull-to-refresh, Cupertino-inspired sheets, system haptic feedback, safe area insets, dynamic notches/dynamic islands, Android back navigation, and edge-to-edge system bars.
5. **Privacy First Principle:** Raw personal schedules are private by default. Circles consume derived free/busy intervals filtered strictly according to circle privacy settings (`free_busy`, `shifts`, or `details`).

---

## 2. Product Overview & Domain Logic

### Product Mission
"Our Days Off" solves schedule coordination for friends, families, shift workers (nurses, doctors, retail, pilots, hospitality), and remote teams by identifying overlapping free time without exposing sensitive personal calendar entries.

### User Flow Diagram
```text
Personal Schedule Entry / AI Rota Scan
            ↓
Availability Engine (Derives Free/Busy/Overnight/Recovery intervals)
            ↓
Circle Roster Comparison (Privacy filtered: free_busy | shifts | details)
            ↓
Matching Engine (Common Free Time & Best Meetup Windows)
            ↓
Meetup Plan Creation (Draft → Polling → Confirmed)
            ↓
In-Plan Discussion & Location Voting
            ↓
RSVP & Native Calendar Export (.ics)
```

### Key Domain Rules
* **Shift Types:** `work`, `personal`, `leave`, `off`, `other`.
* **Overnight Shifts:** Shifts spanning past midnight (e.g. 21:00 to 07:00 next day) with proper multi-day visual indicators and recovery time derivation.
* **Privacy Modes in Circles:**
  - `free_busy`: Group members see only whether the user is free or busy during time blocks. No shift titles or details.
  - `shifts`: Group members see shift template labels (e.g. "Day Shift", "Night Shift") and times.
  - `details`: Group members see notes and details.
* **Matching Algorithm:** The backend calculates common intervals when all or majority of circle members are free, ranking meetup slots by duration, daylight hours, and member attendance.

---

## 3. Technology Stack & Dependencies

The mobile project is located in `mobile/`. Ensure the following production-grade packages are integrated into `pubspec.yaml`:

```yaml
name: our_days_off
description: "Privacy-first schedule matching and social coordination mobile application."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management & DI
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Networking & Serialization
  dio: ^5.4.3+1
  json_annotation: ^4.9.0
  pretty_dio_logger: ^1.3.1

  # Routing & Deep Linking
  go_router: ^14.0.1

  # Secure Storage & Local Caching
  flutter_secure_storage: ^9.2.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.3

  # UI Components & Media
  table_calendar: ^3.1.2
  flutter_animate: ^4.5.0
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.10+1
  lucide_icons: ^0.257.0
  image_picker: ^1.1.0
  file_picker: ^8.0.0+1
  intl: ^0.19.0
  flutter_colorpicker: ^1.1.0
  shimmer: ^3.0.0

  # Device & System Integrations
  share_plus: ^9.0.0
  url_launcher: ^6.2.6
  path_provider: ^2.1.3
  flutter_vibrate: ^1.3.0
  device_info_plus: ^10.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.2
  build_runner: ^2.4.9
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

---

## 4. Design System & UI Specifications

Match the web application's elegant, warm cream and teal aesthetic:

### Color Palette
| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `primary` | `#2B7A72` | Main brand teal, action buttons, active icons |
| `primaryLight` | `#81D8D0` | Mint/soft teal accents, active chips, badges |
| `primaryDark` | `#1D5E57` | High contrast text on mint, pressed states |
| `scaffoldBackground` | `#FAF9F6` | Warm cream base screen background |
| `cardBackground` | `#FFFFFF` | Elevated cards, bottom sheets, navigation bar |
| `borderLight` | `#E8E5DF` | Card borders, dividers, list separators |
| `textPrimary` | `#1F2223` | Main headings, primary typography |
| `textMuted` | `#656A6D` | Subtitles, labels, descriptions |
| `textSubtle` | `#959A9E` | Timestamps, placeholders, inactive states |
| `accentViolet` | `#8C6DBE` | Gradients, special chips, hero badges |
| `accentLavender` | `#AE82D9` | Secondary gradient stop, plan tags |
| `accentLime` | `#D7D982` | Highlights, sparkle icons, gold badges |
| `statusAvailable` | `#10B981` | Day Off / Free indicators (Emerald) |
| `statusBusy` | `#3B82F6` | Working / Shift indicators (Blue) |
| `statusLeave` | `#F59E0B` | Annual / Sick Leave (Amber) |
| `statusOvernight` | `#8B5CF6` | Overnight shifts (Purple) |
| `danger` | `#EF4444` | Deletion, decline RSVP, error notices |

### Typography & Component Rules
* Use clean sans-serif font family (Inter or Roboto) with distinct weights:
  - Titles: Bold 20–24pt (`#1F2223`)
  - Section Headers: Bold 15–16pt (`#1F2223`)
  - Subheaders / Labels: SemiBold 12–13pt (`#656A6D`)
  - Body: Regular 13–14pt (`#1F2223`)
  - Micro / Meta: Medium/SemiBold 10–11pt (`#959A9E`)
* Cards: Rounded corners (`BorderRadius.circular(16)`), subtle border (`#E8E5DF`, 1px), minimal elevation (`0` to `2`).
* Touch targets: Minimum 48x48dp for buttons, fast-tap chips, and calendar cells.

---

## 5. API Backend Specification & Communication Protocol

### Base URL Configuration
The mobile app must support environment-based dynamic base URLs:
* **Android Emulator:** `http://10.0.2.2:8000/api/v1`
* **iOS Simulator / macOS:** `http://127.0.0.1:8000/api/v1`
* **Physical Device (LAN):** `http://<YOUR_LAN_IP>:8000/api/v1`
* **Production cPanel / Cloud:** `https://api.yourdomain.com/api/v1`

### Authentication Flow
1. User logs in or registers via `/auth/login` or `/auth/register`.
2. Response returns:
   ```json
   {
     "message": "Login successful",
     "data": {
       "user": { "id": 1, "name": "Alice", "email": "alice@example.com", "handle": "alice", "is_premium": false, "is_admin": false },
       "token": "1|laravel_sanctum_token..."
     }
   }
   ```
3. Store `token` in `FlutterSecureStorage` (key: `auth_token`).
4. Attach `Authorization: Bearer <token>` to all subsequent requests via Dio Interceptor.
5. On HTTP 401: Clear stored token and redirect to `/login`.
6. Rate limiting (429) must be caught and display a user-friendly throttle message.

### Comprehensive REST Endpoint Directory

#### 1. Authentication
* `POST /auth/register` — Body: `{ name, email, password, password_confirmation, handle? }`
* `POST /auth/login` — Body: `{ email, password }`
* `POST /auth/logout` — Requires Sanctum token. Clears current token.
* `GET /auth/me` — Returns current authenticated user record.

#### 2. User Profile & Settings
* `GET /profile` — Returns user profile details.
* `PUT /profile` — Body: `{ name, timezone?, handle_visibility? }`
* `POST /profile/handle-check` — Body: `{ handle }` → `{ available: bool }`

#### 3. Shift Templates (Fast Tap Presets)
* `GET /shift-templates` — Returns user's saved shift templates.
* `POST /shift-templates` — Body: `{ name, start_time, end_time, is_overnight, color }`
* `PUT /shift-templates/{id}` — Body: Updated template fields.
* `DELETE /shift-templates/{id}` — Deletes template.

#### 4. Personal Schedules & Fast Assignment
* `GET /schedules?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` — Returns schedule entries.
* `POST /schedules` — Body: `{ date, start_time, end_time, entry_type, label?, notes?, is_overnight, shift_template_id? }`
* `POST /schedules/batch` — Body: `{ entries: [...] }` (Fast multi-day stamp).
* `PUT /schedules/{id}` — Update single entry.
* `DELETE /schedules/{id}` — Delete single entry.

#### 5. Availability Engine & Overrides
* `GET /availability/personal?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` — Derived free/busy blocks.
* `GET /availability/overrides` — Manual availability overrides.
* `POST /availability/overrides` — Body: `{ date, is_available, start_time?, end_time?, reason? }`
* `DELETE /availability/overrides/{id}` — Remove override.

#### 6. Social Circles & Roster
* `GET /circles` — List user's joined circles with roles and member counts.
* `POST /circles` — Body: `{ name, handle?, discoverability }` (`private` or `searchable`).
* `GET /circles/{id}` — Circle details including member list, roles, and privacy rules.
* `DELETE /circles/{id}` — Delete circle (owner only).
* `PUT /circles/{id}/members/{member_id}` — Body: `{ role?, member_type?, visibility? }`
* `DELETE /circles/{id}/members/{member_id}` — Remove or leave circle.
* `GET /circles/{id}/activity` — Real-time event log for circle.
* `POST /circles/{id}/invites` — Body: `{ max_uses?, expires_in_days? }` → returns invite code & link.
* `POST /invites/join` — Body: `{ invite_code }` → Joins circle.

#### 7. Availability Matching & Overlap Matrix
* `GET /circles/{id}/availability?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` — Returns full circle matching payload:
  - `members`: Daily status for each member (`is_day_off`, `label`, `start_time`, `end_time`).
  - `common_availability`: Overlapping free intervals across all members.
  - `days_off`: Date-by-date breakdown of who is free vs working.
  - `off_time`: Overlapping hours window (e.g. 18:00 - 22:00, 4 hours overlap).
  - `suggestions`: Top ranked meetup windows with scores.
  - `plans`: Upcoming scheduled plans for this circle.
* `POST /availability/compare` — Body: `{ user_ids: [1, 2], start_date, end_date }` — 1-on-1 or custom sub-group comparison.

#### 8. Meetup Plans, RSVPs & In-Plan Chat
* `GET /plans` — All user's upcoming & past plans.
* `POST /plans` — Body: `{ circle_id, title, description?, event_type, start_at, end_at, status }`
* `GET /plans/{id}` — Plan details with RSVPs, locations, and chat messages.
* `DELETE /plans/{id}` — Cancel plan.
* `POST /plans/{id}/rsvp` — Body: `{ rsvp_status }` (`attending` | `tentative` | `declined`).
* `POST /plans/{id}/options` — Add proposed timeslot for polling.
* `GET /plans/{id}/messages` — In-plan message feed.
* `POST /plans/{id}/messages` — Body: `{ message }` — Post comment.
* `POST /plans/{id}/locations` — Propose venue / location.
* `POST /locations/{id}/vote` — Vote on proposed location.

#### 9. Rota AI Vision Scanner & Import
* `POST /imports/rota` — Multipart `file` (image or PDF) → AI extracts shift dates and times → returns preview JSON.
* `POST /imports/confirm` — Body: `{ entries: [...] }` → Confirms and saves extracted shifts to database.

#### 10. Companion Devices & Notifications
* `GET /devices` — List paired companion devices.
* `POST /devices/pairing-code` — Generate 6-digit sync pairing code.
* `POST /devices/pair` — Body: `{ pairing_code, device_name }` — Pair new device.
* `DELETE /devices/{id}` — Unpair device.
* `GET /notifications` — In-app notification list with `unread_count`.
* `PUT /notifications/{id}/read` — Mark notification read.
* `PUT /notifications/read-all` — Mark all read.

#### 11. Subscriptions & Premium
* `GET /subscription/status` — Returns `{ is_premium: bool }`.
* `POST /subscription/redeem` — Body: `{ coupon_code }` — Upgrades account to premium.

#### 12. Admin Management (Admin users only)
* `GET /admin/stats` — Metrics (users, circles, plans, schedules).
* `GET /admin/users?search=...` — Search & list users.
* `PUT /admin/users/{id}/toggle-premium` — Toggle user premium status.
* `GET /admin/coupons` — List coupon codes.
* `POST /admin/coupons` — Create new coupon code with expiration.
* `PUT /admin/coupons/{id}/toggle` — Enable/disable coupon.
* `GET /admin/circles` — List all circles in the system.

---

## 6. Project Architecture & Directory Layout

Structure the Flutter code in `mobile/lib/` using Feature-First Architecture:

```text
mobile/lib/
├── main.dart                          # App entry point, Riverpod Scope, Theme setup
├── core/
│   ├── config/
│   │   ├── api_config.dart            # Base URLs, timeouts, headers
│   │   └── app_constants.dart         # Global constants, keys, storage tags
│   ├── network/
│   │   ├── api_client.dart            # Dio singleton with auth interceptor
│   │   ├── auth_interceptor.dart      # Sanctum Bearer token injector & 401 handler
│   │   └── error_handler.dart         # Normalized AppExceptions & user messages
│   ├── storage/
│   │   ├── secure_storage_service.dart# FlutterSecureStorage for tokens
│   │   └── cache_manager.dart         # Hive boxes for offline data caching
│   ├── theme/
│   │   ├── app_colors.dart            # Color definitions matching web palette
│   │   ├── app_theme.dart             # ThemeData with Material 3, fonts, shapes
│   │   └── text_styles.dart           # Standardized text hierarchy
│   ├── router/
│   │   └── app_router.dart            # GoRouter with ShellRoute for bottom navigation
│   └── utils/
│       ├── date_time_utils.dart       # Formatter, ISO conversions, timezone helpers
│       ├── ics_exporter.dart          # Native calendar (.ics) file generation & share
│       └── haptic_feedback.dart       # Light, medium, selection haptics
├── shared/
│   └── widgets/
│       ├── app_button.dart            # Primary, secondary, outline, danger buttons
│       ├── app_text_field.dart        # Clean input with labels, errors, icons
│       ├── loading_indicator.dart     # Custom themed spinner & skeleton loaders
│       ├── empty_state_view.dart      # Illustrative empty states with CTA
│       ├── confirmation_dialog.dart   # Native iOS/Android styled alert dialogs
│       └── status_badge.dart          # Color-coded pill tags (work, off, rsvp, role)
└── features/
    ├── auth/                          # Login, Register, Splash, Token state
    │   ├── data/                      # AuthRepository, AuthRemoteSource
    │   ├── models/                    # UserModel, AuthResponse
    │   ├── providers/                 # authStateProvider, loginController
    │   └── views/                     # login_screen.dart, register_screen.dart
    ├── dashboard/                     # Metrics overview, quick actions, agenda
    │   ├── providers/                 # dashboardDataProvider
    │   └── views/                     # dashboard_screen.dart
    ├── schedule/                      # Month Calendar, Day View, Fast Tap Stamping
    │   ├── data/                      # ScheduleRepository, ShiftTemplateRepository
    │   ├── models/                    # ScheduleEntry, ShiftTemplate, Override
    │   ├── providers/                 # scheduleEntriesProvider, activeTemplateProvider
    │   └── views/                     # schedule_screen.dart, fast_tap_bar.dart,
    │                                  # date_detail_bottom_sheet.dart
    ├── rota_import/                   # Camera/Document OCR & AI Rota Extraction
    │   ├── data/                      # ImportRepository
    │   ├── providers/                 # rotaImportProvider
    │   └── views/                     # rota_scanner_screen.dart, rota_preview_screen.dart
    ├── circles/                       # Circles list, detail, invites, members, activity
    │   ├── data/                      # CircleRepository
    │   ├── models/                    # CircleModel, CircleMember, ActivityEvent
    │   ├── providers/                 # circleListProvider, circleDetailProvider
    │   └── views/                     # circles_screen.dart, circle_detail_screen.dart,
    │                                  # invite_modal.dart, join_circle_dialog.dart
    ├── matching/                      # Roster Grid, Overlap Heatmap, Suggestions
    │   ├── data/                      # MatchingRepository
    │   ├── models/                    # CircleAvailabilityData, DaysOffSummary
    │   ├── providers/                 # circleMatchingProvider, compareProvider
    │   └── views/                     # compare_screen.dart, rota_grid_view.dart,
    │                                  # suggestions_carousel.dart
    ├── plans/                         # Meetup Plans, Polling, RSVPs, Chat & Voting
    │   ├── data/                      # PlanRepository
    │   ├── models/                    # PlanModel, PlanMessage, PlanLocation
    │   ├── providers/                 # plansListProvider, planDetailProvider
    │   └── views/                     # plans_screen.dart, plan_detail_screen.dart,
    │                                  # create_plan_sheet.dart, plan_chat_widget.dart
    ├── notifications/                 # In-app notifications tray & badges
    │   ├── models/                    # NotificationModel
    │   ├── providers/                 # notificationCountProvider
    │   └── views/                     # notifications_sheet.dart
    ├── profile/                       # Settings, Handle config, Device pairing
    │   ├── views/                     # profile_screen.dart, device_pairing_view.dart
    │   └── providers/                 # profileProvider, deviceManagerProvider
    └── admin/                         # Admin statistics, user toggle, coupons
        ├── views/                     # admin_panel_screen.dart
        └── providers/                 # adminDataProvider
```

---

## 7. Step-by-Step, Phase-by-Phase Implementation Roadmap

Execute the implementation strictly across the following 10 phases:

### Phase 1: Foundation, Networking, Theming & Base Architecture
* **Goal:** Set up dependencies, configure theme colors, typography, Dio networking client with interceptors, secure token storage, and GoRouter skeleton.
* **Key Tasks:**
  1. Add all dependencies to `mobile/pubspec.yaml` and run `flutter pub get`.
  2. Create `AppColors`, `AppTheme` (Light theme + Dark mode scaffolding) with Google Fonts/Inter, matching `#FAF9F6`, `#2B7A72`, `#81D8D0`, `#1F2223`.
  3. Create `ApiClient` with Dio, logging, base URL resolution, and `AuthInterceptor`.
  4. Build `SecureStorageService` with `flutter_secure_storage`.
  5. Setup `AppRouter` with `StatefulShellRoute.indexedStack` for the 5 primary tabs:
     - Dashboard (`/dashboard`)
     - My Schedule (`/schedule`)
     - Circles (`/circles`)
     - Compare (`/compare`)
     - Plans (`/plans`)
     - (And secondary routes for `/profile`, `/admin`, `/login`, `/register`).
  6. Build custom bottom navigation bar with responsive height and badge indicators.

### Phase 2: Authentication & User Profile
* **Goal:** Complete authentication system with registration, login, auto-login, logout, and profile management.
* **Key Tasks:**
  1. Create `UserModel` with fields `id`, `name`, `email`, `handle`, `is_premium`, `is_admin`, `timezone`.
  2. Implement `AuthRepository` calling `/auth/register`, `/auth/login`, `/auth/logout`, `/auth/me`.
  3. Implement `AuthNotifier` in Riverpod with persistent state.
  4. Build `LoginScreen` and `RegisterScreen`:
     - Clean form validation with instant error display.
     - Live handle availability check via `/profile/handle-check`.
     - Smooth transitions and loading indicators.
  5. Profile Screen:
     - Edit display name, view handle & privacy level.
     - Logout confirmation dialog clearing secure tokens and resetting Riverpod state.

### Phase 3: Personal Schedule Engine & Fast-Tap Stamping
* **Goal:** Build the schedule calendar with high-velocity shift stamping and template management.
* **Key Tasks:**
  1. Create `ShiftTemplate` and `ScheduleEntry` models with JSON serialization.
  2. Implement `ShiftTemplateRepository` and `ScheduleRepository`.
  3. Build `MonthCalendar`:
     - Render monthly calendar using `TableCalendar`.
     - Marker dots / chips colored by shift template (`#3B82F6` for day shifts, `#8B5CF6` for night shifts, `#10B981` for off).
     - Multi-month swipe and quick month picker.
  4. Build **Fast-Tap Toolbar**:
     - Sticky bottom toolbar showing user's shift templates as colored pills (e.g. `[+ Day 07-15]`, `[+ Night 21-07]`, `[+ Off]`).
     - Tapping a template selects it as the active "stamp".
     - Tapping any calendar day immediately creates or replaces the shift for that date with light haptic feedback.
     - Batch creation via `/schedules/batch` for rapid week/month scheduling.
  5. Build `DateDetailBottomSheet`:
     - Opens on date selection.
     - Displays assigned shift, start/end hours, notes, overnight badge, and manual override toggle (`/availability/overrides`).

### Phase 4: AI Rota Vision Scanner & Import System
* **Goal:** Allow users to take a photo of their physical roster, upload an image/document, parse it via backend AI, and confirm imports.
* **Key Tasks:**
  1. Integrate `image_picker` for Camera capture and Gallery selection.
  2. Build `RotaScannerScreen`:
     - Three import modes:
       - **AI Vision (Camera/Upload):** Uploads image as `multipart/form-data` to `/imports/rota`.
       - **External AI Assistant:** Pre-configured prompt copied to clipboard with instructions to paste JSON from ChatGPT/Claude.
       - **Manual Entry:** Rapid manual entry form.
     - Premium validation check (`/subscription/status`) with coupon redemption modal if non-premium.
  3. Build `RotaPreviewScreen`:
     - Interactive table of parsed shifts (Date, Shift Label, Start Time, End Time, Overnight toggle).
     - Ability to edit or delete any parsed row before saving.
     - "Confirm Import" button posting verified shifts to `/imports/confirm`.

### Phase 5: Social Circles & Member Management
* **Goal:** Manage privacy circles, view members, send invites, and track activity.
* **Key Tasks:**
  1. Create `CircleModel`, `CircleMember`, and `ActivityEvent` models.
  2. Build `CirclesScreen` with list of user's circles, member counts, and user's role badge (`Owner`, `Admin`, `Member`).
  3. Implement `CreateCircleModal` (name, handle, discoverability toggle).
  4. Implement `JoinCircleDialog` (enter invite code or handle).
  5. Build `CircleDetailScreen`:
     - Circle header with member count and privacy status.
     - Member roster list showing roles (`Owner`, `Admin`, `Member`) and visibility level (`free_busy`, `shifts`, `details`).
     - Role editing and member removal for admins/owners.
     - "Invite Members" sheet with shareable 6-character code and native share sheet integration (`share_plus`).
     - "Circle Activity Feed" showing recent joins, schedule updates, and plan creations.

### Phase 6: Schedule Matching Engine, Rota Grid & Overlap Heatmaps
* **Goal:** The core intelligence engine matching days off, calculating overlapping hours, and suggesting meetup slots.
* **Key Tasks:**
  1. Fetch circle availability from `/circles/{id}/availability?start_date=...&end_date=...`.
  2. Build `RotaGridView`:
     - Matrix showing circle members along the vertical axis and dates along the horizontal scroll axis.
     - Color-coded cells showing member status (`OFF` in green, `WORK` in blue, `LEAVE` in amber).
     - Tapping any cell opens the privacy-safe member detail popover.
  3. Build **Availability Mode Toggle**:
     - **Mode 1: "Days Off"**: Focuses on dates where all or most members have the entire day off.
     - **Mode 2: "Off Time"**: Focuses on overlapping free time windows across different shifts (e.g., both members free between 18:00 and 23:00).
  4. Build `SuggestedTimesCard`:
     - Display top AI-calculated meetup windows ranked by score and duration.
     - "Create Plan" button on each suggestion that pre-populates plan creation with that exact date and time.
  5. Build `CompareScreen` (1-on-1 personal compare):
     - Select two or more members from a circle.
     - Visual side-by-side time breakdown with overlap highlights.

### Phase 7: Meetup Plans, RSVPs, Location Voting & In-Plan Chat
* **Goal:** Turn matched free time into confirmed social gatherings with collaborative voting and chat.
* **Key Tasks:**
  1. Create `PlanModel`, `PlanOption`, `PlanLocation`, `PlanMessage` models.
  2. Build `PlansScreen`:
     - Tabbed list of plans: "Upcoming", "Polling", "Past".
     - Cards showing title, circle name, date/time, RSVP status badge, and participant avatars.
  3. Build `CreatePlanSheet`:
     - Circle picker, title, description, event type (`social`, `meal`, `travel`, `other`), start/end timestamps.
  4. Build `PlanDetailScreen`:
     - **RSVP Control Bar:** Quick toggle buttons (`Attending`, `Tentative`, `Declined`) with live count updates via `/plans/{id}/rsvp`.
     - **Location Voting Widget:** Propose venues with address/name, vote button with real-time vote counter (`/locations/{id}/vote`).
     - **In-Plan Discussion (Chat):** Lightweight real-time comment thread for the plan (`/plans/{id}/messages`).
     - **Native Calendar Export:** "Add to Device Calendar" action generating an `.ics` file using `ics_exporter.dart` and opening native calendar intent.

### Phase 8: Companion Device Pairing & In-App Notifications
* **Goal:** Multi-device synchronization and timely alerts.
* **Key Tasks:**
  1. Build `NotificationCenter` (accessible via AppBar bell icon):
     - Displays unread notifications with badge count.
     - Tap to mark single read (`/notifications/{id}/read`) or "Mark all read" (`/notifications/read-all`).
     - Navigates directly to the relevant Circle or Plan on tap.
  2. Build `DevicePairingView` (in Profile):
     - Generate a 6-digit one-time code to link an iPad, secondary phone, or desktop companion via `/devices/pairing-code`.
     - Input field to pair another device by code via `/devices/pair`.
     - List active paired devices with revoke button.

### Phase 9: Premium Upgrades, Coupons & Admin Controls
* **Goal:** Monitization support and administrative oversight for platform admins.
* **Key Tasks:**
  1. Build `SubscriptionRedeemDialog`:
     - Coupon input field to redeem promotional VIP codes via `/subscription/redeem`.
     - Instant UI update to Golden/VIP badge.
  2. Build `AdminPanelScreen` (protected by `user.is_admin == true` check):
     - Summary metrics grid: Total users, premium count, total circles, total plans.
     - User Management: Search users by name/email, toggle premium status on/off.
     - Coupon Management: List active coupons, generate new coupon code with expiration date, toggle coupon status.
     - Circles Inspector: View all circles in the system.

### Phase 10: Performance Optimization, Offline Resilience & Native Polish
* **Goal:** Ensure smooth 60fps animations, offline read capability, and store-ready polish on Android and iOS.
* **Key Tasks:**
  1. **Offline Caching:** Cache personal schedule entries and circle rosters in Hive boxes. If network fails, display cached data with a subtle "Offline / Cached" banner.
  2. **Optimistic UI Updates:** Immediately update RSVP states, shift stamps, and notification badges before server response, rolling back on failure.
  3. **Haptic Feedback:** Add `HapticFeedback.lightImpact()` on calendar taps, shift stamps, and RSVP buttons.
  4. **Smooth Transitions:** Use `flutter_animate` for staggered list appearances and modal slides.
  5. **Native Assets:** Configure app launcher icons (`flutter_launcher_icons`) and splash screen (`flutter_native_splash`) with "Our Days Off" branding.

---

## 8. Self-Verification, Testing & Acceptance Criteria

Before declaring any feature complete, verify against the following test checklist:

1. **Authentication:**
   - [ ] Register new user with unique handle → succeeds and persists token.
   - [ ] Invalid credentials return proper error banner.
   - [ ] App restart preserves logged-in state without re-login.
   - [ ] Logout deletes token from secure storage and routes to `/login`.
2. **Personal Schedule:**
   - [ ] Fast-tap stamps shifts smoothly across multiple dates.
   - [ ] Overnight shifts display overnight indicator icon and span correctly.
   - [ ] Custom shift template creation with color picker reflects immediately.
   - [ ] Manual override disables shift and marks user as available/unavailable.
3. **Circles & Matching:**
   - [ ] Create circle, generate invite code, join with second test account.
   - [ ] Rota Grid shows both users with their respective shifts.
   - [ ] Setting visibility to `free_busy` conceals shift names from circle mates.
   - [ ] Off-time overlap calculator displays accurate common free hours.
4. **Meetup Plans & RSVPs:**
   - [ ] Create plan from suggested time slot.
   - [ ] Tapping "Attending" updates RSVP count and changes user badge to green.
   - [ ] Posting chat message updates feed instantly.
   - [ ] Proposing and voting on location updates ranking.
   - [ ] "Add to Calendar" generates `.ics` file and prompts system calendar.
5. **Admin & Premium:**
   - [ ] Admin tab appears exclusively for users with `is_admin: true`.
   - [ ] Redeeming valid coupon upgrades user to premium immediately.
6. **No Regressions:**
   - [ ] `flutter analyze` passes with zero errors and zero warnings.
   - [ ] Layout renders cleanly without any `RenderFlex` overflow errors on small and large screens.
