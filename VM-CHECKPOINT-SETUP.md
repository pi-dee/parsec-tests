# gem5 FS + PARSEC + Garnet (Checkpoint Workflow only works for adaptive right now. For others follow full boot)

## Overview

This document describes a fast and reproducible workflow to run PARSEC workloads in gem5 Full-System (FS) mode using Ruby + Garnet with a custom topology and routing algorithm.

The key idea is to **decouple Linux boot from simulation**:

* Boot once using a fast configuration
* Create a checkpoint
* Restore with your full experimental setup

---

## Step 0: Download parsec prebuilt image and linux kernel image

```bash
mkdir -p ~/gem5-resources

# Download the x86 PARSEC image (the one from https://resources.gem5.org/resources/x86-parsec/raw?database=gem5-resources&version=1.0.0)
wget http://dist.gem5.org/dist/v22-1/images/x86/ubuntu-18-04/parsec.img.gz -O ~/gem5-resources/parsec.img.gz
gunzip ~/gem5-resources/parsec.img.gz

wget http://dist.gem5.org/dist/v20-1/kernels/x86/static/vmlinux-4.19.83 -O ~/gem5-resources/vmlinux-4.19.83
```

---

## Step 1: Build gem5

Step 1 — Start completely clean
`scons -c build/X86/gem5.opt`

Step 2 — Create config from scratch
`scons defconfig build/X86 build_opts/X86`

Step 3 — Use menuconfig once (yes, just once)
`scons menuconfig build/X86`

Then:

```
→ Ruby
   → Protocol
      → Select MOESI_hammer
```

Exit and save.

👉 Important: This ensures all hidden dependencies are resolved properly.

Step 4 — Build
`scons build/X86/gem5.opt -j$(nproc)`

---

## Step 2: Run Fast Boot Configuration

Use a **fast, compatible setup**:

For ***adaptive***:

```bash
./build/X86/gem5.opt -d m5out_wget_image \
 configs/deprecated/example/fs.py \
 --cpu-type=AtomicSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --vcs-per-vnet=6 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 --checkpoint-at-end
```

For ***dateline (MOESI_hammer needed)***:

```bash
./build/X86/gem5.opt -d m5out_wget_image \
 configs/deprecated/example/fs.py \
 --cpu-type=AtomicSimpleCPU \
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
 --checkpoint-dir=boot_wget_ckpt \
 --checkpoint-at-end
```

### For poppingbubbles, spotsaver, checkpoint workflow does not work. Go to last section.

For ***poppingbubbles***:

```bash
./build/X86/gem5.opt -d m5out_wget_image \
 configs/deprecated/example/fs.py \
 --cpu-type=AtomicSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --num-bubbles=1 \
 --deflection-threshold=10 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 --checkpoint-at-end
```

For ***spotsaver***:

```bash
./build/X86/gem5.opt -d m5out_wget_image \
 configs/deprecated/example/fs.py \
 --cpu-type=AtomicSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 --checkpoint-at-end
```

### Notes:

* Must match final system:

  * `--num-cpus=64`
  * `--num-dirs=64`
  * `--ruby`
* Use **AtomicSimpleCPU** for fast boot (can change later)
* Use your chiplet topology (can NOT change later)

---

## Step 3: Monitor Boot

```bash
tail -f m5out_wget_image/system.pc.com_1.device
```

Wait until you see (Will take around 6-8 hours):

```bash
root@gem5-host:~#
```

---

## Step 4: Connect to Guest Console

The `tail` output is **read-only**. To interact:

```bash
telnet localhost 3456
```

To exit out of telnet, **DONT do "exit"**. Instead 
1. Press Ctrl + ] (Control and the right square bracket). This "breaks" the connection to the VM and gives you a telnet> prompt.
2. Type quit (or just q) and hit Enter.

**Where 3456 came from**

That port is the default telnet port used by gem5’s FS script (fs.py) for the serial console.

👉 Specifically:

gem5 creates a terminal device (serial console)
* It exposes it over TCP
* Default port = 3456

---

## Step 5: Create Checkpoint

Inside the guest:

```bash
/sbin/m5 checkpoint
```

---

## Step 6: Verify Checkpoint and then exit

On host:

```bash
ls boot_wget_ckpt/
```

Expected:

```bash
cpt.<tick-number>
```

Once verified, inside the guest:

