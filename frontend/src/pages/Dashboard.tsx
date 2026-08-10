import { useEffect, useState } from "react"
import api from "../services/api"
import UploadResume from "../components/UploadResume"

interface Resume {
  id: number
  filename: string
  created_at: string
  status: string
  score: number | null
}

function Dashboard() {
  const [resumes, setResumes] = useState<Resume[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  useEffect(() => {
    fetchResumes()
  }, [])

  const fetchResumes = async () => {
    try {
      const response = await api.get("/resumes/")
      setResumes(response.data)
    } catch (error) {
      console.error(error)
      setError("Unable to load resumes")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h1>Resume Dashboard</h1>

      <p>Welcome to your AI Resume Analyzer.</p>

     <UploadResume onUploadSuccess={fetchResumes} />

      <h2>Your Resumes</h2>

      {loading && <p>Loading resumes...</p>}

      {error && <p>{error}</p>}

      {!loading && !error && resumes.length === 0 && (
        <p>No resumes uploaded yet.</p>
      )}

      {!loading && !error && resumes.length > 0 && (
        <div>
          {resumes.map((resume) => (
            <div key={resume.id}>
              <h3>{resume.filename}</h3>

              <p>
                Status: {resume.status}
              </p>

              <p>
                Score: {resume.score ?? "Not analyzed"}
              </p>

              <p>
                Uploaded:{" "}
                {new Date(resume.created_at).toLocaleString()}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default Dashboard