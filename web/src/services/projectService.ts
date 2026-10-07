// Project API calls and their real backend response nesting live here.
import api from "./api";
import type { ApiResponse, Pagination, Project, ProjectInput, ProjectStatus } from "../types";
type ListParams = { search?: string; status?: ProjectStatus | ""; page?: number; limit?: number };
export const projectService = {
  list: async ({ search, status, ...pagination }: ListParams) => {
    // An empty string is not a valid backend enum, so omit unselected filters.
    const params = { ...pagination, ...(search ? { search } : {}), ...(status ? { status } : {}) };
    const r = await api.get<ApiResponse<Project[]>>("/projects", { params });
    return { projects: r.data.data ?? [], pagination: r.data.pagination as Pagination };
  },
  get: async (id: string) => (await api.get<ApiResponse<{ project: Project }>>(`/projects/${id}`)).data.data!.project,
  create: async (data: ProjectInput) => (await api.post<ApiResponse<{ project: Project }>>("/projects", data)).data.data!.project,
  update: async (id: string, data: ProjectInput) => (await api.put<ApiResponse<{ project: Project }>>(`/projects/${id}`, data)).data.data!.project,
  remove: (id: string) => api.delete<ApiResponse<never>>(`/projects/${id}`).then((r) => r.data),
};
