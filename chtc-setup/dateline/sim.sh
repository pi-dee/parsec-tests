#!/bin/bash
# sim.sh

EXP=$1
BENCHMARK=$2
SIM_SIZE=$3

# ================================================================================================
echo "Unzipping all files."
# 1. Unzip the massive gem5 folder that HTCondor pulled from staging
if tar -xzf $EXP.tar.gz; then
    echo "Success: $EXP.tar.gz extracted."
else
    echo "Error: $EXP Extraction failed."
    exit 1
fi

if gunzip parsec.img.gz; then
    echo "Success: parsec.img.gz extracted."
else
    echo "Error: Extraction failed."
    exit 1
fi

if tar -xzf vmlinux-4.19.83.tar.gz; then
    echo "Success: vmlinux-4.19.83.tar.gz extracted."
else
    echo "Error: vmlinux-4.19.83.tar.gz Extraction failed."
    exit 1
fi

echo "Unzipped all files."

# ================================================================================================

echo "$(ll)"

# 3. Navigate into your unzipped folder
cd $EXP

echo "Starting parsec simulation for: $EXP, Benchmark [$BENCHMARK], sim size [$SIM_SIZE]"
# NEW: Create a unique output file name for this specific pattern and rate
M5OUT_DIR="m5out_${EXP}_${BENCHMARK}_${SIM_SIZE}"

# 4. Run your exact gem5 command with parsec script
./build/X86/gem5.opt -d $M5OUT_DIR \
  configs/deprecated/example/fs.py \
  --cpu-type=TimingSimpleCPU \
  --restore-with-cpu=TimingSimpleCPU \
  --num-cpus=64 \
  --num-dirs=64 \
  --ruby \
  --network=garnet \
  --topology=TorusMesh_XY \
  --mesh-rows=4 \
  --num-l2caches=64 \
  --num-chips=4 \
  --routing-algorithm=2 \
  --chiplet-routing-algorithm=0 \
  --interconnect-routing-algorithm=0 \
  --buffers-per-data-vc=5 \
  --buffers-per-ctrl-vc=5 \
  --vcs-per-vnet=4 \
  --garnet-deadlock-threshold=240000000 \
  --kernel=../vmlinux-4.19.83 \
  --disk-image=../parsec.img \
  --checkpoint-dir=boot_auto_ckpt \
  -r 1 \
  --script=scripts/${SIM_SIZE}/run_${BENCHMARK}_${SIM_SIZE}.rcS

# ================================================================================================

# tar and move the output folder to main CHTC working directory
tar -czf $M5OUT_DIR.tar.gz $M5OUT_DIR
mv $M5OUT_DIR.tar.gz ../
echo ""

# Clean up the m5out folder so the next loop starts fresh
rm -rf $M5OUT_DIR

cd ..
