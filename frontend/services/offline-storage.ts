import { openDB, DBSchema, IDBPDatabase } from "idb";

interface OurDaysOffDB extends DBSchema {
  schedules: {
    key: string; // date
    value: { date: string; data: any; updatedAt: number };
  };
  availability: {
    key: string; // dateRange
    value: { key: string; data: any; updatedAt: number };
  };
  circles: {
    key: number; // circleId
    value: { id: number; data: any; updatedAt: number };
  };
  plans: {
    key: number; // planId
    value: { id: number; data: any; updatedAt: number };
  };
}

class OfflineStorage {
  private dbPromise: Promise<IDBPDatabase<OurDaysOffDB>> | null = null;

  private getDB() {
    if (typeof window === "undefined") return null;
    if (!this.dbPromise) {
      this.dbPromise = openDB<OurDaysOffDB>("ourdaysoff_db", 1, {
        upgrade(db) {
          if (!db.objectStoreNames.contains("schedules")) {
            db.createObjectStore("schedules", { keyPath: "date" });
          }
          if (!db.objectStoreNames.contains("availability")) {
            db.createObjectStore("availability", { keyPath: "key" });
          }
          if (!db.objectStoreNames.contains("circles")) {
            db.createObjectStore("circles", { keyPath: "id" });
          }
          if (!db.objectStoreNames.contains("plans")) {
            db.createObjectStore("plans", { keyPath: "id" });
          }
        },
      });
    }
    return this.dbPromise;
  }

  public async cacheSchedules(schedules: any[]) {
    const db = await this.getDB();
    if (!db) return;
    const tx = db.transaction("schedules", "readwrite");
    for (const s of schedules) {
      await tx.store.put({ date: s.date, data: s, updatedAt: Date.now() });
    }
    await tx.done;
  }

  public async getCachedSchedules(): Promise<any[]> {
    const db = await this.getDB();
    if (!db) return [];
    const all = await db.getAll("schedules");
    return all.map((item) => item.data);
  }

  public async clearAllCache() {
    const db = await this.getDB();
    if (!db) return;
    await db.clear("schedules");
    await db.clear("availability");
    await db.clear("circles");
    await db.clear("plans");
  }
}

export const offlineStorage = new OfflineStorage();
