// src/services/task.service.ts
//
// Business logic for Task management.
//
// 🔒 CRITICAL SECURITY RULES:
// 1. Every query must verify project ownership via `project: { userId }`.
// 2. Creating a task must verify the target `projectId` belongs to the authenticated user.
// 3. Return 404 (never 403) if a task or project does not exist or belongs to someone else.

import { Prisma } from "@prisma/client";
import prisma from "../config/prisma.js";
import { AppError } from "../utils/AppError.js";
import type {
  CreateTaskInput,
  UpdateTaskInput,
  TaskQueryInput,
} from "../validators/task.validator.js";

/**
 * Standard project relation projection included in task queries.
 */
const projectSelect = {
  select: {
    id: true,
    name: true,
  },
};

/**
 * Retrieve a paginated and filtered list of tasks belonging to projects owned by the user.
 */
export const getTasks = async (userId: string, query: TaskQueryInput) => {
  const { page, limit, search, status, priority, projectId, sortBy, order } = query;
  const skip = (page - 1) * limit;

  // Build the filter condition: strictly owned projects only
  const where: Prisma.TaskWhereInput = {
    project: {
      userId, // Tasks must belong to projects owned by this user
    },
    ...(projectId && { projectId }),
    ...(status && { status }),
    ...(priority && { priority }),
    ...(search && {
      name: {
        contains: search,
        mode: "insensitive",
      },
    }),
  };

  // Ensure sortBy column is valid on Task model (fallback to createdAt)
  const validSortFields = ["createdAt", "name", "dueDate"];
  const sortField = validSortFields.includes(sortBy) ? sortBy : "createdAt";

  const [tasks, total] = await Promise.all([
    prisma.task.findMany({
      where,
      skip,
      take: limit,
      orderBy: { [sortField]: order },
      include: {
        project: projectSelect,
      },
    }),
    prisma.task.count({ where }),
  ]);

  const totalPages = Math.ceil(total / limit) || 1;

  return {
    tasks,
    pagination: {
      page,
      limit,
      total,
      totalPages,
    },
  };
};

/**
 * Fetch a single task by ID, verifying ownership through its parent project.
 */
export const getTaskById = async (userId: string, id: string) => {
  const task = await prisma.task.findFirst({
    where: {
      id,
      project: {
        userId, // Verifies parent project ownership
      },
    },
    include: {
      project: projectSelect,
    },
  });

  if (!task) {
    throw new AppError("Task not found", 404);
  }

  return task;
};

/**
 * Create a new task within a project owned by the user.
 */
export const createTask = async (userId: string, data: CreateTaskInput) => {
  // Step 1: Verify the parent project exists and is owned by the user
  const project = await prisma.project.findFirst({
    where: {
      id: data.projectId,
      userId,
    },
  });

  if (!project) {
    throw new AppError("Project not found", 404);
  }

  // Step 2: Create the task
  const task = await prisma.task.create({
    data: {
      projectId: data.projectId,
      name: data.name,
      description: data.description ?? null,
      priority: data.priority,
      status: data.status,
      dueDate: data.dueDate ? new Date(data.dueDate) : null,
    },
    include: {
      project: projectSelect,
    },
  });

  return task;
};

/**
 * Update an existing task. Ownership is verified via the parent project.
 * Note: `projectId` cannot be modified (guaranteed by validator).
 */
export const updateTask = async (
  userId: string,
  id: string,
  data: UpdateTaskInput
) => {
  // Step 1: Verify the task belongs to a project owned by this user
  const existingTask = await prisma.task.findFirst({
    where: {
      id,
      project: {
        userId,
      },
    },
  });

  if (!existingTask) {
    throw new AppError("Task not found", 404);
  }

  // Step 2: Update the task fields
  const updatedTask = await prisma.task.update({
    where: { id },
    data: {
      ...(data.name !== undefined && { name: data.name }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.priority !== undefined && { priority: data.priority }),
      ...(data.status !== undefined && { status: data.status }),
      ...(data.dueDate !== undefined && {
        dueDate: data.dueDate ? new Date(data.dueDate) : null,
      }),
    },
    include: {
      project: projectSelect,
    },
  });

  return updatedTask;
};

/**
 * Delete a task. Ownership is verified via the parent project.
 */
export const deleteTask = async (userId: string, id: string) => {
  const existingTask = await prisma.task.findFirst({
    where: {
      id,
      project: {
        userId,
      },
    },
  });

  if (!existingTask) {
    throw new AppError("Task not found", 404);
  }

  await prisma.task.delete({
    where: { id },
  });

  return { message: "Task deleted successfully" };
};
