// src/utils/AppError.ts
//
// A custom error class for "expected" errors that our code intentionally throws.
// For example: "Email already registered" (409), "Invalid credentials" (401).
//
// Why extend Error?
// Express's error handler receives `err` as type `unknown`. By creating a class,
// we can use `instanceof AppError` to reliably detect our own errors and format
// them differently from unexpected crashes.

export interface AppErrorDetail {
  field: string;
  message: string;
}

export class AppError extends Error {
  // HTTP status code, e.g. 400, 401, 404, 409, 500
  public readonly statusCode: number;

  // Optional array of per-field validation errors for detailed feedback.
  // Example: [{ field: "email", message: "Invalid email format" }]
  public readonly errors: AppErrorDetail[] | undefined;

  constructor(
    message: string,
    statusCode: number,
    errors?: AppErrorDetail[]
  ) {
    super(message); // Call the base Error constructor with the message
    this.statusCode = statusCode;
    // Explicitly set to undefined when not provided — needed for
    // exactOptionalPropertyTypes compatibility in the error handler.
    this.errors = errors;

    // Fix the prototype chain — required when extending built-in classes in TS
    Object.setPrototypeOf(this, AppError.prototype);
  }
}
