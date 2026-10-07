// src/validators/common.validator.ts
//
// Common reusable validation schemas used across multiple routes:
//   - idParamSchema: validates route parameters containing a UUID (e.g. /:id)
//   - isValidDateString: validates that a string parses to a valid calendar date

import { z } from "zod";

/**
 * Validates route parameters where `:id` must be a valid UUID v4.
 * Returns 400 Bad Request if the parameter is malformed.
 */
export const idParamSchema = z.object({
  id: z.string().uuid("Invalid ID format, must be a valid UUID"),
});

/**
 * Validates that an optional date string is a valid ISO or parseable date string.
 */
export const dateStringSchema = z
  .string()
  .refine((val) => !isNaN(Date.parse(val)) && !isNaN(new Date(val).getTime()), {
    message: "Must be a valid date format",
  });
