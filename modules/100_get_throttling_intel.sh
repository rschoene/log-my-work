#!/bin/sh

# Function to check thermal throttle counts and write to JSON file
check_thermal_throttle() {
    module_name="intel_thermal_throttle"
    description="Checking thermal throttle counts for Intel CPUs"
    version="1.0"

    output_file="$1"

    # Check if the output file is set to stdout
    if [ "$output_file" = "-" ]; then
        # If stdout, use a temporary file
        tmp_file="$(mktemp)"
        trap 'rm -f "$tmp_file"' EXIT
        output_file="$tmp_file"
    fi

    # Create an initial JSON structure
    printf "{ \"Module\": \"%s\", \"Description\": \"%s\", \"Version\": \"%s\", \"Results\": [" > "$output_file"

    # Iterate through all available CPUs
    for cpu_file in /sys/devices/system/cpu/cpu*/thermal_throttle; do
        cpu=$(basename "$(dirname "$cpu_file")")

        core_throttle_count_file="$cpu/thermal_throttle/core_throttle_count"
        package_throttle_count_file="$cpu/thermal_throttle/package_throttle_count"

        # Check if files exist
        if [ -e "$core_throttle_count_file" ] && [ -e "$package_throttle_count_file" ]; then
            # Read content of files
            core_throttle_count=$(cat "$core_throttle_count_file")
            package_throttle_count=$(cat "$package_throttle_count_file")

            # Append data to JSON file
            printf "  { \"CPU\": \"%s\", \"Core_Throttle_count\": %s, \"Package_Throttle_count\": %s }," "$cpu" "$core_throttle_count" "$package_throttle_count" >> "$output_file"
        fi
    done

    # Remove trailing comma and close JSON structure
    sed -i '$s/,$//' "$output_file"
    printf "]}\n" >> "$output_file"

    if [ "$1" = "-" ]; then
        # If stdout was used, cat the temporary file to stdout
        cat "$output_file"
    else
        echo "Results written to: $output_file"
    fi
}

# Function to initialize
initialize() {
    check_thermal_throttle "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/thermal_throttle_results_initial.json"
}

# Function to finalize
finalize() {
    check_thermal_throttle "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/thermal_throttle_results_final.json"
}

# Function to check status
status() {
    check_thermal_throttle "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/thermal_throttle_`date +%s%N`_final.json"
    cat "$output_file"
}


# Main program
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <initialize|status|finalize>"
    exit 1
fi

# if it is not a platform that supports the used files, skip this
if [ ! -f "/sys/devices/system/cpu/cpu0/thermal_throttle/" ]; then
  return
fi

case "$1" in
    "initialize")
        initialize
        ;;
    "status")
        status
        ;;
    "finalize")
        finalize
        ;;
    *)
        echo "Invalid argument. Usage: $0 <initialize|status|finalize>"
        exit 1
        ;;
esac
