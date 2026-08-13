import type { ReactNode } from "react"

interface AppShellProps {
  children: ReactNode
  onLogout: () => void
}

function AppShell({ children, onLogout }: AppShellProps) {
  return (
    <div className="dashboard-page">
      <aside className="dashboard-sidebar">
        <div className="sidebar-brand">
          <div className="brand-logo">AI</div>

          <div>
            <strong>ResumeAI</strong>
            <span>Analyzer</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          <a
            href="/"
            className="sidebar-nav-item"
          >
            <span>⌂</span>
            Dashboard
          </a>
        </nav>

        <div className="sidebar-bottom">
          <button
            type="button"
            className="sidebar-logout"
            onClick={onLogout}
          >
            <span>↪</span>
            Logout
          </button>
        </div>
      </aside>

      <main className="dashboard-main">
        <header className="dashboard-topbar">
          <div>
            <p className="eyebrow">WORKSPACE</p>
            <h1>ResumeAI</h1>
          </div>

          <button
            type="button"
            className="topbar-logout"
            onClick={onLogout}
          >
            Logout
          </button>
        </header>

        {children}
      </main>
    </div>
  )
}

export default AppShell