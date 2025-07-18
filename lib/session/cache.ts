import type { CacheLayer, CacheStorageType } from './types';

/**
 * Multi-layer cache implementation for session management
 * Provides memory, localStorage, and sessionStorage caching
 */
export class MultiLayerCache implements CacheLayer {
  private readonly memoryCache = new Map<string, { value: unknown; expires: number }>();
  private readonly defaultTTL = 15 * 60 * 1000; // 15 minutes

  constructor(
    private readonly config: {
      readonly enableMemory: boolean;
      readonly enableLocalStorage: boolean;
      readonly enableSessionStorage: boolean;
      readonly memoryTTL: number;
      readonly localStorageTTL: number;
      readonly sessionStorageTTL: number;
    }
  ) {
    // Clean up expired memory cache every 5 minutes
    setInterval(() => this.cleanupMemoryCache(), 5 * 60 * 1000);
  }

  async get(key: string): Promise<unknown | null> {
    // Try memory cache first (fastest)
    if (this.config.enableMemory) {
      const memoryResult = this.getFromMemory(key);
      if (memoryResult !== null) {
        return memoryResult;
      }
    }

    // Try localStorage (persistent across tabs)
    if (this.config.enableLocalStorage) {
      const localResult = await this.getFromStorage(key, 'localStorage');
      if (localResult !== null) {
        // Backfill memory cache
        if (this.config.enableMemory) {
          this.setInMemory(key, localResult, this.config.memoryTTL);
        }
        return localResult;
      }
    }

    // Try sessionStorage (tab-specific)
    if (this.config.enableSessionStorage) {
      const sessionResult = await this.getFromStorage(key, 'sessionStorage');
      if (sessionResult !== null) {
        // Backfill higher-level caches
        if (this.config.enableMemory) {
          this.setInMemory(key, sessionResult, this.config.memoryTTL);
        }
        if (this.config.enableLocalStorage) {
          await this.setInStorage(key, sessionResult, 'localStorage', this.config.localStorageTTL);
        }
        return sessionResult;
      }
    }

    return null;
  }

  async set(key: string, value: unknown, ttl?: number): Promise<void> {
    const effectiveTTL = ttl || this.defaultTTL;

    // Set in all enabled cache layers
    const promises: Promise<void>[] = [];

    if (this.config.enableMemory) {
      this.setInMemory(key, value, Math.min(effectiveTTL, this.config.memoryTTL));
    }

    if (this.config.enableLocalStorage) {
      promises.push(
        this.setInStorage(key, value, 'localStorage', Math.min(effectiveTTL, this.config.localStorageTTL))
      );
    }

    if (this.config.enableSessionStorage) {
      promises.push(
        this.setInStorage(key, value, 'sessionStorage', Math.min(effectiveTTL, this.config.sessionStorageTTL))
      );
    }

    await Promise.all(promises);
  }

  async delete(key: string): Promise<void> {
    const promises: Promise<void>[] = [];

    // Remove from memory cache
    if (this.config.enableMemory) {
      this.memoryCache.delete(key);
    }

    // Remove from storage layers
    if (this.config.enableLocalStorage) {
      promises.push(this.removeFromStorage(key, 'localStorage'));
    }

    if (this.config.enableSessionStorage) {
      promises.push(this.removeFromStorage(key, 'sessionStorage'));
    }

    await Promise.all(promises);
  }

  async clear(): Promise<void> {
    const promises: Promise<void>[] = [];

    // Clear memory cache
    if (this.config.enableMemory) {
      this.memoryCache.clear();
    }

    // Clear storage layers
    if (this.config.enableLocalStorage) {
      promises.push(this.clearStorage('localStorage'));
    }

    if (this.config.enableSessionStorage) {
      promises.push(this.clearStorage('sessionStorage'));
    }

    await Promise.all(promises);
  }

  async has(key: string): Promise<boolean> {
    // Check memory cache first
    if (this.config.enableMemory && this.hasInMemory(key)) {
      return true;
    }

    // Check storage layers
    if (this.config.enableLocalStorage && await this.hasInStorage(key, 'localStorage')) {
      return true;
    }

    if (this.config.enableSessionStorage && await this.hasInStorage(key, 'sessionStorage')) {
      return true;
    }

    return false;
  }

