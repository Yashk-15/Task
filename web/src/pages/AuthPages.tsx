// Login and registration share a focused, modern, and user-friendly layout.
import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import toast from "react-hot-toast";
import { useAuth } from "../context/AuthContext";
import { backendErrors, errorMessage } from "../utils/helpers";
import { Button, Input, Spinner } from "../components/ui";

const passwordRule = z
  .string()
  .min(8, "Use at least 8 characters")
  .regex(/[A-Za-z]/, "Include a letter")
  .regex(/\d/, "Include a number");

const loginSchema = z.object({
  email: z.string().email("Enter a valid email"),
  password: z.string().min(1, "Password is required"),
});

const registerSchema = loginSchema
  .extend({
    fullName: z.string().min(2, "Full name needs at least 2 characters"),
    password: passwordRule,
    confirmPassword: z.string(),
  })
  .refine((v) => v.password === v.confirmPassword, {
    message: "Passwords must match",
    path: ["confirmPassword"],
  });

function Shell({
  title,
  subtitle,
  children,
  footer,
}: {
  title: string;
  subtitle: string;
  children: React.ReactNode;
  footer: React.ReactNode;
}) {
  return (
    <main className="grid min-h-screen place-items-center bg-slate-50 p-4 sm:p-6">
      <section className="w-full max-w-md rounded-2xl bg-white p-7 shadow-sm ring-1 ring-slate-200">
        {/* App Logo */}
        <div className="mb-4 flex items-center justify-between">
          <Link to="/welcome" className="flex items-center gap-2 text-indigo-700 transition hover:opacity-80">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-sm">
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2.5"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <span className="font-bold tracking-tight text-slate-900">ProjectFlow</span>
          </Link>
          <Link to="/welcome" className="text-xs font-semibold text-slate-500 hover:text-indigo-600">
            ← Welcome
          </Link>
        </div>

        <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
        <p className="mt-1 text-sm text-slate-500">{subtitle}</p>

        <div className="mt-6">{children}</div>

        <p className="mt-5 text-center text-sm text-slate-600">{footer}</p>
      </section>
    </main>
  );
}

// Password field with eye toggle
function PasswordField({
  label,
  error,
  inputProps,
}: {
  label: string;
  error?: string;
  inputProps: React.InputHTMLAttributes<HTMLInputElement>;
}) {
  const [show, setShow] = useState(false);

  return (
    <div className="space-y-1">
      <label className="block text-sm font-medium text-slate-700">{label}</label>
      <div className="relative">
        <Input type={show ? "text" : "password"} className="pr-10" {...inputProps} />
        <button
          type="button"
          tabIndex={-1}
          onClick={() => setShow(!show)}
          className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
          aria-label={show ? "Hide password" : "Show password"}
        >
          {show ? (
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"
              />
            </svg>
          ) : (
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
              />
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
              />
            </svg>
          )}
        </button>
      </div>
      {error && <p className="text-xs text-rose-600">{error}</p>}
    </div>
  );
}

// Cold-start helper note shown when network request takes over 2.5 seconds
function ColdStartNotice({ active }: { active: boolean }) {
  const [showSlowNotice, setShowSlowNotice] = useState(false);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    if (active) {
      timer = setTimeout(() => setShowSlowNotice(true), 2500);
    } else {
      setShowSlowNotice(false);
    }
    return () => clearTimeout(timer);
  }, [active]);

  if (!showSlowNotice) return null;

  return (
    <div className="mt-3 rounded-lg border border-amber-200 bg-amber-50 p-2.5 text-center text-xs text-amber-800 animate-fadeIn">
      <span>Connecting to cloud server... On free tier, waking up can take up to 60s ☕</span>
    </div>
  );
}

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<z.infer<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
  });

  const submit = async (v: z.infer<typeof loginSchema>) => {
    try {
      await login(v.email, v.password);
      toast.success("Welcome back!");
      navigate("/dashboard");
    } catch (e) {
      backendErrors(e).forEach(({ field, message }) =>
        setError(field as "email" | "password", { message }),
      );
      toast.error(errorMessage(e));
    }
  };

  return (
    <Shell
      title="Welcome back"
      subtitle="Log in to access your projects and tasks."
      footer={
        <>
          New here?{" "}
          <Link className="font-semibold text-indigo-600 hover:underline" to="/register">
            Create an account
          </Link>
        </>
      }
    >
      <form className="space-y-4" onSubmit={handleSubmit(submit)}>
        <div className="space-y-1">
          <label className="block text-sm font-medium text-slate-700">Email</label>
          <Input type="email" placeholder="name@company.com" {...register("email")} />
          {errors.email?.message && (
            <p className="text-xs text-rose-600">{errors.email.message}</p>
          )}
        </div>

        <PasswordField
          label="Password"
          error={errors.password?.message}
          inputProps={{
            placeholder: "••••••••",
            ...register("password"),
          }}
        />

        <Button className="w-full" type="submit" disabled={isSubmitting}>
          {isSubmitting ? <Spinner label="Signing in..." /> : "Sign in"}
        </Button>

        <ColdStartNotice active={isSubmitting} />
      </form>
    </Shell>
  );
}

export function RegisterPage() {
  const { register: signUp } = useAuth();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<z.infer<typeof registerSchema>>({
    resolver: zodResolver(registerSchema),
  });

  const submit = async (v: z.infer<typeof registerSchema>) => {
    try {
      await signUp(v.fullName, v.email, v.password);
      toast.success("Account created successfully!");
      navigate("/dashboard");
    } catch (e) {
      backendErrors(e).forEach(({ field: name, message }) =>
        setError(name as keyof z.infer<typeof registerSchema>, { message }),
      );
      toast.error(errorMessage(e));
    }
  };

  return (
    <Shell
      title="Create your account"
      subtitle="Start managing projects and collaborating with ease."
      footer={
        <>
          Already registered?{" "}
          <Link className="font-semibold text-indigo-600 hover:underline" to="/login">
            Sign in
          </Link>
        </>
      }
    >
      <form className="space-y-3.5" onSubmit={handleSubmit(submit)}>
        <div className="space-y-1">
          <label className="block text-sm font-medium text-slate-700">Full Name</label>
          <Input type="text" placeholder="John Doe" {...register("fullName")} />
          {errors.fullName?.message && (
            <p className="text-xs text-rose-600">{errors.fullName.message}</p>
          )}
        </div>

        <div className="space-y-1">
          <label className="block text-sm font-medium text-slate-700">Email Address</label>
          <Input type="email" placeholder="name@company.com" {...register("email")} />
          {errors.email?.message && (
            <p className="text-xs text-rose-600">{errors.email.message}</p>
          )}
        </div>

        <PasswordField
          label="Password (min 8 chars, letter + number)"
          error={errors.password?.message}
          inputProps={{
            placeholder: "••••••••",
            ...register("password"),
          }}
        />

        <PasswordField
          label="Confirm Password"
          error={errors.confirmPassword?.message}
          inputProps={{
            placeholder: "••••••••",
            ...register("confirmPassword"),
          }}
        />

        <Button className="w-full mt-2" type="submit" disabled={isSubmitting}>
          {isSubmitting ? <Spinner label="Creating account..." /> : "Create account"}
        </Button>

        <ColdStartNotice active={isSubmitting} />
      </form>
    </Shell>
  );
}

