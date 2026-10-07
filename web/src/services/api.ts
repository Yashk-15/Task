// This is the only place that configures axios; pages use typed services instead.
import axios from "axios";
import toast from "react-hot-toast";

export const TOKEN_KEY = "project_management_token";
const api = axios.create({ baseURL: import.meta.env.VITE_API_URL, timeout: 60_000 });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (!error.response) toast.error("Cannot reach the server. Check your connection and try again.");
    const path = error.config?.url ?? "";
    if (error.response?.status === 401 && !["/auth/login", "/auth/register"].some((route) => path.includes(route))) {
      localStorage.removeItem(TOKEN_KEY);
      toast.error("Session expired, please log in again");
      window.location.assign("/login");
    }
    return Promise.reject(error);
  },
);
export default api;