```bash
/sbin/m5 exit
```

---

## Step 7: Restore with Full Configuration

* For ***adaptive***:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_sim_test \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --vcs-per-vnet=6 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 -r 1
```

For ***dateline (MOESI_hammer needed)***:

```bash
./build/X86/gem5.opt -d m5out_wget_image \
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
 --checkpoint-dir=boot_wget_ckpt \
 -r 1
```

### For poppingbubbles, spotsaver, checkpoint workflow does not work. Go to last section.

* For ***poppingbubbles***:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_sim_test \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --num-bubbles=1 \
 --deflection-threshold=10 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 -r 1
```

* For ***spotsaver***:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_sim_test \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 -r 1
```

---

## Step 8: Run PARSEC

Running the 
* **test** simulation with adaptive took about 1 hour and 40 minutes. Only after 1 hour and 30 minutes did we start seeing some parsec output:
* **simsmall** simulation with adaptive (not all correct args) took about 3 hour. Only after 2 hour and 30 minutes did we start seeing some parsec output (not shown here).

```
[PARSEC] Benchmarks to run:  parsec.blackscholes

[PARSEC] [========== Running benchmark parsec.blackscholes [1] ==========]
[PARSEC] Setting up run directory.
[PARSEC] Unpacking benchmark input 'test'.
in_4.txt
[PARSEC] Running 'time /home/gem5/parsec-benchmark/pkgs/apps/blackscholes/inst/amd64-linux.gcc-hooks/bin/blackscholes 64 in_4.txt prices.txt':
[PARSEC] [---------- Beginning of output ----------]
PARSEC Benchmark Suite Version 3.0-beta-20150206
[HOOKS] PARSEC Hooks Version 1.2
WARNING: Not enough work, reducing number of threads to match number of options.
Num of Options: 4
Num of Runs: 100
Size of data: 160
[HOOKS] Entering ROI
[HOOKS] Leaving ROI
[HOOKS] Total time spent in ROI: 0.009s
[HOOKS] Terminating

real	0m0.014s
user	0m0.001s
sys	0m0.005s
[PARSEC] [----------    End of output    ----------]
[PARSEC]
[PARSEC] BIBLIOGRAPHY
[PARSEC]
[PARSEC] [1] Bienia. Benchmarking Modern Multiprocessors. Ph.D. Thesis, 2011.
[PARSEC]
[PARSEC] Done.
Dumping stats
Exiting simulation
Connection closed by foreign host.
```

### Option A: Automated-ish (Recommended for quick test of parsec. For full sim, see Option C)

Create `run_blackscholes.rcS`:

```bash
# 1. Reset stats so we only measure the benchmark
echo "Resetting stats"
/sbin/m5 resetstats

# 2. Run the benchmark (simmedium is best for 64 cores)
cd /home/gem5/parsec-benchmark
echo "Sourcing environment setup"
source env.sh
echo "Running simulation"
parsecmgmt -a run -p blackscholes -c gcc-hooks -n 64 -i test

echo "Dumping stats"
# 3. Dump stats when the ROI (Region of Interest) finishes
/sbin/m5 dumpstats

echo "Exiting simulation"
# 4. Exit simulation
/sbin/m5 exit
```

Run with command from #7 + following arg at end:

```bash
  --script=run_blackscholes.rcS
```

Then connect to telnet and run these in the VM interactively:

```bash
/sbin/m5 readfile > run.sh && chmod +x run.sh && cat ./run.sh 
./run.sh
```

---

### Option B: Interactive

```bash
telnet localhost 3456
```

Then run PARSEC manually.

```bash
# 1. Reset stats so we only measure the benchmark
echo "Resetting stats"
/sbin/m5 resetstats

# 2. Run the benchmark (simmedium is best for 64 cores)
cd /home/gem5/parsec-benchmark
echo "Sourcing environment setup"
source env.sh
echo "Running simulation"
parsecmgmt -a run -p blackscholes -c gcc-hooks -n 64 -i test

echo "Dumping stats"
# 3. Dump stats when the ROI (Region of Interest) finishes
/sbin/m5 dumpstats

echo "Exiting simulation"
# 4. Exit simulation
/sbin/m5 exit
```

---

### Option C: Fully automated (Recommended for CHTC)

---
#### One time setup with manual supervision

Create `gen_and_run.rcS`:

```bash
#!/bin/bash

