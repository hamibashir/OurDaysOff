/**
 * Lightweight, zero-dependency session cache for preserving page data in memory.
 * Prevents redundant API requests and skeleton re-triggers during route navigation.
 */
interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttlMs?: number;
}

class SessionCache {
  private cache = new Map<string, CacheEntry<any>>();

  /**
   * Retrieve cached item if valid and not expired.
   */
  public get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    if (entry.ttlMs && Date.now() - entry.timestamp > entry.ttlMs) {
      this.cache.delete(key);
      return null;
    }

    return entry.data as T;
  }

  /**
   * Store item in session cache.
   */
  public set<T>(key: string, data: T, ttlMs?: number): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttlMs,
    });
  }

  /**
   * Check if a non-expired entry exists for key.
   */
  public has(key: string): boolean {
    return this.get(key) !== null;
  }

  /**
   * Invalidate entries matching a string prefix or RegExp.
   */
  public invalidate(pattern: string | RegExp): void {
    for (const key of this.cache.keys()) {
      if (typeof pattern === "string") {
        if (key.startsWith(pattern) || key === pattern) {
          this.cache.delete(key);
        }
      } else if (pattern.test(key)) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Completely purge cache (called on logout / user switch).
   */
  public clear(): void {
    this.cache.clear();
  }
}

export const sessionCache = new SessionCache();
