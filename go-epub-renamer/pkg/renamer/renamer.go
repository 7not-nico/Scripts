package renamer

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Renamer handles file renaming operations
type Renamer struct{}

// New creates a new Renamer instance
func New() *Renamer {
	return &Renamer{}
}

// SanitizeFilename sanitizes text for use in filenames
func (r *Renamer) SanitizeFilename(text string) string {
	if text == "" {
		return "Unknown"
	}

	// Replace invalid characters
	invalidChars := `<>:"/\|?*`
	for _, char := range invalidChars {
		text = strings.ReplaceAll(text, string(char), "_")
	}

	// Remove control characters
	var result strings.Builder
	for _, r := range text {
		if r >= 32 { // Printable characters only
			result.WriteRune(r)
		}
	}

	// Normalize whitespace
	text = strings.Join(strings.Fields(result.String()), " ")

	// Limit length
	if len(text) > 100 {
		return text[:100]
	}
	return text
}

// GenerateFilename generates new filename in format: title - author.epub
func (r *Renamer) GenerateFilename(title, author, originalPath string) string {
	titleClean := r.SanitizeFilename(title)
	authorClean := r.SanitizeFilename(author)

	// Handle missing metadata
	if titleClean == "" || titleClean == "Unknown" {
		titleClean = "Unknown Title"
	}
	if authorClean == "" || authorClean == "Unknown" {
		authorClean = "Unknown Author"
	}

	return fmt.Sprintf("%s - %s.epub", titleClean, authorClean)
}

// RenameFile safely renames a file
func (r *Renamer) RenameFile(oldPath, newName string) error {
	dir := filepath.Dir(oldPath)
	newPath := filepath.Join(dir, newName)

	// Check if target already exists
	if _, err := os.Stat(newPath); err == nil {
		return fmt.Errorf("target file already exists: %s", newPath)
	}

	// Rename the file
	if err := os.Rename(oldPath, newPath); err != nil {
		return fmt.Errorf("failed to rename file: %w", err)
	}

	return nil
}
