// Dashboard has one small, typed endpoint.
import api from "./api";
import type { ApiResponse, DashboardStats } from "../types";
export const dashboardService = { get: async () => (await api.get<ApiResponse<DashboardStats>>("/dashboard")).data.data! };
