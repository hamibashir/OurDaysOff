# Our Days Off — Complete Step-by-Step Flutter Implementation Plan

This document outlines the granular, step-by-step roadmap for building the production-ready **Our Days Off** Flutter mobile application (Android & iOS).

---

## Progress Overview

| Phase | Description | Steps | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Foundation, Networking, Design System & Router** | Steps 1.1 – 1.4 | 🟢 Completed |
| **Phase 2** | **Authentication & User Profile State** | Steps 2.1 – 2.4 | 🟢 Completed |
| **Phase 3** | **Personal Schedule, Shift Templates & Fast-Tap** | Steps 3.1 – 3.4 | 🟢 Completed |
| **Phase 4** | **AI Rota Vision Camera Scanner & Importer** | Steps 4.1 – 4.3 | 🟢 Completed |
| **Phase 5** | **Circles, Members, Invites & Activity Feed** | Steps 5.1 – 5.4 | 🟡 In Progress (Up Next) |
| **Phase 6** | **Schedule Matching, Rota Grid Matrix & Overlap** | Steps 6.1 – 6.4 | ⚪ Queued |
| **Phase 7** | **Meetup Plans, RSVPs, Chat & Calendar Export** | Steps 7.1 – 7.4 | ⚪ Queued |
| **Phase 8** | **Notifications Center & Companion Device Pairing** | Steps 8.1 – 8.3 | ⚪ Queued |
| **Phase 9** | **VIP Premium, Coupons & Admin Dashboard** | Steps 9.1 – 9.3 | ⚪ Queued |
| **Phase 10** | **Offline Caching, Native Polish & Store Readiness** | Steps 10.1 – 10.3| ⚪ Queued |

---

## Detailed Phase Breakdown

### Phase 1: Foundation, Networking, Design System & Router
- [x] **Step 1.1: Dependency Resolution & Project Folder Structure**
  - Update `pubspec.yaml` with Riverpod, Dio, GoRouter, SecureStorage, TableCalendar, LucideIcons, Intl, etc.
  - Run `flutter pub get` and verify 0 conflicts.
  - Create directory structure under `mobile/lib/` (`core/`, `features/`, `shared/`).
- [x] **Step 1.2: Design Tokens & Theme System**
  - Implement `AppColors` matching web palette (`#2B7A72`, `#81D8D0`, `#FAF9F6`, `#1F2223`, etc.).
  - Implement `AppTheme` with custom Material 3 typography, card radius, button styling, and navigation themes.
- [x] **Step 1.3: Network Layer & Secure Token Engine**
  - Implement `ApiConfig` with dynamic host detection (Android emulator `10.0.2.2` vs iOS `127.0.0.1` vs custom IP).
  - Implement `ApiClient` with Dio, `AuthInterceptor` (Sanctum Bearer token injector & 401 handler), and `AppException`.
  - Implement `SecureStorageService` using `flutter_secure_storage`.
- [x] **Step 1.4: Navigation Shell & Bottom Navigation Bar**
  - Implement `AppRouter` with `StatefulShellRoute` for 5 primary tabs (Dashboard, Schedule, Circles, Compare, Plans).
  - Build responsive custom bottom navigation bar with active indicators and badges.

### Phase 2: Authentication & User Profile State
- [x] **Step 2.1: Auth Models & Repository**
  - Implement `UserModel` and `AuthResponse` with JSON serialization.
  - Implement `AuthRepository` (`/auth/login`, `/auth/register`, `/auth/logout`, `/auth/me`).
- [x] **Step 2.2: Auth State Notifier & Auto-Login**
  - Implement Riverpod `AuthNotifier` to check stored token on app launch and hydrate user state.
- [x] **Step 2.3: Login & Register Screens**
  - Build clean input forms, handle check debounce via `/profile/handle-check`, password visibility toggles, and validation.
- [x] **Step 2.4: Profile Screen & Settings**
  - Display name edit, handle display, visibility settings, and secure sign-out.

### Phase 3: Personal Schedule, Shift Templates & Fast-Tap
- [x] **Step 3.1: Schedule Models & Repository**
  - Implement `ShiftTemplate`, `ScheduleEntry`, and `AvailabilityBlock` models.
  - Implement `ScheduleRepository` and `ShiftTemplateRepository`.
- [x] **Step 3.2: Month & Day Calendar Views**
  - Build `TableCalendar` integration with multi-color dot indicators for shifts.
