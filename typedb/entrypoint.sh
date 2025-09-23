#!/bin/bash
set -e

# --- Configuration ---
# Path inside the container where the data archive will be located.
ARCHIVE_PATH="/archive/knowledgeplatform-data.tar.gz"
# The parent directory where the 'data' folder will be extracted.
TARGET_SERVER_DIR="/opt/typedb-all-linux-x86_64/server"
# The full path to the data directory itself.
TARGET_DATA_DIR="${TARGET_SERVER_DIR}/data"
# The full path to the server data directory that will be loaded.
TARGET_DATA_DIR="/opt/typedb-all-linux-x86_64/server/data"
# --- End Configuration ---

echo "--- TypeDB Container Entrypoint ---"

# Check if the data archive exists.
if [ -f "$ARCHIVE_PATH" ]; then
    echo "Data archive found at ${ARCHIVE_PATH}. Restoring data..."

    # Clear the contents of the target directory.
    echo "Clearing contents of target directory: ${TARGET_DATA_DIR}"
    rm -rf "${TARGET_DATA_DIR:?}/"*

    # Extract the archive's contents into the now-empty directory.
    echo "Extracting data from archive..."
    tar -xzvf "${ARCHIVE_PATH}" -C "${TARGET_SERVER_DIR}"

    echo "Data has been successfully loaded."
else
    echo "No data archive found at ${ARCHIVE_PATH}."
    echo "Starting TypeDB with existing data (if any)."
fi

# Start the TypeDB server.
echo "Starting TypeDB server..."
exec /opt/typedb-all-linux-x86_64/typedb server