# 1. System stabilization
cd /home/gem5/parsec-benchmark/

# 2. Setup Environment
if [ -f env.sh ]; then
    source env.sh
fi

# 3. Create Checkpoint and pause briefly
# When you RESTORE, the simulation resumes exactly at the next line
echo "Checkpointing"
m5 checkpoint

# 4. Fetch the benchmark-specific script passed via --script
echo "Restoring: Fetching run script via m5 readfile..."
/sbin/m5 readfile > run.sh
chmod +x run.sh

# 5. Execute and log
echo "Starting Benchmark..."
./run.sh

# 6. Clean Exit
m5 exit
```

Before running the following command, check what checkpoints exist in the `boot_wget_ckpt` folder as the new checkpoint will be created in the same folder.

Run with command from #7 but **need to use --cpu-type=AtomicSimpleCPU and --restore-with-cpu=AtomicSimpleCPU** and add following arg at end:


```bash
  --script=gen_and_run.rcS
```

Then connect to telnet and run these in the VM interactively:

> **NOTE: After running `./boot.sh` Please look out for the "Checkpointing" message on the vm. Once you see that, wait for "Restoring: Fetching run script via m5 readfile..." message and then immediately ctrl+c the command from #7 (the ./build/X86/gem5.opt... command).**

```bash
/sbin/m5 readfile > boot.sh && chmod +x boot.sh && cat ./boot.sh 
./boot.sh
```

> **Make sure to check the `boot_wget_ckpt` folder and make a new directory for the new checkpoint named `boot_auto_ckpt`. Then copy the `cpt.<>` checkpoint that you just created from `boot_wget_ckpt` to `boot_auto_ckpt`.**

---

#### Automated after the one-time setup

After this one-time setup, you can pass any script for running a parsec benchmark and it will run the script and exit.

For example, create `run_blackscholes_simmedium.rcS`

```bash
#!/bin/bash

# 1. Reset stats so we only measure the benchmark
echo "Resetting stats"
/sbin/m5 resetstats

# 2. Run the benchmark (simmedium is best for 64 cores)
cd /home/gem5/parsec-benchmark
#echo "Sourcing environment setup"
#source env.sh
echo "Running simulation"
parsecmgmt -a run -p blackscholes -c gcc-hooks -n 64 -i simmedium

echo "Dumping stats"
# 3. Dump stats when the ROI (Region of Interest) finishes
/sbin/m5 dumpstats

echo "Exiting simulation"
# 4. Exit simulation
#sbin/m5 exit
```

Then run

* For **adaptive**:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_simmedium \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --vcs-per-vnet=6 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_auto_ckpt \
 -r 1 \
 --script=scripts/medium/run_blackscholes_medium.rcS
```

**NOTE: the `-r 1` is for restoring from the first checkpoint. If you have more than one checkpoint, you can change this value accordingly. Since we made sure in previous step that boot_auto_ckpt has only one checkpoint, we pass -r 1.**

* For **dateline**:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_test \
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
 --script=scripts/test/run_blackscholes_test.rcS
```

* For **spotsaver**:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_test \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_auto_ckpt \
 -r 1 \
 --script=scripts/test/run_blackscholes_test.rcS
```

* For **poppingbubbles**:

```bash
./build/X86/gem5.opt -d m5out_blackscholes_test \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --restore-with-cpu=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --num-bubbles=1 \
 --deflection-threshold=10 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_auto_ckpt \
 -r 1 \
 --script=scripts/test/run_blackscholes_test.rcS
```

---

## Compatibility Rules (IMPORTANT)

### Must match between boot and restore (Recommended to match everything except cpu-type):

* Number of CPUs
* Number of directories
* Ruby enabled
* Topology (if node count matches)
* ISA (X86)

### Can change (not tested):

* Routing algorithms
* Garnet parameters

---

## Common Issues

### Cannot type in terminal

* You are using `tail`
* Use `telnet localhost 3456`

---

### stats.txt not getting generated

* Running `m5 dumpstats` after the simulation has exited is the only way to dump stats. **Check if you are running it after the simulation has exited.**

### No checkpoint appears

* Did not run `m5 checkpoint`
* Or simulation did not exit

---

### Segmentation faults during boot

* Common in gem5 FS
* Safe if system reaches shell

---

### Slow boot

* Expected with 64 cores + Ruby
* Usually 6-8 hours

