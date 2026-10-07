// src/middleware/validate.ts
//
// Reusable middleware factory for request body validation.
//
// How it works:
//   1. You pass in a Zod schema.
//   2. It returns a middleware function.
//   3. That middleware calls schema.parse(req.body).
//   4. If validation passes, `req.body` is replaced with the cleaned/transformed
//      data (e.g. trimmed strings, lowercased emails) and the request continues.
//   5. If validation fails, the ZodError is forwarded to the error handler,
//      which converts it into a readable 400 response.
//
// Usage:
//   router.post("/register", validate(registerSchema), controller);

import type { Request, Response, NextFunction } from "express";
import type { ZodSchema } from "zod";

export const validate =
  (schema: ZodSchema) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    try {
      // .parse() throws a ZodError if validation fails.
      // It also returns the transformed data (e.g. lowercased email).
      req.body = schema.parse(req.body) as unknown;
      next(); // Validation passed — continue to the next middleware/controller
    } catch (err) {
      next(err); // Forward ZodError to the central error handler
    }
  };
