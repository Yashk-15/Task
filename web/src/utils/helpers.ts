// Small display and error helpers are reused by multiple pages.
import type { AxiosError } from "axios";
import type { ApiErrorField } from "../types";
export const dateInput = (value?: string | null) => value ? value.slice(0, 10) : "";
export const showDate = (value?: string | null) => value ? new Date(value).toLocaleDateString() : "—";
export const errorMessage = (error: unknown) => (error as AxiosError<{ message?: string }>).response?.data?.message ?? "Something went wrong. Please try again.";
export const backendErrors = (error: unknown): ApiErrorField[] => (error as AxiosError<{ errors?: ApiErrorField[] }>).response?.data?.errors ?? [];
