#!/bin/bash
set -e

NAMESPACE="codebase-wiki"

GEMINI_API_KEY="${GEMINI_API_KEY:-changeme}"
OPENAI_API_KEY="${OPENAI_API_KEY:-changeme}"
ENCRYPTION_SECRET_KEY="${ENCRYPTION_SECRET_KEY:-changeme32charssecretkey123456}"
NEXTAUTH_SECRET="${NEXTAUTH_SECRET:-changeme}"

echo "Applying secrets ke namespace ${NAMESPACE}..."

kubectl create secret generic app-secrets \
  --namespace="${NAMESPACE}" \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=postgres \
  --from-literal=DATABASE_URL="postgresql://postgres:postgres@database-svc:5432/codebase_wiki" \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --from-literal=GEMINI_API_KEY="${GEMINI_API_KEY}" \
  --from-literal=ENCRYPTION_SECRET_KEY="${ENCRYPTION_SECRET_KEY}" \
  --from-literal=NEXTAUTH_SECRET="${NEXTAUTH_SECRET}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets applied successfully!"
