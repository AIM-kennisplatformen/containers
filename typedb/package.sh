#!/bin/bash
set -e

# --- Configuration ---
SOURCE_CONTAINER_NAME="knowledgeplatform-typedb"
# The absolute path to the data folder inside the container
CONTAINER_DATA_PATH="/opt/typedb-all-linux-x86_64/server/data"
# The local directory where the final packaged data will be stored
HOST_DATA_DIR="data"
# The name of the final compressed archive
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

# 2. Create the host data directory if it doesn't exist
echo "Creating host data directory: ./${HOST_DATA_DIR}"
mkdir -p "./${HOST_DATA_DIR}"

# 3. Ensure the current user owns the data directory.
echo "Ensuring you have ownership of the data directory..."
sudo chown -R $(id -u):$(id -g) "./${HOST_DATA_DIR}"

# 4. Create a temporary directory to stage the data
TEMP_DIR=$(mktemp -d)
echo "Staging data in temporary directory: ${TEMP_DIR}..."

# 5. Copy the entire data folder from the container to the temporary directory
docker cp "${CONTAINER_ID}:${CONTAINER_DATA_PATH}" "${TEMP_DIR}"
echo "Successfully copied '${CONTAINER_DATA_PATH}' from container."

# 6. Create a compressed tarball from the copied data
ARTIFACT_PATH="./${HOST_DATA_DIR}/${ARTIFACT_NAME}"
echo "Creating data archive: ${ARTIFACT_PATH}..."
# The '-C' flag changes the directory, so the tarball contains the 'data' folder itself.
tar -czvf "${ARTIFACT_PATH}" -C "${TEMP_DIR}" .

# 7. Clean up the temporary directory
rm -rf "${TEMP_DIR}"

# --- Finished ---
echo "--- Packaging complete! ---"
echo "The archive is located at: ${ARTIFACT_PATH}"
echo "You can now use this archive to restore the data to another TypeDB instance."
