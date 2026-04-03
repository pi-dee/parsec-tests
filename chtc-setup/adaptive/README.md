# Adaptive Parsec CHTC Setup

> in `.sub` file, replace placeholders with your netid and your email id for notifications.

## Assumptions

* The `adaptive-parsec-MOESI_hammer.tar.gz` file is submitted to the staging. And on untar also the folder name should be `adaptive-parsec-MOESI_hammer`. This is hardcoded in sim.sh and can be changed on users choice.
* The `adaptive-parsec-MOESI_hammer.tar.gz` has the gem5 already compiled. And it also has the scripts folder with contents same as automation-scripts (can check file paths in .sh script for more clarity).
* The vmlinux and parsec images are predownloaded as told in VM-CHECKPOINT-SETUP.md.
* **The adaptive uses checkpoints instead of full linux boot, in `sim.sh` it assumes the first cpt in `boot_auto_ckpt` is the correct checkpoint.**
* ChipletMesh should have the change how the DMA nodes are connected.
