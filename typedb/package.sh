#!/bin/bash
set -e

# --- Configuration ---
# These variables define the source container, the database to be packaged,
# and the names for the output artifact and the data directory.
SOURCE_CONTAINER_NAME="knowledgeplatform-typedb"
DATABASE_NAME="knowledgeplatform"
ARTIFACT_NAME="knowledgeplatform-data.tar.gz"
DATA_DIR="knowledgeplatform-data"
# --- End Configuration ---

echo "--- Starting TypeDB Data Packaging ---"

# 1. Find the running container's ID
CONTAINER_ID=$(docker ps -qf "name=${SOURCE_CONTAINER_NAME}")
if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Container '${SOURCE_CONTAINER_NAME}' not found."
    exit 1
fi
echo "Found container '${SOURCE_CONTAINER_NAME}' with ID: ${CONTAINER_ID}"

# 2. Clean up previous attempts and create a fresh data directory
echo "Creating a clean data directory: ./${DATA_DIR}"
rm -rf "./${DATA_DIR}"
mkdir -p "./${DATA_DIR}"

# 3. Export the database schema and data into the data directory
echo "Exporting database '${DATABASE_NAME}' and copying to host..."
# The >&2 redirects the export command's progress output to stderr,
# ensuring only the clean tar stream goes to stdout and through the pipe.
docker exec "$CONTAINER_ID" sh -c ' \
  /opt/typedb-all-linux-x86_64/typedb server export \
    --port=1729 \
    --database='"$DATABASE_NAME"' \
    --schema=/tmp/schema.tql \
    --data=/tmp/data.typedb >&2 && \
  tar -c -C /tmp schema.tql data.typedb \
' | tar -x -v -C "./${DATA_DIR}"

# 4. Create a compressed tarball of the data directory
echo "Creating data archive: ${ARTIFACT_NAME}..."
# The -C flag changes the directory, so the paths in the tarball are relative
tar -czvf "${ARTIFACT_NAME}" -C "./${DATA_DIR}" .
# Remove the data directory
rm -rf "./${DATA_DIR}"

# --- Finished ---
echo "--- Packaging complete! ---"
echo "To use this data, share '${ARTIFACT_NAME}', 'docker-compose.yml', and 'entrypoint.sh'."
echo "The user should extract the archive and run 'docker-compose up'."

