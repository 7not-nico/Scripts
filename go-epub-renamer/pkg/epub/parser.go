package epub

import (
	"archive/zip"
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

// Metadata represents epub metadata
type Metadata struct {
	Title   string `xml:"title"`
	Creator string `xml:"creator"`
}

// OPF represents the Open Packaging Format structure
type OPF struct {
	Metadata Metadata `xml:"metadata"`
}

// ExtractMetadata extracts title and author from an epub file
func ExtractMetadata(epubPath string) (title, author string, err error) {
	reader, err := zip.OpenReader(epubPath)
	if err != nil {
		return "", "", fmt.Errorf("failed to open epub: %w", err)
	}
	defer reader.Close()

	// Find container.xml
	var containerFile *zip.File
	for _, file := range reader.File {
		if file.Name == "META-INF/container.xml" {
			containerFile = file
			break
		}
	}

	if containerFile == nil {
		return "", "", fmt.Errorf("container.xml not found")
	}

	// Read container.xml
	containerData, err := readZipFile(containerFile)
	if err != nil {
		return "", "", fmt.Errorf("failed to read container.xml: %w", err)
	}

	// Parse container to find content.opf path
	opfPath, err := parseContainer(containerData)
	if err != nil {
		return "", "", fmt.Errorf("failed to parse container: %w", err)
	}

	// Find and read content.opf
	var opfFile *zip.File
	for _, file := range reader.File {
		if file.Name == opfPath {
			opfFile = file
			break
		}
	}

	if opfFile == nil {
		return "", "", fmt.Errorf("content.opf not found at %s", opfPath)
	}

	// Read and parse content.opf
	opfData, err := readZipFile(opfFile)
	if err != nil {
		return "", "", fmt.Errorf("failed to read content.opf: %w", err)
	}

	title, author, err = parseOPF(opfData)
	if err != nil {
		return "", "", fmt.Errorf("failed to parse OPF: %w", err)
	}

	return title, author, nil
}

// readZipFile reads the contents of a zip file entry
func readZipFile(file *zip.File) ([]byte, error) {
	rc, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer rc.Close()

	return io.ReadAll(rc)
}

// parseContainer extracts the content.opf path from container.xml
func parseContainer(data []byte) (string, error) {
	type Container struct {
		Rootfiles struct {
			Rootfile struct {
				FullPath string `xml:"full-path,attr"`
			} `xml:"rootfile"`
		} `xml:"rootfiles"`
	}

	var container Container
	if err := xml.Unmarshal(data, &container); err != nil {
		return "", err
	}

	if container.Rootfiles.Rootfile.FullPath == "" {
		return "", fmt.Errorf("no rootfile found in container")
	}

	return container.Rootfiles.Rootfile.FullPath, nil
}

// parseOPF extracts title and author from content.opf
func parseOPF(data []byte) (title, author string, err error) {
	// Simple XML parsing for Dublin Core metadata
	dataStr := string(data)

	// Extract title
	if titleStart := strings.Index(dataStr, "<dc:title"); titleStart != -1 {
		if titleEnd := strings.Index(dataStr[titleStart:], "</dc:title>"); titleEnd != -1 {
			titleContent := dataStr[titleStart : titleStart+titleEnd+10]
			if start := strings.Index(titleContent, ">"); start != -1 {
				if end := strings.LastIndex(titleContent, "<"); end > start {
					title = strings.TrimSpace(titleContent[start+1 : end])
				}
			}
		}
	}

	// Extract author/creator
	if authorStart := strings.Index(dataStr, "<dc:creator"); authorStart != -1 {
		if authorEnd := strings.Index(dataStr[authorStart:], "</dc:creator>"); authorEnd != -1 {
			authorContent := dataStr[authorStart : authorStart+authorEnd+12]
			if start := strings.Index(authorContent, ">"); start != -1 {
				if end := strings.LastIndex(authorContent, "<"); end > start {
					author = strings.TrimSpace(authorContent[start+1 : end])
				}
			}
		}
	}

	return title, author, nil
}
