#!/bin/bash
set -e

# --- Configuration ---
SOURCE_CONTAINER_NAME="knowledgeplatform-typedb"
DATABASE_NAME="knowledgeplatform"
DATA_DIR="data"
ARTIFACT_NAME="knowledgeplatform-data.tar.gz"
# --- End Configuration ---

echo "--- Starting TypeDB Data Packaging ---"

# 1. Find the running container's ID
CONTAINER_ID=$(docker ps -qf "name=${SOURCE_CONTAINER_NAME}")
if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Container '${SOURCE_CONTAINER_NAME}' not found."
    exit 1
fi
echo "Found container '${SOURCE_CONTAINER_NAME}' with ID: ${CONTAINER_ID}"

# 2. Create the data directory if it doesn't exist
echo "Creating data directory: ./${DATA_DIR}"
mkdir -p "./${DATA_DIR}"

# 3. FIX: Ensure the current user owns the data directory.
# This is crucial on Linux, where Docker may create the directory as root.
echo "Ensuring you have ownership of the data directory..."
sudo chown -R $(id -u):$(id -g) "./${DATA_DIR}"

# 4. Create a temporary directory for the export
EXPORT_DIR=$(mktemp -d)
echo "Exporting database '${DATABASE_NAME}' to ${EXPORT_DIR}..."

# 5. Export the database schema and data into the temp directory
docker exec "$CONTAINER_ID" sh -c ' \
  /opt/typedb-all-linux-x86_64/typedb server export \
    --port=1729 \
    --database='"$DATABASE_NAME"' \
    --schema=/tmp/schema.tql \
    --data=/tmp/data.typedb >&2 && \
  tar -c -C /tmp schema.tql data.typedb \
' | tar -x -v -C "${EXPORT_DIR}"

# 6. Create a compressed tarball of the data inside the ./data directory
ARTIFACT_PATH="./${DATA_DIR}/${ARTIFACT_NAME}"
echo "Creating data archive: ${ARTIFACT_PATH}..."
tar -czvf "${ARTIFACT_PATH}" -C "${EXPORT_DIR}" .

# 7. Clean up the temporary export directory
rm -rf "${EXPORT_DIR}"

# --- Finished ---
echo "--- Packaging complete! ---"
echo "The archive is located at ${ARTIFACT_PATH}"
echo "You can now run 'docker-compose up' to start the database."

