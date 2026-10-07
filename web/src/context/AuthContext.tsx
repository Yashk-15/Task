// Auth state is shared here so every protected page sees the same session.
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { authService } from "../services/authService";
import { TOKEN_KEY } from "../services/api";
import type { User } from "../types";

type AuthContextValue = { user: User | null; token: string | null; loading: boolean; login: (email: string, password: string) => Promise<void>; register: (fullName: string, email: string, password: string) => Promise<void>; logout: () => Promise<void> };
const AuthContext = createContext<AuthContextValue | null>(null);
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null); const [token, setToken] = useState<string | null>(localStorage.getItem(TOKEN_KEY)); const [loading, setLoading] = useState(true);
  useEffect(() => { if (!token) { setLoading(false); return; } authService.me().then(setUser).catch(() => { localStorage.removeItem(TOKEN_KEY); setToken(null); }).finally(() => setLoading(false)); }, [token]);
  const save = (nextUser: User, nextToken: string) => { localStorage.setItem(TOKEN_KEY, nextToken); setUser(nextUser); setToken(nextToken); };
  const login = async (email: string, password: string) => { const r = await authService.login({ email, password }); save(r.user, r.token); };
  const register = async (fullName: string, email: string, password: string) => { const r = await authService.register({ fullName, email, password }); save(r.user, r.token); };
  const logout = async () => { try { await authService.logout(); } finally { localStorage.removeItem(TOKEN_KEY); setUser(null); setToken(null); } };
  return <AuthContext.Provider value={{ user, token, loading, login, register, logout }}>{children}</AuthContext.Provider>;
}
export function useAuth() { const value = useContext(AuthContext); if (!value) throw new Error("useAuth must be used within AuthProvider"); return value; }
