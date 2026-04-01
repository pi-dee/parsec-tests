# parsec-tests

## Quick Start

Follow VM-CHECKPOINT-SETUP.md

## Steps on compiling your own parsec.img

**NOTE: This does not contain the inputs for the benchmarks.**

Followed https://www.gem5.org/documentation/gem5art/tutorials/parsec-tutorial but made edits to the following files for successful compilation so use from github repo:

* parsec-install.sh
* parsec.json (can enable/disable gui using `headless` config)

Commands:

```bash
mkdir -p disk-image/parsec
cd disk-image/parsec/
git clone https://github.com/darchr/parsec-benchmark.git

# Create files `parsec-install.sh`, `post-installation.sh`, `runscript.sh`, and `parsec.json` in parsec

cd .. # back to disk-image
wget https://releases.hashicorp.com/packer/1.4.3/packer_1.4.3_linux_amd64.zip
unzip packer_1.4.3_linux_amd64.zip

# Now, to build the disk image inside the disk-image folder, run:
./packer validate parsec/parsec.json

./packer build parsec/parsec.json
```

### Notes

* You will also need the prebuilt `m5` binary to be in some path defined in parsec.json

