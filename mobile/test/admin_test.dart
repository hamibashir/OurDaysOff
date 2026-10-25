import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/features/admin/models/admin_models.dart';

void main() {
  group('Admin Models Serialization Tests', () {
    test('AdminStats parses stats payload correctly', () {
      final json = {
        'total_users': 150,
        'premium_users': 45,
        'total_circles': 28,
        'total_plans': 72,
        'total_schedules': 1200,
        'active_coupons': 12,
      };

      final stats = AdminStats.fromJson(json);

      expect(stats.totalUsers, equals(150));
      expect(stats.premiumUsers, equals(45));
      expect(stats.totalCircles, equals(28));
      expect(stats.totalPlans, equals(72));
      expect(stats.totalSchedules, equals(1200));
      expect(stats.activeCoupons, equals(12));
    });

    test('AdminUser parses and handles initials correctly', () {
      final json = {
        'id': 10,
        'name': 'Sarah Connor',
        'email': 'sarah@skynet.com',
        'handle': 'sarahc',
        'is_premium': true,
        'is_admin': false,
        'created_at': '2026-05-01T10:00:00Z',
      };

      final user = AdminUser.fromJson(json);

      expect(user.id, equals(10));
      expect(user.name, equals('Sarah Connor'));
      expect(user.email, equals('sarah@skynet.com'));
      expect(user.isPremium, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.initials, equals('SC'));

      final updated = user.copyWith(isAdmin: true);
      expect(updated.isAdmin, isTrue);
    });

    test('AdminCoupon calculates expiration and copyWith correctly', () {
      final json = {
        'id': 3,
        'code': 'VIPPRO2026',
        'is_active': 1,
        'is_used': 0,
        'expires_at': '2020-01-01T00:00:00Z',
      };

      final coupon = AdminCoupon.fromJson(json);

      expect(coupon.id, equals(3));
      expect(coupon.code, equals('VIPPRO2026'));
      expect(coupon.isActive, isTrue);
      expect(coupon.isUsed, isFalse);
      expect(coupon.isExpired, isTrue);

      final toggled = coupon.copyWith(isActive: false);
      expect(toggled.isActive, isFalse);
    });

    test('AdminCircle parses circle overview with owner name', () {
      final json = {
        'id': 5,
        'name': 'ER Night Shift Crew',
        'handle': 'er_nights',
        'owner': {'id': 2, 'name': 'Dr. John Watson'},
        'members_count': 14,
        'is_discoverable': 1,
        'created_at': '2026-06-15T08:30:00Z',
      };

      final circle = AdminCircle.fromJson(json);

      expect(circle.id, equals(5));
      expect(circle.name, equals('ER Night Shift Crew'));
      expect(circle.handle, equals('er_nights'));
      expect(circle.ownerName, equals('Dr. John Watson'));
      expect(circle.membersCount, equals(14));
      expect(circle.isDiscoverable, isTrue);
    });
  });
}
