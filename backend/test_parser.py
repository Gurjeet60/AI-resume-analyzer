from app.services.resume_parser import extract_resume_text


file_path = "uploads/resumes/5eabac2b-59a4-4794-ae13-34e4fddeedc2.pdf"

try:
    text = extract_resume_text(file_path)

    print("\n========== EXTRACTED RESUME TEXT ==========\n")
    print(text)
    print("\n========== END ==========\n")

except Exception as exc:
    print(f"ERROR: {exc}")