- [x] **Step 3.3: High-Velocity Fast-Tap Stamping Toolbar**
  - Sticky bottom template bar (`+ Day`, `+ Night`, `+ Off`).
  - Single-tap rapid date stamping with haptic feedback.
- [x] **Step 3.4: Date Detail Bottom Sheet & Overrides**
  - Detailed shift info card, time adjustments, and manual availability override toggle.

### Phase 4: AI Rota Vision Camera Scanner & Importer
- [x] **Step 4.1: Camera & Gallery Image Picker**
  - Integrate `image_picker` with platform permissions.
- [x] **Step 4.2: Multipart AI Vision Upload & External Prompt Mode**
  - Upload rota photo to `/imports/rota` and support external JSON paste fallback.
- [x] **Step 4.3: Interactive Shift Preview & Batch Confirmation**
  - Editable data table of parsed shifts, delete row, and confirm batch import to `/imports/confirm`.

### Phase 5: Circles, Members, Invites & Activity Feed
- [x] **Step 5.1: Circle Models & Repository**
  - Implement `CircleModel`, `CircleMember`, and `ActivityEvent` models.
- [x] **Step 5.2: Circles List & Creation**
  - List user's circles, member counts, and `CreateCircleModal`.
- [x] **Step 5.3: Circle Detail, Member Roles & Privacy Rules**
  - Member management, privacy selector (`free_busy`, `shifts`, `details`), role changes.
- [x] **Step 5.4: Invite Generator & Activity Feed**
  - 6-character code generator, native share sheet, and recent activity log.

### Phase 6: Schedule Matching, Rota Grid Matrix & Overlap
- [x] **Step 6.1: Matching Repository & Response Models**
  - Fetch circle matching payload from `/circles/{id}/availability`.
- [x] **Step 6.2: Horizontal Scrollable Rota Grid Matrix**
  - Members (Y-axis) vs Dates (X-axis) with colored shift badges.
- [x] **Step 6.3: "Days Off" vs "Off Time" Toggle**
  - Filter full days off vs overlapping shift hours.
- [x] **Step 6.4: AI Suggested Meetup Windows & 1-on-1 Compare**
  - Top scored meetup suggestions and custom member comparison tool.

### Phase 7: Meetup Plans, RSVPs, Chat & Calendar Export
- [x] **Step 7.1: Plan Models & Repository**
  - Implement `PlanModel`, `PlanMessage`, `PlanLocation`.
- [x] **Step 7.2: Plans Feed & Quick Create**
  - Upcoming/polling/past tabs, pre-filled plan creation from suggestions.
- [x] **Step 7.3: RSVP State Machine & Location Voting**
  - Attending / Tentative / Declined toggles, propose venue, and upvote location.
- [x] **Step 7.4: In-Plan Discussion Thread & .ics Native Export**
  - Comments feed and calendar (.ics) file generation with native calendar intent.

### Phase 8: Notifications Center & Companion Device Pairing
- [x] **Step 8.1: In-App Notification Center**
  - AppBar bell badge, read/unread status, mark all read, deep link navigation.
- [ ] **Step 8.2: Companion Device 6-Digit Pairing**
  - Generate one-time pairing code and pair secondary devices.
- [ ] **Step 8.3: Paired Devices Management**
  - List active companion devices with revoke session capability.

### Phase 9: VIP Premium, Coupons & Admin Dashboard
- [ ] **Step 9.1: Subscription Status & Coupon Redemption**
  - Promo code redemption via `/subscription/redeem` and VIP badge styling.
- [ ] **Step 9.2: Admin Stats & User Management**
  - Protected admin screen, platform metrics, user search, and premium toggle.
- [ ] **Step 9.3: Coupon Management & Circle Oversight**
  - Generate new promo codes, set expirations, toggle active status.

### Phase 10: Offline Caching, Native Polish & Store Readiness
- [ ] **Step 10.1: Hive Local Storage & Offline Mode**
  - Cache personal schedule & circles for instant offline launch.
- [ ] **Step 10.2: Native Haptics & Fluid Micro-Animations**
  - Staggered list animations and iOS/Android haptic feedback.
- [ ] **Step 10.3: App Icons, Splash Screen & Platform Build Verification**
  - Configure native launch assets and verify `flutter analyze` with 0 warnings.
