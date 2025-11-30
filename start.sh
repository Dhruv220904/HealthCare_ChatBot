#!/usr/bin/env bash
set -e

# Ensure spaCy English model is available. Ignore errors if download fails.
python -m spacy download en_core_web_sm || true

# Start Gunicorn
exec gunicorn app:app --bind 0.0.0.0:$PORT --workers 4
