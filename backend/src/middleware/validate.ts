// src/middleware/validate.ts
//
// Reusable middleware factories for validating incoming request parts:
//   - validate / validateBody : validates req.body (POST / PUT requests)
//   - validateParams          : validates req.params (e.g. UUID in /:id)
//   - validateQuery           : validates req.query (e.g. ?page=1&limit=20)
//
// If validation succeeds:
//   The parsed/cleaned data is attached back to the request object.
// If validation fails:
//   Zod throws a ZodError, which is forwarded via next(err) to the central
//   errorHandler where it becomes a 400 Bad Request response with detailed field messages.

import type { Request, Response, NextFunction } from "express";
import type { ZodSchema } from "zod";

/**
 * Validates req.body against a Zod schema.
 * Replaces req.body with the sanitized and coerced data.
 */
export const validateBody =
  (schema: ZodSchema) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body) as unknown;
      next();
    } catch (err) {
      next(err);
    }
  };

// Alias `validate` to `validateBody` for backwards compatibility with auth routes
export const validate = validateBody;

/**
 * Validates req.params against a Zod schema (e.g., verifying :id is a valid UUID).
 */
export const validateParams =
  (schema: ZodSchema) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.params = schema.parse(req.params) as Record<string, string>;
      next();
    } catch (err) {
      next(err);
    }
  };

/**
 * Validates req.query against a Zod schema (e.g., page, limit, filters, search).
 * In Express 5, req.query is a getter property on request, so we define
 * an own property on req to safely assign the validated/coerced values.
 */
export const validateQuery =
  (schema: ZodSchema) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const parsed = schema.parse(req.query);
      Object.defineProperty(req, "query", {
        value: parsed,
        writable: true,
        configurable: true,
        enumerable: true,
      });
      next();
    } catch (err) {
      next(err);
    }
  };
