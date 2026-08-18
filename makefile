# Image names
IMAGE_NAME=opencyber-snort-lab

# Default target: build the final lab image
all: student

# Build only the builder stage (the slow from-source Snort compile)
build:
	docker build --target snort-builder -f docker/Dockerfile .

# Build the final lab image (reuses cached builder layers)
student:
	docker build -t $(IMAGE_NAME):local -f docker/Dockerfile .

# Run an interactive container from the local build (named volume persists student work).
# --network none: the lab needs NO outbound network (Snort reads local pcaps; the vuln-server
# listens on localhost:8888, and loopback still works with no network). Keeps the container sealed.
run: student
	docker run --rm -it --network none -v snort-lab-data:/home/student $(IMAGE_NAME):local

# Clean up dangling images (optional)
clean:
	docker image prune -f

# Fully reset persisted student work. The `run`/`ghcr` targets mount a named volume
# (snort-lab-data) that persists /home/student ACROSS runs — handy, but it also shadows
# image updates, so a stale volume can serve an old attack.sh/ftp_folder. Run `make reset`
# between dev runs (or after rebuilding) to wipe it and start from the fresh image.
reset:
	-docker volume rm snort-lab-data

# Run the image from GitHub Container Registry
ghcr:
	docker run --rm -it -v snort-lab-data:/home/student ghcr.io/codepath/$(IMAGE_NAME):latest

# Build and push to GitHub Container Registry (requires docker login ghcr.io).
# MAKE_JOBS=1: the emulated amd64 cross-compile segfaults cc1 under parallel make, so the
# published image is built single-threaded. Local builds (student/build) keep all cores.
push:
	docker buildx build --platform linux/amd64,linux/arm64 --build-arg MAKE_JOBS=1 -t ghcr.io/codepath/$(IMAGE_NAME):latest -f docker/Dockerfile --push .
