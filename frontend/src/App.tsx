import { useState } from "react"
import { Navigate, Route, Routes } from "react-router-dom"

import Login from "./pages/Login"
import Dashboard from "./pages/Dashboard"
import Analysis from "./pages/Analysis"
import JobMatch from "./pages/JobMatch"

function App() {
  const [token, setToken] = useState<string | null>(
    localStorage.getItem("access_token")
  )

  const isAuthenticated = Boolean(token)

  const handleLogin = (newToken: string) => {
    localStorage.setItem("access_token", newToken)
    setToken(newToken)
  }

  const handleLogout = () => {
    localStorage.removeItem("access_token")
    setToken(null)
  }

  return (
    <Routes>
      <Route
        path="/login"
        element={
          isAuthenticated ? (
            <Navigate to="/" replace />
          ) : (
            <Login onLogin={handleLogin} />
          )
        }
      />

      <Route
        path="/"
        element={
          isAuthenticated ? (
            <Dashboard onLogout={handleLogout} />
          ) : (
            <Navigate to="/login" replace />
          )
        }
      />

      <Route
        path="/analysis/:resumeId"
        element={
          isAuthenticated ? (
            <Analysis />
          ) : (
            <Navigate to="/login" replace />
          )
        }
      />

      <Route
        path="/job-match/:resumeId"
        element={
          isAuthenticated ? (
            <JobMatch />
          ) : (
            <Navigate to="/login" replace />
          )
  }
/>

      <Route
        path="*"
        element={<Navigate to={isAuthenticated ? "/" : "/login"} replace />}
      />

    </Routes>
  )
}

export default App