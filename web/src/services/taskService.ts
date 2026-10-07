// Task API calls are kept separate from page presentation logic.
import api from "./api";
import type { ApiResponse, Pagination, Priority, Task, TaskInput, TaskStatus } from "../types";
type ListParams = { projectId?: string; search?: string; status?: TaskStatus | ""; priority?: Priority | ""; page?: number; limit?: number };
export const taskService = {
  list: async ({ search, status, priority, ...pagination }: ListParams) => {
    // Empty dropdown values mean "all", so they must not become `status=` in the URL.
    const params = { ...pagination, ...(search ? { search } : {}), ...(status ? { status } : {}), ...(priority ? { priority } : {}) };
    const r = await api.get<ApiResponse<Task[]>>("/tasks", { params });
    return { tasks: r.data.data ?? [], pagination: r.data.pagination as Pagination };
  },
  create: async (data: Required<Pick<TaskInput, "projectId">> & TaskInput) => (await api.post<ApiResponse<{ task: Task }>>("/tasks", data)).data.data!.task,
  update: async (id: string, data: TaskInput) => (await api.put<ApiResponse<{ task: Task }>>(`/tasks/${id}`, data)).data.data!.task,
  remove: (id: string) => api.delete<ApiResponse<never>>(`/tasks/${id}`).then((r) => r.data),
};
