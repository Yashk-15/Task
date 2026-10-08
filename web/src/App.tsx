// Routes define which page appears for each browser URL.
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { Toaster } from "react-hot-toast";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { OfflineBanner } from "./components/OfflineBanner";
import { Spinner } from "./components/ui";
import { WelcomePage } from "./pages/WelcomePage";
import { LoginPage, RegisterPage } from "./pages/AuthPages";
import { DashboardPage } from "./pages/DashboardPage";
import { ProjectsPage } from "./pages/ProjectsPage";
import { TasksPage } from "./pages/TasksPage";
import { ProjectDetailPage } from "./pages/ProjectDetailPage";
import { NotFoundPage } from "./pages/NotFoundPage";

// Handles the root path "/":
// Authenticated users go to /dashboard; first-time/guest visitors land on /welcome
function RootRedirect() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="grid min-h-screen place-items-center bg-slate-50">
        <Spinner label="Loading workspace..." />
      </div>
    );
  }

  return <Navigate to={user ? "/dashboard" : "/welcome"} replace />;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <OfflineBanner />
        <Toaster position="top-right" />
        <Routes>
          {/* Welcome Screen with animated loader */}
          <Route path="/welcome" element={<WelcomePage />} />

          {/* Public Auth Routes */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Protected Application Routes */}
          <Route element={<ProtectedRoute />}>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/projects" element={<ProjectsPage />} />
            <Route path="/projects/:id" element={<ProjectDetailPage />} />
            <Route path="/tasks" element={<TasksPage />} />
          </Route>

          {/* Root Redirect: dashboard if logged in, welcome if new */}
          <Route path="/" element={<RootRedirect />} />

          {/* 404 Fallback */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

