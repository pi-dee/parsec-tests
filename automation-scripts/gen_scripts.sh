#!/bin/bash

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Usage: ./gen_scripts.sh <sim_size>"
    echo "Example: ./gen_scripts.sh simmedium"
    exit 1
fi

SIM_SIZE=$1
TARGET_DIR="./${SIM_SIZE}"

# List of standard PARSEC benchmarks
# You can add or remove names from this list as needed
BENCHMARKS=(
    "blackscholes" "bodytrack" "facesim" 
    "ferret" "fluidanimate" "freqmine" "raytrace" 
    "swaptions" "vips" "x264"
    # "canneal" "dedup" "streamcluster"
)

# Create the directory if it doesn't exist
mkdir -p "$TARGET_DIR"

echo "Generating scripts in $TARGET_DIR for size: $SIM_SIZE"

for BENCH in "${BENCHMARKS[@]}"; do
    FILE_NAME="${TARGET_DIR}/run_${BENCH}_${SIM_SIZE}.rcS"
    
    # Create the script using a Heredoc
    cat <<EOF > "$FILE_NAME"
#!/bin/bash

# 1. Reset stats so we only measure the benchmark
echo "Resetting stats"
/sbin/m5 resetstats

# 2. Run the benchmark ($SIM_SIZE is best for 64 cores)
cd /home/gem5/parsec-benchmark
#echo "Sourcing environment setup"
#source env.sh
echo "Running simulation"
parsecmgmt -a run -p $BENCH -c gcc-hooks -n 64 -i $SIM_SIZE

echo "Dumping stats"
# 3. Dump stats when the ROI (Region of Interest) finishes
/sbin/m5 dumpstats

echo "Exiting simulation"
# 4. Exit simulation
#sbin/m5 exit
EOF

    # Make the generated script executable
    chmod +x "$FILE_NAME"
done

echo "Done! Generated ${#BENCHMARKS[@]} scripts."

