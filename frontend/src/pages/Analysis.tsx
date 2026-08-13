import { useEffect, useState, type CSSProperties } from "react"
import { Link, useNavigate, useParams } from "react-router-dom"
import AppShell from "../components/AppShell"
import api from "../services/api"

interface Sections {
  contact: boolean
  summary: boolean
  skills: boolean
  experience: boolean
  education: boolean
  projects: boolean
}

interface AnalysisData {
  score: number
  skills: string[]
  sections: Sections
  suggestions: string[]
}

interface AnalysisResponse {
  resume_id: number
  filename: string
  analysis: AnalysisData
}

const sectionLabels: Record<keyof Sections, string> = {
  contact: "Contact Information",
  summary: "Professional Summary",
  skills: "Technical Skills",
  experience: "Work Experience",
  education: "Education",
  projects: "Projects",
}

function Analysis() {
  const { resumeId } = useParams<{ resumeId: string }>()
  const navigate = useNavigate()

  const [data, setData] = useState<AnalysisResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [analyzing, setAnalyzing] = useState(false)
  const [error, setError] = useState("")

  const logout = () => {
    localStorage.removeItem("access_token")
    navigate("/login", { replace: true })
  }

  useEffect(() => {
    if (!resumeId) {
      setError("Invalid resume.")
      setLoading(false)
      return
    }

    const loadAnalysis = async () => {
      try {
        setLoading(true)
        setError("")

        try {
          const response = await api.get<AnalysisResponse>(
            `/analysis/${resumeId}`,
          )

          setData(response.data)
          return
        } catch (getError: unknown) {
          const status = (
            getError as {
              response?: {
                status?: number
              }
            }
          ).response?.status

          if (status !== 404) {
            throw getError
          }
        }

        setAnalyzing(true)

        const response = await api.post<AnalysisResponse>(
          `/analysis/${resumeId}`,
        )

        setData(response.data)
      } catch (err) {
        console.error("Analysis failed:", err)
        setError("Unable to analyze this resume.")
      } finally {
        setAnalyzing(false)
        setLoading(false)
      }
    }

    void loadAnalysis()
  }, [resumeId])

  if (loading || analyzing) {
    return (
      <AppShell onLogout={logout}>
        <div className="analysis-loading-page">
          <div className="analysis-loader">
            <div className="loader-ring" />

            <h2>
              {analyzing
                ? "Analyzing your resume..."
                : "Loading analysis..."}
            </h2>

            <p>
              Our AI is reviewing your resume and preparing
              your results.
            </p>
          </div>
        </div>
      </AppShell>
    )
  }

  if (error || !data) {
    return (
      <AppShell onLogout={logout}>
        <div className="analysis-error-page">

          <div className="analysis-error-card">
            <div className="error-icon">!</div>

            

            <p>{error || "Analysis could not be loaded."}</p>

            <Link className="primary-button" to="/">
              Return to Dashboard
            </Link>
          </div>
        </div>
      </AppShell>
    )
  }

  const { analysis } = data

  const score = Math.max(
    0,
    Math.min(100, Number(analysis.score) || 0),
  )

  const sectionEntries = Object.entries(
    sectionLabels,
  ) as [keyof Sections, string][]

  const presentSections = sectionEntries.filter(
    ([key]) => analysis.sections[key],
  ).length

  const scoreLabel =
    score >= 80
      ? "Excellent Resume"
      : score >= 65
        ? "Good Resume"
        : score >= 50
          ? "Needs Improvement"
          : "Needs Work"

  const scoreClass =
    score >= 80
      ? "score-excellent"
      : score >= 65
        ? "score-good"
        : score >= 50
          ? "score-average"
          : "score-low"

  return (
    <AppShell onLogout={logout}>
      <div className="analysis-page">
        <div className="analysis-header-row">
          <div>
            <Link
              className="analysis-dashboard-button"
              to="/"
            >
              ← Return to Dashboard
            </Link>
            <div className="suggestions-footer">
                {analysis.suggestions.length} improvement{" "}
                {analysis.suggestions.length === 1
                  ? "area"
                  : "areas"}{" "}
                identified
              </div>

            <div className="eyebrow">
              AI RESUME ANALYZER
            </div>

            <h1 className="analysis-page-title">
              Resume Analysis
            </h1>

            <p className="analysis-page-subtitle">
              Detailed insights and recommendations for your resume.
            </p>
          </div>

          <div className="analysis-file-badge">
            <span className="file-badge-icon">PDF</span>
            <span>{data.filename}</span>
          </div>
        </div>

        <div className="analysis-layout">
          <main className="analysis-main">
            <section className="glass-card analysis-top-card">
              <div>
                <div className="card-eyebrow">
                  OVERALL RESUME SCORE
                </div>

                <h2 className="score-heading">
                  Your resume is{" "}
                  <span className={scoreClass}>
                    {scoreLabel.toLowerCase()}
                  </span>
                </h2>

                <p className="score-description">
                  Your score is based on resume content,
                  technical skills, structure and important
                  professional sections.
                </p>
              </div>

              <div className="score-wrapper">
                <div
                  className={`score-circle ${scoreClass}`}
                  style={
                    {
                      "--score": `${score * 3.6}deg`,
                    } as CSSProperties
                  }
                >
                  <div className="score-inner">
                    <strong>{score}</strong>
                    <span>/100</span>
                  </div>
                </div>

                <span className={`score-status ${scoreClass}`}>
                  {scoreLabel}
                </span>
              </div>
            </section>

            <div className="analysis-grid">
              <section className="glass-card analysis-card">
                <div className="card-header">
                  <div className="card-icon purple">
                    ✦
                  </div>

                  <div>
                    <h2>Skills Detected</h2>
                    <p>
                      Technologies found in your resume
                    </p>
                  </div>
                </div>

                {analysis.skills.length > 0 ? (
                  <div className="skills">
                    {analysis.skills.map(
                      (skill: string) => (
                        <span
                          className="skill"
                          key={skill}
                        >
                          {skill}
                        </span>
                      ),
                    )}
                  </div>
                ) : (
                  <div className="empty-analysis">
                    No recognized skills found.
                  </div>
                )}

                <div className="card-footer">
                  <span>{analysis.skills.length}</span>{" "}
                  skills detected
                </div>
              </section>

              <section className="glass-card analysis-card">
                <div className="card-header">
                  <div className="card-icon blue">
                    ◎
                  </div>

                  <div>
                    <h2>Resume Structure</h2>
                    <p>
                      Important sections in your resume
                    </p>
                  </div>
                </div>

                <div className="section-list">
                  {sectionEntries.map(
                    ([key, label]) => {
                      const present =
                        analysis.sections[key]

                      return (
                        <div
                          className="section-item"
                          key={key}
                        >
                          <span>{label}</span>

                          <span
                            className={
                              present
                                ? "section-check"
                                : "section-missing"
                            }
                          >
                            {present ? "✓" : "−"}
                          </span>
                        </div>
                      )
                    },
                  )}
                </div>

                <div className="card-footer">
                  <span>{presentSections}</span>/
                  {sectionEntries.length} sections present
                </div>
              </section>
            </div>

            <section className="ai-card">
              <div className="ai-glow" />

              <div className="ai-icon">✦</div>

              <div>
                <div className="ai-label">
                  AI INSIGHT
                </div>

                <h2>
                  Your resume has been analyzed
                </h2>

                <p>
                  We reviewed your resume content,
                  technical skills and professional
                  structure to identify areas that can
                  improve your profile.
                </p>
              </div>
            </section>
          </main>

          <aside className="analysis-sidebar">
            <section className="glass-card suggestions-card">
              <div className="card-header">
                <div className="card-icon orange">
                  ✧
                </div>

                <div>
                  <h2>Top Suggestions</h2>
                  <p>Improve your resume score</p>
                </div>
              </div>

              {analysis.suggestions.length > 0 ? (
                <div className="suggestion-list">
                  {analysis.suggestions.map(
                    (
                      suggestion: string,
                      index: number,
                    ) => (
                      <div
                        className="suggestion"
                        key={`${suggestion}-${index}`}
                      >
                        <span className="suggestion-number">
                          {String(index + 1).padStart(2, "0")}
                        </span>

                        <p>{suggestion}</p>
                      </div>
                    ),
                  )}
                </div>
              ) : (
                <div className="empty-analysis">
                  Your resume looks great. No major
                  suggestions at this time.
                </div>
              )}

              
            </section>

            
          </aside>
        </div>
      </div>
    </AppShell>
  )
}

export default Analysis