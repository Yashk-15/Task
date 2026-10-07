// src/validators/task.validator.ts
//
// Validation schemas for Task resources:
//   - createTaskSchema: validates new task creation payloads
//   - updateTaskSchema: validates task updates (forbids updating projectId)
//   - taskQuerySchema  : validates query parameters for filtering, sorting, and pagination

import { z } from "zod";
import { dateStringSchema } from "./common.validator.js";

// Valid enum values matching Priority and TaskStatus in schema.prisma
export const priorityEnum = z.enum(["LOW", "MEDIUM", "HIGH"]);
export const taskStatusEnum = z.enum(["PENDING", "IN_PROGRESS", "COMPLETED"]);

// ─── Create Task Schema ──────────────────────────────────────────────────────
export const createTaskSchema = z.object({
  projectId: z.string().uuid("projectId must be a valid UUID"),
  name: z
    .string()
    .trim()
    .min(1, "Task name is required")
    .max(150, "Task name must be at most 150 characters"),
  description: z
    .string()
    .max(2000, "Description must be at most 2000 characters")
    .optional()
    .nullable(),
  priority: priorityEnum.default("MEDIUM"),
  status: taskStatusEnum.default("PENDING"),
  dueDate: dateStringSchema.optional().nullable(),
});

// ─── Update Task Schema ──────────────────────────────────────────────────────
// All fields optional, and projectId cannot be changed
export const updateTaskSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(1, "Task name cannot be empty")
      .max(150, "Task name must be at most 150 characters")
      .optional(),
    description: z
      .string()
      .max(2000, "Description must be at most 2000 characters")
      .optional()
      .nullable(),
    priority: priorityEnum.optional(),
    status: taskStatusEnum.optional(),
    dueDate: dateStringSchema.optional().nullable(),
    projectId: z.any().optional(), // captured to explicitly disallow modification
  })
  .refine((data) => data.projectId === undefined, {
    message: "projectId cannot be changed",
    path: ["projectId"],
  });

// ─── Task List Query Schema ──────────────────────────────────────────────────
export const taskQuerySchema = z.object({
  search: z.string().trim().optional(),
  status: taskStatusEnum.optional(),
  priority: priorityEnum.optional(),
  projectId: z.string().uuid("projectId must be a valid UUID").optional(),
  page: z.coerce.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.coerce
    .number()
    .int()
    .min(1, "Limit must be at least 1")
    .max(100, "Limit cannot exceed 100")
    .default(20),
  sortBy: z
    .enum(["createdAt", "name", "dueDate", "endDate"])
    .default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
});

export type CreateTaskInput = z.infer<typeof createTaskSchema>;
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>;
export type TaskQueryInput = z.infer<typeof taskQuerySchema>;
