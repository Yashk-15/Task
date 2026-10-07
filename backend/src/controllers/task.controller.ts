// src/controllers/task.controller.ts
//
// HTTP route handlers for Task endpoints.
// Controllers forward requests to task.service and return responses.
// Handlers are wrapped in asyncHandler to automatically forward errors to errorHandler.

import type { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler.js";
import * as taskService from "../services/task.service.js";
import type {
  CreateTaskInput,
  UpdateTaskInput,
  TaskQueryInput,
} from "../validators/task.validator.js";

// GET /api/tasks
export const getTasks = asyncHandler(async (req: Request, res: Response) => {
  const result = await taskService.getTasks(
    req.user!.id,
    req.query as unknown as TaskQueryInput
  );

  res.status(200).json({
    success: true,
    data: result.tasks,
    pagination: result.pagination,
  });
});

// GET /api/tasks/:id
export const getTask = asyncHandler(async (req: Request, res: Response) => {
  const task = await taskService.getTaskById(
    req.user!.id,
    req.params["id"] as string
  );

  res.status(200).json({
    success: true,
    data: { task },
  });
});

// POST /api/tasks
export const createTask = asyncHandler(async (req: Request, res: Response) => {
  const task = await taskService.createTask(
    req.user!.id,
    req.body as CreateTaskInput
  );

  res.status(201).json({
    success: true,
    data: { task },
  });
});

// PUT /api/tasks/:id
export const updateTask = asyncHandler(async (req: Request, res: Response) => {
  const task = await taskService.updateTask(
    req.user!.id,
    req.params["id"] as string,
    req.body as UpdateTaskInput
  );

  res.status(200).json({
    success: true,
    data: { task },
  });
});

// DELETE /api/tasks/:id
export const deleteTask = asyncHandler(async (req: Request, res: Response) => {
  const result = await taskService.deleteTask(
    req.user!.id,
    req.params["id"] as string
  );

  res.status(200).json({
    success: true,
    message: result.message,
  });
});
