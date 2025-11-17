package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"epub-renamer/pkg/epub"
	"epub-renamer/pkg/renamer"
)

func main() {
	dryRun := flag.Bool("dry-run", false, "Show what would be renamed without actually doing it")
	flag.Parse()

	if flag.NArg() == 0 {
		fmt.Println("Usage: epub-renamer [options] file.epub [file2.epub ...]")
		fmt.Println("Options:")
		flag.PrintDefaults()
		fmt.Println("\nExamples:")
		fmt.Println("  epub-renamer book.epub")
		fmt.Println("  epub-renamer --dry-run *.epub")
		os.Exit(1)
	}

	r := renamer.New()
	successCount := 0

	for _, filePath := range flag.Args() {
		if err := processFile(filePath, r, *dryRun); err != nil {
			log.Printf("Error processing %s: %v", filePath, err)
		} else {
			successCount++
		}
	}

	fmt.Printf("\nProcessed %d/%d files successfully\n", successCount, flag.NArg())
	if successCount != flag.NArg() {
		os.Exit(1)
	}
}

func processFile(filePath string, r *renamer.Renamer, dryRun bool) error {
	fmt.Printf("Processing: %s\n", filePath)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return fmt.Errorf("file not found: %s", filePath)
	}

	// Extract metadata
	title, author, err := epub.ExtractMetadata(filePath)
	if err != nil {
		return fmt.Errorf("failed to extract metadata: %w", err)
	}

	// Generate new filename
	newName := r.GenerateFilename(title, author, filePath)

	if dryRun {
		fmt.Printf("Would rename: %s -> %s\n", filePath, newName)
		return nil
	}

	// Rename file
	if err := r.RenameFile(filePath, newName); err != nil {
		return fmt.Errorf("failed to rename file: %w", err)
	}

	fmt.Printf("Renamed: %s -> %s\n", filePath, newName)
	return nil
}
