import AppKit
import Foundation
// Helper extension to make PDFDocument available
import PDFKit
import UniformTypeIdentifiers

class FileDetailsCapture {

  // Structure to hold file details
  struct FileDetails {
    var name: String
    var path: String
    var size: UInt64
    var type: String
    var creationDate: Date?
    var modificationDate: Date?
    var base64: String?
    var dimensions: (width: Int, height: Int)?
    var additionalMetadata: [String: Any]

    // Convert to dictionary for easy serialization
    func toDictionary() -> [String: Any] {
      var dict: [String: Any] = [
        "name": name,
        "path": path,
        "size": size,
        "type": type,
      ]

      if let creationDate = creationDate {
        dict["creationDate"] = creationDate
      }

      if let modificationDate = modificationDate {
        dict["modificationDate"] = modificationDate
      }

      if let base64 = base64 {
        dict["base64"] = base64
      }

      if let dimensions = dimensions {
        dict["width"] = dimensions.width
        dict["height"] = dimensions.height
      }

      for (key, value) in additionalMetadata {
        dict[key] = value
      }

      return dict
    }

    // Convert to formatted string for display
    func toFormattedString() -> String {
      var result = """
        File: \(name)
        Path: \(path)
        Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
        Type: \(type)
        """

      if let creationDate = creationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        result += "\nCreated: \(formatter.string(from: creationDate))"
      }

      if let modificationDate = modificationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        result += "\nModified: \(formatter.string(from: modificationDate))"
      }

      if let dimensions = dimensions {
        result += "\nDimensions: \(dimensions.width) × \(dimensions.height)"
      }

      // Add path for easy copying
      result += "\n\nFull Path: \(path)"

      // Add only base64 preview for images (first 100 chars)
      if type.contains("image") && base64 != nil {
        let previewLength = min(100, base64?.count ?? 0)
        result += "\n\nBase64 (preview): \(base64?.prefix(previewLength) ?? "")..."
      }

      return result
    }
  }

  // Capture file details from a URL
  func captureDetails(from url: URL) -> FileDetails? {
    do {
      // Get basic file attributes
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)

      // Extract basic info
      let name = url.lastPathComponent
      let path = url.path
      let size = fileAttributes[.size] as? UInt64 ?? 0

      // Get type information
      let typeIdentifier =
        try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? "unknown"
      let fileType = UTType(typeIdentifier)?.localizedDescription ?? "Unknown type"

      // Get dates
      let creationDate = fileAttributes[.creationDate] as? Date
      let modificationDate = fileAttributes[.modificationDate] as? Date

      // Additional metadata dictionary
      var additionalMetadata: [String: Any] = [:]

      // Get file extension
      additionalMetadata["extension"] = url.pathExtension

      // Initialize with basic information
      var fileDetails = FileDetails(
        name: name,
        path: path,
        size: size,
        type: fileType,
        creationDate: creationDate,
        modificationDate: modificationDate,
        base64: nil,
        dimensions: nil,
        additionalMetadata: additionalMetadata
      )

      // Add Base64 encoding for appropriate file types
      if let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
        // Handle images specifically
        if fileType.conforms(to: .image) {
          addImageDetails(to: &fileDetails, from: url)
        }
        // Handle PDFs
        else if fileType.conforms(to: .pdf) {
          addPDFDetails(to: &fileDetails, from: url)
        }
        // Handle text files
        else if fileType.conforms(to: .text) {
          addTextFileDetails(to: &fileDetails, from: url)
        }
        // Handle other binary files - just add base64 if not too large
        else if size < 1_000_000 {  // 1MB limit for base64 encoding
          addBase64(to: &fileDetails, from: url)
        }
      }

      return fileDetails

    } catch {
      print("Error getting file details: \(error)")
      return nil
    }
  }

  // Add image-specific details
  private func addImageDetails(to fileDetails: inout FileDetails, from url: URL) {
    if let image = NSImage(contentsOf: url) {
      // Get image dimensions
      let dimensions = (
        width: Int(image.size.width),
        height: Int(image.size.height)
      )
      fileDetails.dimensions = dimensions

      // Add image format to metadata
      if let imageRep = NSBitmapImageRep(data: try! Data(contentsOf: url)) {
        fileDetails.additionalMetadata["bitsPerPixel"] = imageRep.bitsPerPixel
        fileDetails.additionalMetadata["colorSpace"] = imageRep.colorSpaceName
      }

      // Add base64 encoding (with size limit)
      if fileDetails.size < 5_000_000 {  // 5MB limit for images
        addBase64(to: &fileDetails, from: url)
      }
    }
  }

  // Add PDF-specific details
  private func addPDFDetails(to fileDetails: inout FileDetails, from url: URL) {
    if let pdfDocument = PDFDocument(url: url) {
      // Get page count
      let pageCount = pdfDocument.pageCount
      fileDetails.additionalMetadata["pageCount"] = pageCount

      // Get PDF metadata if available
      if let pdfMetadata = pdfDocument.documentAttributes {
        for (key, value) in pdfMetadata {
          fileDetails.additionalMetadata["pdf_\(key)"] = value
        }
      }

      // Add base64 for smaller PDFs
      if fileDetails.size < 2_000_000 {  // 2MB limit for PDFs
        addBase64(to: &fileDetails, from: url)
      }
    }
  }

  // Add text file details
  private func addTextFileDetails(to fileDetails: inout FileDetails, from url: URL) {
    do {
      // Read text content
      let textContent = try String(contentsOf: url, encoding: .utf8)
      let previewLength = min(1000, textContent.count)
      fileDetails.additionalMetadata["textPreview"] = String(textContent.prefix(previewLength))

      // Count lines
      let lineCount = textContent.components(separatedBy: .newlines).count
      fileDetails.additionalMetadata["lineCount"] = lineCount

      // For text files, we don't need base64 since we can read the content directly
    } catch {
      print("Error reading text file: \(error)")
    }
  }

  // Add base64 encoding
  private func addBase64(to fileDetails: inout FileDetails, from url: URL) {
    do {
      let data = try Data(contentsOf: url)
      fileDetails.base64 = data.base64EncodedString()
    } catch {
      print("Error creating base64 encoding: \(error)")
    }
  }
}
