import { ApiErrorResponse } from "@/types/api";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8000/api/v1";

class ApiClient {
  private getAuthToken(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem("odo_auth_token");
  }

  public setAuthToken(token: string) {
    if (typeof window !== "undefined") {
      localStorage.setItem("odo_auth_token", token);
    }
  }

  public clearAuthToken() {
    if (typeof window !== "undefined") {
      localStorage.removeItem("odo_auth_token");
    }
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = this.getAuthToken();
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      ...(options.headers as Record<string, string>),
    };

    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const config: RequestInit = {
      ...options,
      headers,
    };

    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

    if (response.status === 401) {
      this.clearAuthToken();
      if (typeof window !== "undefined" && !window.location.pathname.startsWith("/login")) {
        window.location.href = "/login";
      }
    }

    let data: any = {};
    try {
      data = await response.json();
    } catch (e) {
      // Fallback for empty or non-JSON response body
      data = { message: response.statusText || "Server error occurred" };
    }

    if (!response.ok) {
      const message = response.status === 429
        ? "Too many requests. Please wait a moment before trying again."
        : (data as ApiErrorResponse).message || "An unexpected error occurred.";

      const error = new Error(message) as Error & {
        status: number;
        errors?: Record<string, string[]>;
      };
      error.status = response.status;
      error.errors = data.errors;
      throw error;
    }

    return data as T;
  }

  public get<T>(endpoint: string, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, { method: "GET", ...options });
  }

  public post<T>(endpoint: string, body?: unknown, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, {
      method: "POST",
      body: body ? JSON.stringify(body) : undefined,
      ...options,
    });
  }

  public put<T>(endpoint: string, body?: unknown, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, {
      method: "PUT",
      body: body ? JSON.stringify(body) : undefined,
      ...options,
    });
  }

  public delete<T>(endpoint: string, options?: RequestInit): Promise<T> {
    return this.request<T>(endpoint, { method: "DELETE", ...options });
  }

  public async upload<T>(endpoint: string, formData: FormData): Promise<T> {
    const token = this.getAuthToken();
    const headers: Record<string, string> = {
      "Accept": "application/json",
    };
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: "POST",
      headers,
      body: formData,
    });

    if (response.status === 401) {
      this.clearAuthToken();
      if (typeof window !== "undefined" && !window.location.pathname.startsWith("/login")) {
        window.location.href = "/login";
      }
    }

    let data: any = {};
    try {
      data = await response.json();
    } catch (e) {
      data = { message: response.statusText || "Server error occurred" };
    }

    if (!response.ok) {
      const message = data.message || "An unexpected error occurred.";
      throw new Error(message);
    }

    return data as T;
  }
}

export const apiClient = new ApiClient();