---

## Key Insight

This workflow enables:

> Fast iteration by avoiding repeated Linux boot

* Boot once
* Reuse checkpoint
* Run multiple network experiments efficiently

---

## For Debugging

* You can add `--debug-flags=RubyNetwork` after the `-d m5out` flag. **The placement of this flag is important.**
* Since the debug output is very large, you can if you know the issue tick range, you can use the `--debug-start` and `--debug-end` flags to limit the debug output. For example, if you know the issue is between tick 1000000 and 2000000, you can add `--debug-start=1000000 --debug-end=2000000` to the command. **The placement of this flag is also important and should go after the `-d m5out` flag.**

---

## Done ✅

You now have:

* A reusable FS checkpoint
* A working path to run PARSEC with custom Garnet topology and routing
* automation-scripts/ can be used for the scripts to provide for --script


# Without Checkpoint Workflow

## Step 0: Download parsec prebuilt image and linux kernel image

```bash
mkdir -p ~/gem5-resources

# Download the x86 PARSEC image (the one from https://resources.gem5.org/resources/x86-parsec/raw?database=gem5-resources&version=1.0.0)
wget http://dist.gem5.org/dist/v22-1/images/x86/ubuntu-18-04/parsec.img.gz -O ~/gem5-resources/parsec.img.gz
gunzip ~/gem5-resources/parsec.img.gz

wget http://dist.gem5.org/dist/v20-1/kernels/x86/static/vmlinux-4.19.83 -O ~/gem5-resources/vmlinux-4.19.83
```

---

## Step 1: Build gem5

Step 1 — Start completely clean
`scons -c build/X86/gem5.opt`

Step 2 — Create config from scratch
`scons defconfig build/X86 build_opts/X86`

### skip step 3 (MOESI_hammer) for now
Step 3 — Use menuconfig once (yes, just once)
`scons menuconfig build/X86`

Then:

```
→ Ruby
   → Protocol
      → Select MOESI_hammer
```

Exit and save.

👉 Important: This ensures all hidden dependencies are resolved properly.

Step 4 — Build
`scons build/X86/gem5.opt -j$(nproc)`

---

## Step 2: Run Slow Boot Configuration and Parsec

Example `run_blackscholes_simmedium.rcS`

```bash
#!/bin/bash

# 1. Reset stats so we only measure the benchmark
echo "Resetting stats"
/sbin/m5 resetstats

# 2. Run the benchmark (simmedium is best for 64 cores)
cd /home/gem5/parsec-benchmark
#echo "Sourcing environment setup"
#source env.sh
echo "Running simulation"
parsecmgmt -a run -p blackscholes -c gcc-hooks -n 64 -i simmedium

echo "Dumping stats"
# 3. Dump stats when the ROI (Region of Interest) finishes
/sbin/m5 dumpstats

echo "Exiting simulation"
# 4. Exit simulation
#sbin/m5 exit
```
* For ***poppingbubbles***

```bash
./build/X86/gem5.opt -d m5out_direct_boot \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --num-bubbles=1 \
 --deflection-threshold=10 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 --script=scripts/test/run_blackscholes_test.rcS
```

* For ***spotsaver***

```bash
./build/X86/gem5.opt -d m5out_direct_boot \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
 --num-cpus=64 \
 --num-dirs=64 \
 --ruby \
 --network=garnet \
 --topology=ChipletMesh_XY \
 --mesh-rows=4 \
 --num-l2caches=64 \
 --num-chips=4 \
 --routing-algorithm=2 \
 --chiplet-routing-algorithm=1 \
 --interconnect-routing-algorithm=1 \
 --buffers-per-data-vc=5 \
 --buffers-per-ctrl-vc=5 \
 --vcs-per-vnet=1 \
 --garnet-deadlock-threshold=240000000 \
 --kernel=../vmlinux-4.19.83 \
 --disk-image=../parsec.img \
 --checkpoint-dir=boot_wget_ckpt \
 --script=scripts/test/run_blackscholes_test.rcS
```

* For ***dateline***

```bash
./build/X86/gem5.opt -d m5out_direct_boot \
 configs/deprecated/example/fs.py \
 --cpu-type=TimingSimpleCPU \
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
 --checkpoint-dir=boot_wget_ckpt \
 --script=scripts/test/run_blackscholes_test.rcS
```

---
