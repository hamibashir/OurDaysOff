"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { User, AuthResponse } from "@/types/api";
import { apiClient } from "@/lib/api-client";

import { sessionCache } from "@/lib/session-cache";

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: { name: string; email: string; password: string; handle?: string }) => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshUser = async () => {
    try {
      const response = await apiClient.get<{ data: User }>("/auth/me");
      setUser(response.data);
    } catch (err) {
      setUser(null);
    }
  };

  useEffect(() => {
    async function loadUser() {
      try {
        await refreshUser();
      } finally {
        setIsLoading(false);
      }
    }
    loadUser();
  }, []);

  const login = async (email: string, password: string) => {
    sessionCache.clear();
    const res = await apiClient.post<AuthResponse>("/auth/login", { email, password });
    apiClient.setAuthToken(res.data.token);
    setUser(res.data.user);
  };

  const register = async (data: { name: string; email: string; password: string; handle?: string }) => {
    sessionCache.clear();
    const res = await apiClient.post<AuthResponse>("/auth/register", data);
    apiClient.setAuthToken(res.data.token);
    setUser(res.data.user);
  };

  const logout = async () => {
    try {
      await apiClient.post("/auth/logout");
    } catch (e) {
      // Ignore network/auth logout errors
    } finally {
      sessionCache.clear();
      apiClient.clearAuthToken();
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, login, register, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
