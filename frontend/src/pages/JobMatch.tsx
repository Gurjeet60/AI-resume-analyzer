import { useState, type FormEvent } from "react"
import { Link, useNavigate, useParams } from "react-router-dom"
import api from "../services/api"
import AppShell from "../components/AppShell"

interface JobMatchResult {
  match_score: number
  matching_skills: string[]
  missing_skills: string[]
  resume_skills: string[]
  job_skills: string[]
  suggestions: string[]
}

interface JobMatchResponse {
  resume_id: number
  filename: string
  result: JobMatchResult
}

function JobMatch() {
  const { resumeId } = useParams<{ resumeId: string }>()
  const navigate = useNavigate()

  const [jobDescription, setJobDescription] = useState("")
  const [result, setResult] = useState<JobMatchResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const handleLogout = () => {
    localStorage.removeItem("access_token")
    navigate("/login", { replace: true })
  }

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    setError("")

    if (!resumeId) {
      setError("Invalid resume.")
      return
    }

    const description = jobDescription.trim()

    if (description.length < 50) {
      setError(
        "Please enter a job description with at least 50 characters.",
      )
      return
    }

    try {
      setLoading(true)
      setResult(null)

      const response = await api.post<JobMatchResponse>(
        `/job-match/${resumeId}`,
        {
          job_description: description,
        },
      )

      setResult(response.data)
    } catch (err: any) {
      console.error("Job match failed:", err)

      if (err?.response?.status === 401) {
        handleLogout()
        return
      }

      const detail = err?.response?.data?.detail

      if (typeof detail === "string") {
        setError(detail)
      } else {
        setError(
          "Unable to analyze this job description. Please try again.",
        )
      }
    } finally {
      setLoading(false)
    }
  }

  const score = result
    ? Math.max(
        0,
        Math.min(100, Number(result.result.match_score) || 0),
      )
    : 0

  const scoreLabel =
    score >= 80
      ? "Excellent Match"
      : score >= 65
        ? "Strong Match"
        : score >= 50
          ? "Moderate Match"
          : "Low Match"

  const scoreClass =
    score >= 80
      ? "score-excellent"
      : score >= 65
        ? "score-good"
        : score >= 50
          ? "score-average"
          : "score-low"

  return (
    <AppShell onLogout={handleLogout}>
      <div className="job-match-page">
        <header className="job-match-header">
          <div className="job-match-heading">
            <Link className="back-link" to="/">
              ← Dashboard
            </Link>

            <div className="eyebrow">ATS JOB MATCH</div>

            <h1>Match Your Resume</h1>

            <p>
              Compare your resume against a job description and
              discover how well your profile matches the role.
            </p>
          </div>

          <div className="job-match-resume-badge">
            <div className="job-match-resume-icon">
              CV
            </div>

            <div>
              <span>Analyzing resume</span>
              <strong>
                {result?.filename || "Selected Resume"}
              </strong>
            </div>
          </div>
        </header>

        <section className="job-match-workspace">
          <div className="job-match-input-card glass-card">
            <div className="job-match-card-title">
              <div className="job-match-card-icon purple">
                JD
              </div>

              <div>
                <h2>Job Description</h2>
                <p>
                  Paste the job description for the position
                  you're applying for.
                </p>
              </div>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="job-description-wrapper">
                <textarea
                  value={jobDescription}
                  onChange={(event) =>
                    setJobDescription(event.target.value)
                  }
                  className="job-description-input"
                  placeholder={`Paste the complete job description here...

Example:
We are looking for a Python developer with experience in FastAPI, React, Docker, AWS and PostgreSQL...`}
                  disabled={loading}
                />

                <div className="job-description-counter">
                  <span>
                    {jobDescription.length} characters
                  </span>

                  <span>Minimum 50 characters</span>
                </div>
              </div>

              {error && (
                <div className="job-match-error">
                  <span>!</span>
                  {error}
                </div>
              )}

              <button
                type="submit"
                className="job-match-submit"
                disabled={
                  loading ||
                  jobDescription.trim().length < 50
                }
              >
                {loading ? (
                  <>
                    <span className="button-spinner" />
                    Analyzing Match...
                  </>
                ) : (
                  <>
                    Analyze Job Match
                    <span className="submit-arrow">→</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {!result && !loading && (
            <div className="job-match-info-card glass-card">
              <div className="job-match-info-icon">
                ✦
              </div>

              <div className="job-match-info-content">
                <span className="job-match-info-label">
                  AI POWERED MATCHING
                </span>

                <h2>
                  See how your resume fits the role
                </h2>

                <p>
                  Our analyzer compares the technical skills
                  detected in your resume with the requirements
                  found in the job description.
                </p>
              </div>

              <div className="job-match-feature-list">
                <div>
                  <span>✓</span>
                  Matching skills
                </div>

                <div>
                  <span>✓</span>
                  Missing skills
                </div>

                <div>
                  <span>✓</span>
                  ATS compatibility score
                </div>

                <div>
                  <span>✓</span>
                  Improvement recommendations
                </div>
              </div>
            </div>
          )}
        </section>

        {loading && (
          <div className="job-match-loading glass-card">
            <div className="loader-ring" />

            <h2>Analyzing job match...</h2>

            <p>
              We're comparing your resume against the job
              requirements.
            </p>
          </div>
        )}

        {result && !loading && (
          <section className="job-match-results">
            <div className="job-match-score-card glass-card">
              <div className="job-match-score-content">
                <span className="card-eyebrow">
                  ATS COMPATIBILITY
                </span>

                <h2>
                  Your resume is{" "}
                  <span className={scoreClass}>
                    {scoreLabel.toLowerCase()}
                  </span>
                </h2>

                <p>
                  This score represents how closely the skills
                  detected in your resume match the technical
                  requirements of this job.
                </p>
              </div>

              <div className="job-match-score-visual">
                <div
                  className={`score-circle ${scoreClass}`}
                  style={
                    {
                      "--score": `${score * 3.6}deg`,
                    } as React.CSSProperties
                  }
                >
                  <div className="score-inner">
                    <strong>{score}</strong>
                    <span>/100</span>
                  </div>
                </div>

                <span
                  className={`score-status ${scoreClass}`}
                >
                  {scoreLabel}
                </span>
              </div>
            </div>

            <div className="job-match-result-grid">
              <section className="glass-card job-match-result-card">
                <div className="job-match-card-title">
                  <div className="job-match-card-icon green">
                    ✓
                  </div>

                  <div>
                    <h2>Matching Skills</h2>
                    <p>
                      Skills found in both your resume and
                      this job.
                    </p>
                  </div>
                </div>

                {result.result.matching_skills.length > 0 ? (
                  <div className="job-match-skills">
                    {result.result.matching_skills.map(
                      (skill) => (
                        <span
                          className="job-match-skill matching"
                          key={skill}
                        >
                          <span>✓</span>
                          {skill}
                        </span>
                      ),
                    )}
                  </div>
                ) : (
                  <div className="job-match-empty">
                    No matching skills detected.
                  </div>
                )}

                <div className="job-match-result-footer">
                  <strong>
                    {result.result.matching_skills.length}
                  </strong>
                  matching skills
                </div>
              </section>

              <section className="glass-card job-match-result-card">
                <div className="job-match-card-title">
                  <div className="job-match-card-icon orange">
                    !
                  </div>

                  <div>
                    <h2>Missing Skills</h2>
                    <p>
                      Skills required by the job but not
                      detected in your resume.
                    </p>
                  </div>
                </div>

                {result.result.missing_skills.length > 0 ? (
                  <div className="job-match-skills">
                    {result.result.missing_skills.map(
                      (skill) => (
                        <span
                          className="job-match-skill missing"
                          key={skill}
                        >
                          <span>+</span>
                          {skill}
                        </span>
                      ),
                    )}
                  </div>
                ) : (
                  <div className="job-match-empty">
                    No major missing skills detected.
                  </div>
                )}

                <div className="job-match-result-footer">
                  <strong>
                    {result.result.missing_skills.length}
                  </strong>
                  missing skills
                </div>
              </section>
            </div>

            <section className="glass-card job-match-recommendations">
              <div className="job-match-card-title">
                <div className="job-match-card-icon blue">
                  ✦
                </div>

                <div>
                  <h2>Recommendations</h2>
                  <p>
                    Suggestions to improve your match for
                    this position.
                  </p>
                </div>
              </div>

              <div className="job-match-suggestions">
                {result.result.suggestions.map(
                  (suggestion, index) => (
                    <div
                      className="job-match-suggestion"
                      key={`${suggestion}-${index}`}
                    >
                      <span>
                        {String(index + 1).padStart(2, "0")}
                      </span>

                      <p>{suggestion}</p>
                    </div>
                  ),
                )}
              </div>
            </section>

            <div className="job-match-bottom-actions">
              <Link
                to={`/analysis/${resumeId}`}
                className="secondary-button"
              >
                ← Resume Analysis
              </Link>

              <button
                type="button"
                className="primary-button"
                onClick={() => {
                  setResult(null)
                  setJobDescription("")
                  setError("")

                  window.scrollTo({
                    top: 0,
                    behavior: "smooth",
                  })
                }}
              >
                Analyze Another Job
              </button>
            </div>
          </section>
        )}
      </div>
    </AppShell>
  )
}

export default JobMatch