import { useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"

import api from "../services/api"
import UploadResume from "../components/UploadResume"

interface Resume {
  id: number
  filename: string
  created_at: string
  status: string
  score: number | null
}

interface DashboardProps {
  onLogout: () => void
}

function Dashboard({ onLogout }: DashboardProps) {
  const navigate = useNavigate()

  const [resumes, setResumes] = useState<Resume[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [deleteId, setDeleteId] = useState<number | null>(null)
  const [deleting, setDeleting] = useState(false)

  const fetchResumes = async () => {
    try {
      setError("")

      const response = await api.get("/resumes/")

      setResumes(response.data)
    } catch (err: any) {
      console.error("Failed to load resumes:", err)

      if (err?.response?.status === 401) {
        onLogout()
        navigate("/login", { replace: true })
        return
      }

      setError("Unable to load your resumes.")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchResumes()
  }, [])

  const handleDelete = async () => {
    if (deleteId === null) {
      return
    }

    try {
      setDeleting(true)

      await api.delete(`/resumes/${deleteId}`)

      setResumes((current) =>
        current.filter((resume) => resume.id !== deleteId)
      )

      setDeleteId(null)
    } catch (err: any) {
      console.error("Delete failed:", err)

      if (err?.response?.status === 401) {
        onLogout()
        navigate("/login", { replace: true })
        return
      }

      setError("Unable to delete this resume.")
    } finally {
      setDeleting(false)
    }
  }

  const handleLogout = () => {
    onLogout()
    navigate("/login", { replace: true })
  }

  const scoredResumes = resumes.filter(
  (resume) =>
    resume.status === "analyzed" &&
    resume.score !== null
)

    const analyzedCount = resumes.filter(
      (resume) => resume.status === "analyzed"
    ).length

    const pendingCount = resumes.filter(
      (resume) => resume.status !== "analyzed"
    ).length

    const averageScore =
      scoredResumes.length > 0
        ? Math.round(
            scoredResumes.reduce(
              (total, resume) => total + (resume.score ?? 0),
              0
            ) / scoredResumes.length
          )
        : 0

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
          <button className="sidebar-nav-item active">
            <span>⌂</span>
            Dashboard
          </button>
        </nav>

        <div className="sidebar-bottom">
          <button
            className="sidebar-logout"
            onClick={handleLogout}
            type="button"
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
            <h1>Resume Dashboard</h1>
          </div>

          <button
            className="topbar-logout"
            onClick={handleLogout}
            type="button"
          >
            Logout
          </button>
        </header>

        <section className="dashboard-content">
          <div className="welcome-section">
            <div>
              <h2>Welcome back 👋</h2>
              <p>
                Upload your resume and let AI help you improve your career
                profile.
              </p>
            </div>
          </div>

          <section className="stats-grid">
            <div className="stat-card">
              <div className="stat-icon purple">CV</div>

              <div>
                <span>Total Resumes</span>
                <strong>{resumes.length}</strong>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon green">✓</div>

              <div>
                <span>Analyzed</span>
                <strong>{analyzedCount}</strong>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon orange">◷</div>

              <div>
                <span>Pending</span>
                <strong>{pendingCount}</strong>
              </div>
            </div>

            <div className="stat-card">
              <div className="stat-icon blue">★</div>

              <div>
                <span>Average Score</span>
                <strong>
                  {analyzedCount > 0 ? `${averageScore}%` : "—"}
                </strong>
              </div>
            </div>
          </section>

          <section className="upload-section">
            <div className="section-heading">
              <div>
                <p className="eyebrow">ANALYSIS</p>
                <h2>Upload a new resume</h2>
                <p>
                  Upload a PDF or DOCX file up to 5 MB.
                </p>
              </div>
            </div>

            <UploadResume onUploadSuccess={fetchResumes} />
          </section>

          <section className="resume-section">
            <div className="section-heading">
              <div>
                <p className="eyebrow">YOUR DOCUMENTS</p>
                <h2>Your Resumes</h2>
              </div>

              <span className="resume-count">
                {resumes.length} document
                {resumes.length !== 1 ? "s" : ""}
              </span>
            </div>

            {loading && (
              <div className="empty-state">
                <div className="loading-spinner" />
                <p>Loading your resumes...</p>
              </div>
            )}

            {!loading && error && (
              <div className="error-card">
                {error}
              </div>
            )}

            {!loading && !error && resumes.length === 0 && (
              <div className="empty-state">
                <div className="empty-icon">CV</div>

                <h3>No resumes yet</h3>

                <p>
                  Upload your first resume to start your AI analysis.
                </p>
              </div>
            )}

            {!loading && resumes.length > 0 && (
              <div className="resume-list">
                {resumes.map((resume) => (
                  <div
                    className="resume-card"
                    key={resume.id}
                  >
                    <div className="resume-file-icon">
                      PDF
                    </div>

                    <div className="resume-info">
                      <h3>{resume.filename}</h3>

                      <p>
                        Uploaded{" "}
                        {new Date(
                          resume.created_at
                        ).toLocaleString()}
                      </p>
                    </div>

                    <div className="resume-status">
                      <span
                        className={
                          resume.status === "analyzed"
                            ? "status-badge analyzed"
                            : "status-badge pending"
                        }
                      >
                        {resume.status === "analyzed"
                          ? "Analyzed"
                          : "Pending"}
                      </span>
                    </div>

                    <div className="resume-score">
                      {resume.score !== null ? (
                        <>
                          <strong>{resume.score}</strong>
                          <span>/ 100</span>
                        </>
                      ) : (
                        <span>Not analyzed</span>
                      )}
                    </div>

                    <div className="resume-actions">
                        {resume.status === "analyzed" ? (
                          <button
                            type="button"
                            className="action-button primary"
                            onClick={() =>
                              navigate(`/analysis/${resume.id}`)
                            }
                          >
                            View Analysis
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="action-button primary"
                            onClick={() =>
                              navigate(`/analysis/${resume.id}`)
                            }
                          >
                            Analyze Resume
                          </button>
                        )}

                        <button
                          type="button"
                          className="action-button secondary"
                          onClick={() =>
                            navigate(`/job-match/${resume.id}`)
                          }
                        >
                          Job Match
                        </button>

                        <button
                          type="button"
                          className="action-button danger"
                          onClick={() => setDeleteId(resume.id)}
                        >
                          Delete
                        </button>
                      </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </section>
      </main>

      {deleteId !== null && (
        <div
          className="modal-overlay"
          onClick={() => {
            if (!deleting) {
              setDeleteId(null)
            }
          }}
        >
          <div
            className="delete-modal"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="delete-modal-icon">!</div>

            <h2>Delete resume?</h2>

            <p>
              This will permanently remove the resume and its
              analysis. This action cannot be undone.
            </p>

            <div className="modal-actions">
              <button
                type="button"
                className="modal-cancel"
                onClick={() => setDeleteId(null)}
                disabled={deleting}
              >
                Cancel
              </button>

              <button
                type="button"
                className="modal-delete"
                onClick={handleDelete}
                disabled={deleting}
              >
                {deleting ? "Deleting..." : "Delete Resume"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default Dashboard