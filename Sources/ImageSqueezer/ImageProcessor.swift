import AppKit
import CoreGraphics
import Foundation
import ImageIO

enum ImageProcessorError: LocalizedError {
    case cannotLoadImage
    case cannotCreateBitmap
    case cannotCreateDestination
    case cannotFinalize

    var errorDescription: String? {
        switch self {
        case .cannotLoadImage:
            "画像を読み込めませんでした"
        case .cannotCreateBitmap:
            "リサイズ画像を作成できませんでした"
        case .cannotCreateDestination:
            "保存先を作成できませんでした"
        case .cannotFinalize:
            "画像を書き込めませんでした"
        }
    }
}

struct ImageProcessor {
    static let supportedExtensions = Set(["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp"])

    static func inspect(url: URL) throws -> (size: CGSize, bytes: Int64) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            throw ImageProcessorError.cannotLoadImage
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = attributes[.size] as? Int64 ?? 0
        return (CGSize(width: width, height: height), bytes)
    }

    static func process(job: ImageJob, options: ResizeOptions) throws -> (url: URL, bytes: Int64) {
        guard let image = NSImage(contentsOf: job.sourceURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            throw ImageProcessorError.cannotLoadImage
        }

        let targetSize = scaledSize(
            original: CGSize(width: cgImage.width, height: cgImage.height),
            options: options
        )
        let rendered = try render(cgImage: cgImage, size: targetSize)
        let destinationURL = makeDestinationURL(for: job.sourceURL, options: options)

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            options.outputFormat.uniformTypeIdentifier,
            1,
            nil
        ) else {
            throw ImageProcessorError.cannotCreateDestination
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: options.jpegQuality
        ]

        if options.outputFormat == .png {
            properties = [:]
        }

        CGImageDestinationAddImage(destination, rendered, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessorError.cannotFinalize
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let bytes = attributes[.size] as? Int64 ?? 0
        return (destinationURL, bytes)
    }

    private static func scaledSize(original: CGSize, options: ResizeOptions) -> CGSize {
        let widthRatio = options.maxWidth / original.width
        let heightRatio = options.maxHeight / original.height
        let ratio = options.keepAspectRatio ? min(widthRatio, heightRatio) : 1
        let boundedRatio = options.allowUpscale ? ratio : min(ratio, 1)

        if options.keepAspectRatio {
            return CGSize(
                width: max(1, round(original.width * boundedRatio)),
                height: max(1, round(original.height * boundedRatio))
            )
        }

        return CGSize(width: max(1, round(options.maxWidth)), height: max(1, round(options.maxHeight)))
    }

    private static func render(cgImage: CGImage, size: CGSize) throws -> CGImage {
        guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
            throw ImageProcessorError.cannotCreateBitmap
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let output = context.makeImage() else {
            throw ImageProcessorError.cannotCreateBitmap
        }
        return output
    }

    private static func makeDestinationURL(for sourceURL: URL, options: ResizeOptions) -> URL {
        let folder = options.outputFolder ?? sourceURL.deletingLastPathComponent()
        let base = sourceURL.deletingPathExtension().lastPathComponent
        let name = "\(base)-squeezed.\(options.outputFormat.fileExtension)"
        var destination = folder.appendingPathComponent(name)

        var index = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = folder.appendingPathComponent("\(base)-squeezed-\(index).\(options.outputFormat.fileExtension)")
            index += 1
        }

        return destination
    }
}
