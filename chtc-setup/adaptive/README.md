# Adaptive Parsec CHTC Setup

> in `.sub` file, replace placeholders with your netid and your email id for notifications.

## Assumptions

* The `adaptive-parsec.tar.gz` file is submitted to the staging. And on untar the folder name should be **`adaptive`**. This is hardcoded in sim.sh and can be changed on users choice.
* The `adaptive-parsec.tar.gz` has the gem5 already compiled. And it also has the scripts folder with contents same as automation-scripts (can check file paths in .sh script for more clarity).
* The vmlinux and parsec images are predownloaded as told in VM-CHECKPOINT-SETUP.md
* **The adaptive uses checkpoints instead of full linux boot, in `sim.sh` it assumes the second cpt in `boot_wget_ckpt` is the correct checkpoint.** This can be replaced to `boot_golden_ckpt` in the `sim.sh` flags and then the flag `-r 1` would have to be passed instead of the current `-r 2`.

