.PHONY: generate build test clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project MemeMill.xcodeproj -scheme MemeMill -configuration Debug build

test: generate
	xcodebuild -project MemeMill.xcodeproj -scheme MemeMill -configuration Debug test

clean:
	xcodebuild -project MemeMill.xcodeproj -scheme MemeMill clean
	rm -rf DerivedData build
