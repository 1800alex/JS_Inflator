.PHONY: init all build release debug clean install run format help test test-build

# Build directory
BUILD_DIR := build
DIST_DIR := dist

# Detect number of cores for parallel builds
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

init:
	@echo "Initializing submodules..."
	git submodule update --init --recursive --depth 1

# Default target
all: release

# Alias for release
build: release

# Release build
release:
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release -DSMTG_ENABLE_VSTGUI_SUPPORT=ON -DSMTG_ENABLE_VST3_PLUGIN_EXAMPLES=OFF -DSMTG_ENABLE_VST3_HOSTING_EXAMPLES=OFF
	cmake --build $(BUILD_DIR) --config Release -j$(NPROC)

# Debug build
debug:
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug -DSMTG_ENABLE_VSTGUI_SUPPORT=ON -DSMTG_ENABLE_VST3_PLUGIN_EXAMPLES=OFF -DSMTG_ENABLE_VST3_HOSTING_EXAMPLES=OFF
	cmake --build $(BUILD_DIR) --config Debug -j$(NPROC)

# Clean build directory
clean:
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# Deep clean (including dist)
distclean: clean
	rm -rf $(DIST_DIR)

# Install to system VST3 folder
install: release
	@echo "Installing JS_Inflator..."
ifeq ($(shell uname),Linux)
	mkdir -p ~/.vst3
	cp -rf $(BUILD_DIR)/JS_Inflator_artefacts/Release/VST3/JS_Inflator.vst3 ~/.vst3/
	@echo "Installed to ~/.vst3/"
else ifeq ($(shell uname),Darwin)
	mkdir -p ~/Library/Audio/Plug-Ins/VST3
	cp -r $(BUILD_DIR)/JS_Inflator_artefacts/Release/VST3/JS_Inflator.vst3 ~/Library/Audio/Plug-Ins/VST3/
	@echo "Installed to ~/Library/Audio/Plug-Ins/VST3/"
else
	@echo "Please manually copy VST3 to your system folder"
endif

# Run standalone executable
run: release
	@echo "Running JS_Inflator Standalone..."
	$(BUILD_DIR)/JS_Inflator_artefacts/Release/Standalone/JS_Inflator

# Build and run tests
test: test-build
	@echo "Running tests..."
	cd $(BUILD_DIR) && ctest --output-on-failure

# Build tests only
test-build:
	@echo "Building tests..."
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON
	cmake --build $(BUILD_DIR) --target JS_InflatorTests -j$(NPROC)

# Format source code
format:
	@echo "Formatting source code..."
	find source -name '*.cpp' -o -name '*.h' | xargs clang-format -i
	@echo "Format complete!"

# Help
help:
	@echo "JS_Inflator Build System"
	@echo ""
	@echo "Native Builds:"
	@echo "  make build        - Build optimized release (alias)"
	@echo "  make release      - Build optimized release"
	@echo "  make debug        - Build debug version"
	@echo "  make clean        - Remove build directory"
	@echo "  make distclean    - Remove build and dist directories"
	@echo "  make install      - Install to system VST3 folder"
	@echo "  make run          - Run standalone executable"
	@echo ""
	@echo "Testing:"
	@echo "  make test         - Build and run unit tests"
	@echo "  make test-build   - Build tests only"
	@echo ""
	@echo "Development:"
	@echo "  make init		   - Initialize git submodules"
	@echo "  make format       - Format source code"
	@echo "  make help         - Show this help message"
