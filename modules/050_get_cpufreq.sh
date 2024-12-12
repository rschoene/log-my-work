#!/bin/sh

# Function to check thermal throttle counts and write to JSON file
cpufreq() {
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
    for cpu_file in /sys/devices/system/cpu/cpu*/cpufreq; do
        cpu=$(basename "$(dirname "$cpu_file")")
        folder="$(dirname "$cpu_file")"

        driver_file="$folder/cpufreq/scaling_driver"
        governor_file="$folder/cpufreq/scaling_governor"
        min_file="$folder/cpufreq/scaling_min_freq"
        max_file="$folder/cpufreq/scaling_max_freq"
        boost_file="$folder/cpufreq/cpb"
        echo "Yay $folder"

        # Check if files exist
        if [ -e "$driver_file" ] && [ -e "$governor_file" ]&& [ -e "$min_file" ]&& [ -e "$max_file" ]&& [ -e "$cpb_file" ]; then
            # Read content of files
            driver=$(cat "$driver_file")
            governor_file=$(cat "$governor_file")
            min=$(cat "$min_file")
            max=$(cat "$max_file")
            boost=$(cat "$boost_file")

            # Append data to JSON file
            printf "  { \"CPU\": \"%s\", \"Driver\": %s, \"Governor\": %s , \"MinFreq\": %s, \"MaxFreq\": %s, \"Boost\": %s  }," "$cpu" "$driver" "$governor_file" "$min" "$max" "$boost">> "$output_file"
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
    cpufreq "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/cpufreq_initial.json"
}

# Function to finalize
finalize() {
    cpufreq "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/cpufreq_final.json"
}

# Function to check status
status() {
    cpufreq "${LOG_MY_WORK_FOLDER_RESULT_FOLDER}/cpufreq_`date +%s%N`.json"
}


# Main program
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <initialize|status|finalize>"
    exit 1
fi

# if it is not a platform that supports the used files, skip this
if [ ! -d "/sys/devices/system/cpu/cpufreq" ]; then
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
