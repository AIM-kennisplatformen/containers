#!/bin/bash
set -e

# --- Terminal Control ---

# This function is called on exit to restore the terminal
cleanup() {
    # Switch back from the alternate screen
    tput rmcup
}

# Trap the EXIT signal to ensure cleanup happens every time
trap cleanup EXIT

# Switch to the alternate screen
tput smcup

# --- Configuration ---
HOST_DATA_DIR="data"
# These paths are relative to the HOST_DATA_DIR.
TYPEDB_EXCLUDE_FILE="typedb/.gitkeep"
QDRANT_EXCLUDE_FILE="qdrant/.gitkeep"
# --- End Configuration ---

# Ensure the main data directory and subdirectories exist.
# The .gitkeep files ensure that Git tracks these directories.
mkdir -p "./${HOST_DATA_DIR}/typedb" && touch "./${HOST_DATA_DIR}/typedb/.gitkeep"
mkdir -p "./${HOST_DATA_DIR}/qdrant" && touch "./${HOST_DATA_DIR}/qdrant/.gitkeep"

# --- Function to read user input with ESC as cancel ---
read_with_esc() {
    local prompt="$1"
    local output_var="$2"
    local input=""
    local key

    echo -n "$prompt"

    # Read character by character
    while IFS= read -rsn1 key; do
        # Check for ESC key (ASCII code \x1b)
        if [[ "$key" == $'\x1b' ]]; then
            echo " Cancelled."
            return 1 # Indicate cancellation
        fi

        # Check for Enter key (empty character from read)
        if [[ "$key" == "" ]]; then
            echo "" # Move to the next line
            break
        fi

        # Check for Backspace/Delete key
        if [[ "$key" == $'\x7f' ]]; then
            if [ ${#input} -gt 0 ]; then
                input="${input%?}"
                # Move cursor back, overwrite with space, move back again
                echo -ne "\b \b"
            fi
        else
            input+="$key"
            echo -n "$key"
        fi
    done

    # Assign the final input to the provided output variable name
    eval "$output_var=\"$input\""
    return 0 # Indicate success
}

# --- Function to wait for a key press (ESC only) ---
wait_for_key() {
    local prompt="$1"
    if [ -z "$prompt" ]; then
        prompt="Press [ESC] to continue..."
    fi
    echo -n "$prompt"
    local key
    # Read character by character
    while IFS= read -rsn1 key; do
        # Check for ESC key
        if [[ "$key" == $'\x1b' ]]; then
            echo "" # Move to the next line
            break
        fi
    done
}


# --- Function to list available artifacts ---
list_artifacts() {
    # This function can be called in two modes:
    # 1. Standard: Just lists the files and populates the ARTIFACTS array.
    # 2. Interactive: Lists the files and then waits for user input to return.
    local interactive_mode=false
    if [[ "$1" == "--interactive" ]]; then
        interactive_mode=true
    fi

    echo "--- Available Data Artifacts in ./${HOST_DATA_DIR}/ ---"
    # Find all .tar.gz files in the data directory and store them in an array
    readarray -t ARTIFACTS < <(find "./${HOST_DATA_DIR}" -maxdepth 1 -type f -name "*.tar.gz")

    if [ ${#ARTIFACTS[@]} -eq 0 ]; then
        echo "No artifacts found."
        # If in interactive mode, wait for user input before returning
        if [ "$interactive_mode" = true ]; then
            echo ""
            wait_for_key "Press [ESC] to return to the main menu..."
        fi
        return 1
    fi

    # Print a numbered list
    for i in "${!ARTIFACTS[@]}"; do
        printf "%d) %s\n" "$((i+1))" "$(basename "${ARTIFACTS[$i]}")"
    done
    echo "---------------------------------------"

    # If in interactive mode, wait for user input before returning
    if [ "$interactive_mode" = true ]; then
        echo ""
        wait_for_key "Press [ESC] to return to the main menu..."
    fi

    return 0
}

# --- Function to package the current data into an artifact ---
package_current_data() {
    local artifact_name=$1
    if [ -z "$artifact_name" ]; then
        echo "Error: Artifact name not provided."
        return 1
    fi

    # Check if there is anything to package in the typedb or qdrant directories
    if [ -z "$(ls -A "./${HOST_DATA_DIR}/typedb" 2>/dev/null)" ] && [ -z "$(ls -A "./${HOST_DATA_DIR}/qdrant" 2>/dev/null)" ]; then
        echo "No data found in 'typedb' or 'qdrant' directories to package. Skipping."
        wait_for_key "Press [ESC] to return to the main menu..."
        return 1
    fi

    local artifact_path="./${HOST_DATA_DIR}/${artifact_name}.tar.gz"
    echo "Packaging 'typedb' and 'qdrant' dirs into '${artifact_path}'..."
    echo "Excluding '${TYPEDB_EXCLUDE_FILE}' and '${QDRANT_EXCLUDE_FILE}'."

    # The -C flag changes directory to HOST_DATA_DIR.
    # --exclude flags are used to omit specific files from the archive.
    tar --exclude="${TYPEDB_EXCLUDE_FILE}" \
        --exclude="${QDRANT_EXCLUDE_FILE}" \
        -czvf "${artifact_path}" \
        -C "./${HOST_DATA_DIR}" typedb qdrant

    echo "Packaging complete."
    # Add a pause so the user can see the completion message
    echo ""
    wait_for_key "Press [ESC] to return to the main menu..."
    return 0
}

# --- Function to load from an artifact ---
load_artifact() {
    # First, list the available artifacts in non-interactive mode
    if ! list_artifacts; then
        return
    fi

    local choice
    # Ask the user to choose an artifact, return if ESC is pressed
    if ! read_with_esc "Enter the number of the artifact to load (press ESC to cancel): " choice; then
        return
    fi

    # Also treat empty input (just pressing Enter) as a cancellation
    if [ -z "$choice" ]; then
        echo "Loading cancelled."
        return
    fi

    # Validate input is a number and within the array bounds
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#ARTIFACTS[@]} ]; then
        echo "Invalid selection. Please enter a number from the list."
        wait_for_key "Press [ESC] to return to the main menu..."
        return
    fi

    local selected_artifact=${ARTIFACTS[$((choice-1))]}
    echo "You selected: $(basename "$selected_artifact")"

    # 1. Ask the user if they want to package current data first
    read -p "Do you want to package the current data before loading? (y/n): " package_choice
    if [[ "$package_choice" =~ ^[Yy]$ ]]; then
        local timestamp=$(date +%F_%H-%M-%S)
        package_current_data "package-${timestamp}"
    else
        echo "Skipping packaging of current data."
    fi

    # 2. Clean up old data directories, preserving .gitkeep
    echo "Cleaning old 'typedb' and 'qdrant' directories (preserving .gitkeep)..."
    find "./${HOST_DATA_DIR}/typedb" -mindepth 1 -not -name ".gitkeep" -delete
    find "./${HOST_DATA_DIR}/qdrant" -mindepth 1 -not -name ".gitkeep" -delete
    echo "Cleanup complete."

    # 3. Unpack the selected artifact
    echo "Loading '${selected_artifact}' into ./${HOST_DATA_DIR}/..."
    # The -C flag ensures it extracts directly into the data directory
    tar -xzvf "${selected_artifact}" -C "./${HOST_DATA_DIR}"
    echo "Artifact loaded successfully! You can now run 'docker-compose up -d'."
    # Add a pause so the user can see the completion message
    echo ""
    wait_for_key "Press [ESC] to return to the main menu..."
}

# --- Main Menu ---
while true; do
    clear
    echo ""
    echo "======================================"
    echo "      Data Artifact Manager       "
    echo "======================================"
    echo "1. List available data artifacts"
    echo "2. Load data from an artifact"
    echo "3. Package current data"
    echo "4. Exit"
    echo ""
    read -p "Enter your choice [1-4]: " main_choice

    case $main_choice in
        1)
            clear
            # Call the list function in interactive mode
            list_artifacts --interactive
            ;;
        2)
            clear
            load_artifact
            ;;
        3)
            clear
            custom_artifact_name=""
            if read_with_esc "Enter a name for the new artifact (press ESC to cancel): " custom_artifact_name; then
                if [ -n "$custom_artifact_name" ]; then
                    package_current_data "$custom_artifact_name"
                else
                    echo "Packaging cancelled. No name provided."
                    wait_for_key "Press [ESC] to return to the main menu..."
                fi
            fi
            ;;
        4)
            # The 'trap' will automatically handle the cleanup and terminal restoration
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            wait_for_key "Press [ESC] to continue..."
            ;;
    esac
done