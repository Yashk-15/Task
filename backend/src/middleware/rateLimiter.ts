// src/middleware/rateLimiter.ts
//
// Rate limiting protects authentication endpoints from brute-force attacks.
// Without it, an attacker could try millions of passwords per second.
//
// This limiter allows 10 attempts per IP per 15 minutes.
// After that, the IP gets a 429 "Too Many Requests" response.

import rateLimit from "express-rate-limit";

export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes in milliseconds
  max: 10,                   // Maximum 10 requests per IP within that window
  standardHeaders: true,     // Adds X-RateLimit-* headers to responses
  legacyHeaders: false,      // Don't send old X-RateLimit-Limit headers

  // Custom response when the limit is exceeded (instead of the default HTML page)
  handler: (_req, res) => {
    res.status(429).json({
      success: false,
      message: "Too many attempts, please try again later",
    });
  },
});
