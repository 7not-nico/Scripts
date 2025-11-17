.PHONY: build build-all clean test

# Build for current platform
build:
	go build -o bin/epub-renamer ./cmd/epub-renamer

# Build for multiple platforms
build-all: build-linux build-darwin build-windows

build-linux:
	GOOS=linux GOARCH=amd64 go build -o bin/epub-renamer-linux-amd64 ./cmd/epub-renamer
	GOOS=linux GOARCH=arm64 go build -o bin/epub-renamer-linux-arm64 ./cmd/epub-renamer

build-darwin:
	GOOS=darwin GOARCH=amd64 go build -o bin/epub-renamer-darwin-amd64 ./cmd/epub-renamer
	GOOS=darwin GOARCH=arm64 go build -o bin/epub-renamer-darwin-arm64 ./cmd/epub-renamer

build-windows:
	GOOS=windows GOARCH=amd64 go build -o bin/epub-renamer-windows-amd64.exe ./cmd/epub-renamer
	GOOS=windows GOARCH=386 go build -o bin/epub-renamer-windows-386.exe ./cmd/epub-renamer

# Clean build artifacts
clean:
	rm -rf bin/

# Run tests
test:
	go test ./...

# Install locally
install: build
	cp bin/epub-renamer /usr/local/bin/

# Development setup
dev:
	go mod tidy
	go mod download