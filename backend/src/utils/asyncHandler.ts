// src/utils/asyncHandler.ts
//
// Problem: if an async route handler throws (or returns a rejected promise),
// Express 4 won't catch it automatically — the server hangs.
// (Express 5 handles this natively, but wrapping is still a clean pattern.)
//
// Solution: this tiny wrapper catches any error from async functions and
// forwards it to Express's error handler via `next(err)`.
//
// Usage:
//   router.get("/me", asyncHandler(async (req, res) => { ... }));

import type { Request, Response, NextFunction, RequestHandler } from "express";

// The type says: "take an async function that receives req, res, next"
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
): RequestHandler => {
  return (req, res, next) => {
    // .catch(next) sends any thrown error straight to the error handler
    fn(req, res, next).catch(next);
  };
};
