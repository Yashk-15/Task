// Shared TypeScript types mirror the response shapes returned by the API.
export type ProjectStatus = "NOT_STARTED" | "IN_PROGRESS" | "COMPLETED";
export type TaskStatus = "PENDING" | "IN_PROGRESS" | "COMPLETED";
export type Priority = "LOW" | "MEDIUM" | "HIGH";

export interface User { id: string; fullName: string; email: string; createdAt?: string }
export interface Project {
  id: string; name: string; description: string | null; status: ProjectStatus;
  startDate: string | null; endDate: string | null; createdAt: string; taskCount: number;
}
export interface Task {
  id: string; projectId: string; name: string; description: string | null;
  priority: Priority; status: TaskStatus; dueDate: string | null; createdAt: string;
  project?: { id: string; name: string };
}
export interface Pagination { page: number; limit: number; total: number; totalPages: number }
export interface ApiErrorField { field: string; message: string }
export interface ApiResponse<T> { success: boolean; message?: string; data?: T; errors?: ApiErrorField[]; pagination?: Pagination }
export interface DashboardStats { totalProjects: number; totalTasks: number; completedTasks: number; pendingTasks: number; projectsInProgress: number }
export type ProjectInput = { name: string; description?: string; status?: ProjectStatus; startDate?: string; endDate?: string };
export type TaskInput = { projectId?: string; name?: string; description?: string; priority?: Priority; status?: TaskStatus; dueDate?: string };
