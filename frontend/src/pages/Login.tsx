import { useState, type FormEvent } from "react"
import api from "../services/api"

interface LoginProps {
  onLogin: (token: string) => void
}

function Login({ onLogin }: LoginProps) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    setError("")

    if (!email.trim() || !password) {
      setError("Please enter your email and password.")
      return
    }

    try {
      setLoading(true)

      const formData = new URLSearchParams()

      formData.append("username", email.trim())
      formData.append("password", password)

      const response = await api.post("/auth/login", formData, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      })

      const accessToken = response.data?.access_token

      if (!accessToken) {
        throw new Error("No access token received from server.")
      }

      localStorage.setItem("access_token", accessToken)

      onLogin(accessToken)
    } catch (err: any) {
      console.error("Login failed:", err)

      const detail = err?.response?.data?.detail

      if (Array.isArray(detail)) {
        setError(
          detail
            .map((item: any) => item?.msg || "Invalid login information")
            .join(", ")
        )
      } else if (typeof detail === "string") {
        setError(detail)
      } else {
        setError("Unable to login. Please check your credentials.")
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-background-shape auth-shape-one" />
      <div className="auth-background-shape auth-shape-two" />

      <div className="auth-container">
        <div className="auth-brand">
          <div className="brand-logo">AI</div>

          <div>
            <h1>ResumeAI</h1>
            <p>Smart Resume Analysis</p>
          </div>
        </div>

        <div className="auth-card">
          <div className="auth-header">
            <h2>Welcome back</h2>

            <p>
              Sign in to continue analyzing and improving your resume.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="auth-form">
            <div className="form-group">
              <label htmlFor="email">Email</label>

              <input
                id="email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                disabled={loading}
              />
            </div>

            <div className="form-group">
              <div className="password-label-row">
                <label htmlFor="password">Password</label>
              </div>

              <input
                id="password"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
                autoComplete="current-password"
                disabled={loading}
              />
            </div>

            {error && (
              <div className="auth-error">
                {error}
              </div>
            )}

            <button
              type="submit"
              className="auth-submit"
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="button-spinner" />
                  Logging in...
                </>
              ) : (
                "Sign in"
              )}
            </button>
          </form>
        </div>

        <p className="auth-footer">
          AI Resume Analyzer
        </p>
      </div>
    </div>
  )
}

export default Login