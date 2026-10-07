// src/services/auth.service.ts
//
// Services contain the BUSINESS LOGIC — the "what does registering actually do?"
// Controllers just call services and format the HTTP response.
// This separation makes code easier to test and maintain.

import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import type { StringValue } from "ms";
import prisma from "../config/prisma.js";
import { env } from "../config/env.js";
import { AppError } from "../utils/AppError.js";
import type { RegisterInput, LoginInput } from "../validators/auth.validator.js";

// ─── Helper: Generate JWT ─────────────────────────────────────────────────────
// Creates a signed token that contains the user's ID.
// The token is valid for however long JWT_EXPIRES_IN says (e.g. "1d").
const signToken = (userId: string): string => {
  // @types/jsonwebtoken 9.x requires expiresIn to be StringValue | number.
  // StringValue is a branded string type from the `ms` library.
  // env.JWT_EXPIRES_IN is a plain string like "1d" which is compatible at
  // runtime — we just need a type assertion to satisfy the compiler.
  return jwt.sign(
    { userId },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN as StringValue }
  );
};

// ─── Safe user type (without passwordHash) ───────────────────────────────────
type UserRow = {
  id: string;
  fullName: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
};

// Removes passwordHash from a user object so we never send it in a response.
const omitPassword = (user: UserRow) => {
  const { passwordHash: _removed, ...safeUser } = user;
  return safeUser;
};

// ─── Register ─────────────────────────────────────────────────────────────────
export const registerUser = async (data: RegisterInput) => {
  // Step 1: Check if the email is already taken.
  // We do this manually before inserting to give a clear 409 error.
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email },
  });

  if (existingUser) {
    throw new AppError("Email already registered", 409);
  }

  // Step 2: Hash the password.
  // bcrypt's cost factor 12 means the hashing takes ~250ms — slow enough
  // to deter attackers trying millions of passwords, fast enough for users.
  const passwordHash = await bcrypt.hash(data.password, 12);

  // Step 3: Save the new user to the database.
  const user = await prisma.user.create({
    data: {
      fullName: data.fullName,
      email: data.email,
      passwordHash, // Store the hash, NEVER the plain-text password
    },
  });

  // Step 4: Create a JWT so the user is instantly logged in after registering.
  const token = signToken(user.id);

  return { user: omitPassword(user), token };
};

// ─── Login ────────────────────────────────────────────────────────────────────
export const loginUser = async (data: LoginInput) => {
  // Step 1: Find the user by email.
  const user = await prisma.user.findUnique({
    where: { email: data.email },
  });

  // SECURITY: We use the SAME error message whether the email doesn't exist
  // OR the password is wrong. This prevents "user enumeration" — an attacker
  // testing emails to discover which accounts exist.
  if (!user) {
    throw new AppError("Invalid email or password", 401);
  }

  // Step 2: Compare the submitted password against the stored hash.
  // bcrypt.compare() is slow by design (same cost as hashing) and safe
  // against timing attacks.
  const passwordMatch = await bcrypt.compare(data.password, user.passwordHash);

  if (!passwordMatch) {
    throw new AppError("Invalid email or password", 401); // Same message!
  }

  // Step 3: Issue a JWT.
  const token = signToken(user.id);

  return { user: omitPassword(user), token };
};

// ─── Get Current User ─────────────────────────────────────────────────────────
// Used by the /me endpoint. Fetches from DB so we return current data.
export const getCurrentUser = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    // select only the fields we want — passwordHash is deliberately excluded
    select: {
      id: true,
      fullName: true,
      email: true,
      createdAt: true,
    },
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  return user;
};
