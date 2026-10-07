// Typed wrappers keep HTTP details out of React components.
import api from "./api";
import type { ApiResponse, User } from "../types";
type Credentials = { email: string; password: string };
export const authService = {
  register: (data: Credentials & { fullName: string }) => api.post<ApiResponse<{ user: User; token: string }>>("/auth/register", data).then((r) => r.data),
  login: (data: Credentials) => api.post<ApiResponse<{ user: User; token: string }>>("/auth/login", data).then((r) => r.data),
  logout: () => api.post<ApiResponse<never>>("/auth/logout").then((r) => r.data),
  me: () => api.get<ApiResponse<{ user: User }>>("/auth/me").then((r) => r.data),
};
