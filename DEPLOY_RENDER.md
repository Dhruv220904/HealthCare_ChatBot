# Deploying HealthGenie to Render

This document gives a copy/paste-ready, step-by-step guide to deploy this repo to Render.com. The repo already contains a `Procfile`, a `start.sh` script, and a minimal `requirements.txt`.

Follow these steps in Render's dashboard.

1) Create a new Web Service
  - Connect your GitHub account and select the repository: `Dhruv220904/HealthCare_ChatBot`
  - Branch: `master`

2) Runtime / Environment
  - Environment: `Python` (choose a recent Python version, e.g. 3.11)
  - Plan: choose based on your needs (Starter for testing; larger if you run heavy models)

3) Build Command (Render UI field)
  Paste exactly:

  pip install -r requirements.txt && python -m spacy download en_core_web_sm

  Notes:
  - This installs Python dependencies and downloads the spaCy English model during the build.
  - We also included a runtime fallback: `start.sh` will attempt to download the model if needed.

4) Start Command (Render UI field) — REQUIRED
  Paste exactly:

  bash start.sh

  Explanation:
  - `start.sh` downloads the spaCy model if missing and then launches Gunicorn with the Flask `app` callable in `app.py`.
  - Alternatively (if you prefer not to use the script) use:
    gunicorn app:app --bind 0.0.0.0:$PORT --workers 4

5) Environment variables
  - In the Render service settings, add the environment variables your app needs. Set secrets here (do NOT commit them). At minimum, the following placeholders exist in the repo:
    - `OPENAI_API_KEY` (if using OpenAI)
    - `OLLAMA_BASE_URL` (if using a local LLM server)
    - `OTHER_API_KEY`

6) Persistence (important)
  - The app writes Chroma vectorstores to `vectorstores/chroma_index` and uploaded PDFs to `uploads/`. Render's filesystem is ephemeral and will be reset on deploy/rollback by default.
  - Options:
    - Enable a Persistent Disk in the Render service settings (recommended if you want vectorstore/uploads to survive deploys). Choose a size (e.g. 5 GB) and mount it.
    - Accept rebuilding the vectorstore on startup. The app will create the vectorstore from `Data/medical_vault.txt` if the persist dir is missing. Note: building embeddings may be slow and may require additional memory/time.

7) Deploy
  - Click `Create Web Service` / `Deploy` in Render.
  - Watch the build logs. If the build fails during `pip install`, update `requirements.txt` with pinned versions and retry.

8) Logs & verification
  - Open the Live Logs in Render. You should see `gunicorn` start and bind to the provided $PORT, and Flask serving the app.
  - Confirm the root URL (`/`) loads and try POSTing to `/chat` with a JSON body:

    {
      "query": "I have headache and fever, what should I do?"
    }

9) Troubleshooting notes
  - If spaCy model download fails in build, `start.sh` will try at runtime; check logs for `python -m spacy download en_core_web_sm` progress and errors.
  - If you get memory or timeout issues while building the vectorstore, consider:
    - Increasing instance size for the build
    - Pre-building vectorstore in CI and committing (or uploading) the `vectorstores/chroma_index` to a persistent store
  - If your LLM is local (ollama) make sure the deployed instance can reach it or use a hosted LLM endpoint.

If you'd like, I can also:
- Pin dependency versions in `requirements.txt` (recommended for reproducible builds)
- Add a short `README` section and a one-click `render.yaml` (I can prepare but you'll need to confirm the disk spec and API token to create the service via the Render API)
