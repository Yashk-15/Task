// src/validators/project.validator.ts
//
// Validation schemas for Project resources:
//   - createProjectSchema: validates new project creation payloads
//   - updateProjectSchema: validates project updates
//   - projectQuerySchema : validates query parameters for filtering, sorting, and pagination

import { z } from "zod";
import { dateStringSchema } from "./common.validator.js";

// Valid status values matching ProjectStatus enum in schema.prisma
export const projectStatusEnum = z.enum([
  "NOT_STARTED",
  "IN_PROGRESS",
  "COMPLETED",
]);

// ─── Create Project Schema ───────────────────────────────────────────────────
export const createProjectSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(1, "Name is required")
      .max(150, "Name must be at most 150 characters"),
    description: z
      .string()
      .max(2000, "Description must be at most 2000 characters")
      .optional()
      .nullable(),
    status: projectStatusEnum.default("NOT_STARTED"),
    startDate: dateStringSchema.optional().nullable(),
    endDate: dateStringSchema.optional().nullable(),
  })
  .refine(
    (data) => {
      // If both dates are provided, ensure endDate is not before startDate
      if (data.startDate && data.endDate) {
        return new Date(data.endDate) >= new Date(data.startDate);
      }
      return true;
    },
    {
      message: "endDate must not be before startDate",
      path: ["endDate"],
    }
  );

// ─── Update Project Schema ───────────────────────────────────────────────────
export const updateProjectSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(1, "Name cannot be empty")
      .max(150, "Name must be at most 150 characters")
      .optional(),
    description: z
      .string()
      .max(2000, "Description must be at most 2000 characters")
      .optional()
      .nullable(),
    status: projectStatusEnum.optional(),
    startDate: dateStringSchema.optional().nullable(),
    endDate: dateStringSchema.optional().nullable(),
  })
  .refine(
    (data) => {
      // Enforce the rule when both dates are present in the update payload
      // (Single-date comparison is handled in project.service.ts using stored values)
      if (data.startDate && data.endDate) {
        return new Date(data.endDate) >= new Date(data.startDate);
      }
      return true;
    },
    {
      message: "endDate must not be before startDate",
      path: ["endDate"],
    }
  );

// ─── Project List Query Schema ───────────────────────────────────────────────
export const projectQuerySchema = z.object({
  search: z.string().trim().optional(),
  status: projectStatusEnum.optional(),
  page: z.coerce.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.coerce
    .number()
    .int()
    .min(1, "Limit must be at least 1")
    .max(100, "Limit cannot exceed 100")
    .default(20),
  sortBy: z
    .enum(["createdAt", "name", "endDate", "dueDate"])
    .default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
});

export type CreateProjectInput = z.infer<typeof createProjectSchema>;
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>;
export type ProjectQueryInput = z.infer<typeof projectQuerySchema>;