  // Memory cache operations
  private getFromMemory(key: string): unknown | null {
    const item = this.memoryCache.get(key);
    if (!item) return null;

    if (Date.now() > item.expires) {
      this.memoryCache.delete(key);
      return null;
    }

    return item.value;
  }

  private setInMemory(key: string, value: unknown, ttl: number): void {
    this.memoryCache.set(key, {
      value,
      expires: Date.now() + ttl
    });
  }

  private hasInMemory(key: string): boolean {
    const item = this.memoryCache.get(key);
    if (!item) return false;

    if (Date.now() > item.expires) {
      this.memoryCache.delete(key);
      return false;
    }

    return true;
  }

  private cleanupMemoryCache(): void {
    const now = Date.now();
    for (const [key, item] of this.memoryCache.entries()) {
      if (now > item.expires) {
        this.memoryCache.delete(key);
      }
    }
  }

  // Storage operations
  private async getFromStorage(key: string, storageType: CacheStorageType): Promise<unknown | null> {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return null;

      const item = storage.getItem(this.getCacheKey(key));
      if (!item) return null;

      const parsed = JSON.parse(item) as { value: unknown; expires: number };
      if (Date.now() > parsed.expires) {
        storage.removeItem(this.getCacheKey(key));
        return null;
      }

      return parsed.value;
    } catch (error) {
      console.warn(`Cache storage error for ${storageType}:`, error);
      return null;
    }
  }

  private async setInStorage(
    key: string, 
    value: unknown, 
    storageType: CacheStorageType, 
    ttl: number
  ): Promise<void> {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return;

      const item = {
        value,
        expires: Date.now() + ttl
      };

      storage.setItem(this.getCacheKey(key), JSON.stringify(item));
    } catch (error) {
      console.warn(`Cache storage error for ${storageType}:`, error);
    }
  }

  private async removeFromStorage(key: string, storageType: CacheStorageType): Promise<void> {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return;

      storage.removeItem(this.getCacheKey(key));
    } catch (error) {
      console.warn(`Cache storage error for ${storageType}:`, error);
    }
  }

  private async hasInStorage(key: string, storageType: CacheStorageType): Promise<boolean> {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return false;

      const item = storage.getItem(this.getCacheKey(key));
      if (!item) return false;

      const parsed = JSON.parse(item) as { expires: number };
      if (Date.now() > parsed.expires) {
        storage.removeItem(this.getCacheKey(key));
        return false;
      }

      return true;
    } catch (error) {
      console.warn(`Cache storage error for ${storageType}:`, error);
      return false;
    }
  }

  private async clearStorage(storageType: CacheStorageType): Promise<void> {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return;

      // Only clear our cache keys
      const keys = Object.keys(storage);
      const cacheKeys = keys.filter(key => key.startsWith('pos_session_'));
      
      for (const key of cacheKeys) {
        storage.removeItem(key);
      }
    } catch (error) {
      console.warn(`Cache storage error for ${storageType}:`, error);
    }
  }

  private getStorage(storageType: CacheStorageType): Storage | null {
    try {
      switch (storageType) {
        case 'localStorage':
          return typeof window !== 'undefined' ? window.localStorage : null;
        case 'sessionStorage':
          return typeof window !== 'undefined' ? window.sessionStorage : null;
        default:
          return null;
      }
    } catch {
      return null;
    }
  }

  private getCacheKey(key: string): string {
    return `pos_session_${key}`;
  }

  // Cache statistics for monitoring
  getCacheStats(): {
    memory: { size: number; keys: readonly string[] };
    storage: { localStorage: number; sessionStorage: number };
  } {
    const memoryKeys = Array.from(this.memoryCache.keys());
    
    const localStorageCount = this.getStorageKeyCount('localStorage');
    const sessionStorageCount = this.getStorageKeyCount('sessionStorage');

    return {
      memory: {
        size: this.memoryCache.size,
        keys: memoryKeys
      },
      storage: {
        localStorage: localStorageCount,
        sessionStorage: sessionStorageCount
      }
    };
  }

  private getStorageKeyCount(storageType: CacheStorageType): number {
    try {
      const storage = this.getStorage(storageType);
      if (!storage) return 0;

      const keys = Object.keys(storage);
      return keys.filter(key => key.startsWith('pos_session_')).length;
    } catch {
      return 0;
    }
  }
}
