export interface User {
  id: number;
  name: string;
  email: string;
  handle: string | null;
  handle_visibility?: 'public' | 'circle_only' | 'private';
  is_premium?: boolean;
  is_admin?: boolean;
  timezone?: string;
  created_at?: string;
}

export interface AuthResponse {
  message: string;
  data: {
    user: User;
    token: string;
  };
}

export interface ApiResponse<T> {
  message?: string;
  data: T;
}

export interface ApiErrorResponse {
  message: string;
  errors?: Record<string, string[]>;
}

export interface ShiftTemplate {
  id: number;
  user_id: number;
  name: string;
  start_time: string;
  end_time: string;
  is_overnight: boolean;
  color: string;
}

export interface ScheduleEntry {
  id: number;
  user_id: number;
  shift_template_id: number | null;
  date: string;
  start_time: string;
  end_time: string;
  timezone?: string;
  entry_type: 'work' | 'personal' | 'leave' | 'off' | 'other';
  label?: string | null;
  notes?: string | null;
  is_overnight: boolean;
  source: 'manual' | 'template' | 'import';
}

export interface AvailabilityBlock {
  date: string;
  start: string;
  end: string;
  status: 'available' | 'unavailable';
  reason?: string;
  shift_type?: string;
}

export interface Circle {
  id: number;
  owner_id: number;
  name: string;
  handle: string | null;
  discoverability: 'private' | 'searchable';
  created_at: string;
  members_count?: number;
  my_role?: 'owner' | 'admin' | 'member';
  my_visibility?: 'free_busy' | 'shifts' | 'details';
}

export interface CircleMember {
  id: number;
  circle_id: number;
  user_id: number;
  role: 'owner' | 'admin' | 'member';
  member_type: 'working' | 'viewer';
  visibility: 'free_busy' | 'shifts' | 'details';
  status: 'pending' | 'active' | 'removed';
  joined_at: string;
  user?: User;
}

export interface Plan {
  id: number;
  circle_id: number;
  created_by: number;
  title: string;
  description: string | null;
  event_type: 'social' | 'meal' | 'travel' | 'other';
  start_at: string | null;
  end_at: string | null;
  timezone?: string;
  status: 'draft' | 'polling' | 'confirmed' | 'cancelled' | 'completed';
  created_at: string;
  my_rsvp?: 'attending' | 'tentative' | 'declined' | 'pending';
}

export interface ActivityEvent {
  id: number;
  circle_id: number;
  actor_id: number;
  event_type: string;
  entity_type: string | null;
  entity_id: number | null;
  metadata: Record<string, any> | null;
  created_at: string;
  actor?: User;
}
