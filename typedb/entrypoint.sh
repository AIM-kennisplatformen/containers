#!/bin/bash
set -e

# This script is run by the Docker container on startup.
# It looks for a data archive in the /data directory, unpacks it if found,
# waits for the TypeDB server to be ready, and then imports the database.

# The DATABASE_NAME is passed as an environment variable from docker-compose.yml
DATA_ARCHIVE="/data/knowledgeplatform-data.tar.gz"
IMPORT_DIR="/tmp/import_data"

SCHEMA_FILE="${IMPORT_DIR}/schema.tql"
DATA_FILE="${IMPORT_DIR}/data.typedb"

echo "Checking for data archive at ${DATA_ARCHIVE}..."
if [ -f "$DATA_ARCHIVE" ]; then
    echo "Data archive found. Unpacking into ${IMPORT_DIR}..."
    mkdir -p "$IMPORT_DIR"
    # Unpack the archive into the import directory
    tar -xzvf "$DATA_ARCHIVE" -C "$IMPORT_DIR"
    echo "Unpacking complete."
else
    echo "Data archive not found. Starting with a fresh, empty database."
fi

echo "Starting TypeDB server in background..."
/opt/typedb-all-linux-x86_64/typedb server &
SERVER_PID=$!

echo "Waiting for TypeDB server to be ready..."
# Wait until the server is responsive on its core port
until /opt/typedb-all-linux-x86_64/typedb console --core=localhost:1729 --command="database list" &>/dev/null; do
  echo "Server not responsive yet. Retrying in 2 seconds..."
  sleep 2
done
echo "Server is ready."

# Only attempt to import if the schema file was successfully unpacked
if [ -f "$SCHEMA_FILE" ]; then
    # Check if the database already exists to prevent import errors on restart
    if /opt/typedb-all-linux-x86_64/typedb console --core=localhost:1729 --command="database list" | grep -q "$DATABASE_NAME"; then
      echo "Database '$DATABASE_NAME' already exists. Skipping import."
    else
      echo "Importing database: $DATABASE_NAME"
      /opt/typedb-all-linux-x86_64/typedb server import --port=1729 --database=$DATABASE_NAME --schema=$SCHEMA_FILE --data=$DATA_FILE
      echo "Import complete."
    fi
else
    echo "Schema file not found. No data will be imported."
fi

echo "TypeDB is running. Tailing logs to keep container alive."
# Wait for the server process to exit, ensuring the container stays up
wait $SERVER_PID