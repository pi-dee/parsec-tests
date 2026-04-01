# Dateline Parsec CHTC Setup

> in `.sub` file, replace placeholders with your netid and your email id for notifications.

## Assumptions

* The `dateline-parsec.tar.gz` file is submitted to the staging. And on untar also the folder name is `dateline-parsec`.
* The `dateline-parsec.tar.gz` has the gem5 already compiled. And it also has the scripts folder with contents same as automation-scripts (can check file paths in .sh script for more clarity).
* The vmlinux and parsec images are predownloaded as told in VM-CHECKPOINT-SETUP.md
* Make sure your Network.py file is updated with changes to enable `--buffers-per-ctrl-vc` flag.
* TorusMesh should have the change how the DMA nodes are connected.
