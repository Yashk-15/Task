// Blocks private screens until the saved session has been restored.
import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { Spinner } from "./ui";
import { Navbar } from "./Navbar";
export function ProtectedRoute() { const { user, loading } = useAuth(); if (loading) return <div className="grid min-h-screen place-items-center"><Spinner label="Restoring your session" /></div>; if (!user) return <Navigate to="/login" replace />; return <><Navbar /><main className="mx-auto max-w-6xl p-4 sm:p-6"><Outlet /></main></>; }
