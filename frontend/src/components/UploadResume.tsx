import { useRef, useState } from "react"
import api from "../services/api"

interface UploadResumeProps {
  onUploadSuccess: () => void
}

function UploadResume({ onUploadSuccess }: UploadResumeProps) {
  const [file, setFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [message, setMessage] = useState("")
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const handleFileChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const selectedFile = event.target.files?.[0]

    if (!selectedFile) {
      setFile(null)
      return
    }

    const extension = selectedFile.name
      .toLowerCase()
      .split(".")
      .pop()

    if (extension !== "pdf" && extension !== "docx") {
      setFile(null)
      setMessage("Please select a PDF or DOCX file.")
      return
    }

    if (selectedFile.size > 5 * 1024 * 1024) {
      setFile(null)
      setMessage("File size must be less than 5 MB.")
      return
    }

    setFile(selectedFile)
    setMessage("")
  }

  const handleUpload = async () => {
    if (!file) {
      setMessage("Please select a resume first.")
      return
    }

    const token = localStorage.getItem("access_token")

    if (!token) {
      setMessage("Your session has expired. Please login again.")
      return
    }

    try {
      setUploading(true)
      setMessage("Uploading resume...")

      const formData = new FormData()
      formData.append("file", file)

      await api.post("/resumes/upload", formData)

      setMessage("Resume uploaded successfully!")
      setFile(null)

      if (fileInputRef.current) {
        fileInputRef.current.value = ""
      }

      await onUploadSuccess()
    } catch (error: any) {
      console.error("UPLOAD ERROR:", error)

      if (error.response?.status === 401) {
        localStorage.removeItem("access_token")
        window.location.href = "/login"
        return
      }

      setMessage(
        error.response?.data?.detail ||
        "Failed to upload resume."
      )
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="upload-section">

      <div className="upload-header">
        <div>
          <h2>Upload Resume</h2>
          <p>PDF or DOCX · Maximum 5 MB</p>
        </div>

        <button
          type="button"
          className="upload-button"
          onClick={handleUpload}
          disabled={!file || uploading}
        >
          {uploading ? "Uploading..." : "Upload Resume"}
        </button>
      </div>

      <div className="upload-box">

        <div className="upload-box-title">
          Upload Resume
        </div>

        <div className="upload-box-subtitle">
          PDF or DOCX · Maximum 5 MB
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept=".pdf,.docx"
          onChange={handleFileChange}
        />

        {file && (
          <div className="selected-file">
            Selected: <strong>{file.name}</strong>
          </div>
        )}

      </div>

      {message && (
        <p className="upload-message">
          {message}
        </p>
      )}

    </div>
  )
}

export default UploadResume