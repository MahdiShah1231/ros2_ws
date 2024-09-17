ros2_base_exists = $(shell docker images | grep ros2_docker_base)
define clean_img_if_exists
	result=$$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$(1):latest$$" && echo "found" || echo "not found") ; \
	if [ "$$result" = "found" ]; then \
		echo "Cleaning $(1):latest" ; \
		docker rmi -f $(1):latest ; \
	else \
		echo "No image found for $(1):latest" ; \
	fi
endef

# Default build arguments
BUILD_ARGS ?= --build-arg USERNAME=docker_user
.PHONY: build
build:
	docker build -t ros2_docker_base -f Dockerfile . $(BUILD_ARGS)
	docker build -t ros2_docker_kobuki -f Dockerfile.Kobuki .

## TODO remove the floating containers as well
# List of images to check
IMAGES = ros2_docker_base ros2_docker_kobuki
.PHONY: clean
clean:
	@echo "Checking for Docker images..." ; \
	$(foreach img,$(IMAGES),$(call clean_img_if_exists,$(img));)