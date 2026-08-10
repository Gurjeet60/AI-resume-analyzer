import { useState } from "react"
import api from "../services/api"

interface UploadResumeProps {
  onUploadSuccess: () => void
}

function UploadResume({ onUploadSuccess }: UploadResumeProps) {
  const [file, setFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [message, setMessage] = useState("")

  const handleFileChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const selectedFile = event.target.files?.[0]

    if (!selectedFile) {
      return
    }

    const allowedTypes = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ]

    if (!allowedTypes.includes(selectedFile.type)) {
      setMessage("Please select a PDF or DOCX file.")
      setFile(null)
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

    try {
      setUploading(true)
      setMessage("Uploading resume...")

      const formData = new FormData()
      formData.append("file", file)

      await api.post("/resumes/upload", formData, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })

      setMessage("Resume uploaded successfully!")
      setFile(null)

      onUploadSuccess()
    } catch (error) {
      console.error(error)
      setMessage("Failed to upload resume.")
    } finally {
      setUploading(false)
    }
  }

  return (
    <div>
      <h2>Upload Resume</h2>

      <input
        type="file"
        accept=".pdf,.docx"
        onChange={handleFileChange}
      />

      {file && (
        <p>
          Selected file: <strong>{file.name}</strong>
        </p>
      )}

      <button
        onClick={handleUpload}
        disabled={!file || uploading}
      >
        {uploading ? "Uploading..." : "Upload Resume"}
      </button>

      {message && <p>{message}</p>}
    </div>
  )
}

export default UploadResume