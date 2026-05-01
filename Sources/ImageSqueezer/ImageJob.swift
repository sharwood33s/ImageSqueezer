import AppKit
import Foundation

struct ImageJob: Identifiable, Hashable, Sendable {
    let id = UUID()
    let sourceURL: URL
    let originalSize: CGSize
    let originalBytes: Int64
    var outputURL: URL?
    var outputBytes: Int64?
    var status: Status = .pending

    enum Status: Hashable, Sendable {
        case pending
        case processing
        case completed
        case failed(String)

        var label: String {
            switch self {
            case .pending:
                "待機中"
            case .processing:
                "処理中"
            case .completed:
                "完了"
            case .failed(let message):
                "失敗: \(message)"
            }
        }
    }
}

enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case jpeg
    case png
    case heic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .jpeg: "JPEG"
        case .png: "PNG"
        case .heic: "HEIC"
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: "jpg"
        case .png: "png"
        case .heic: "heic"
        }
    }

    var uniformTypeIdentifier: CFString {
        switch self {
        case .jpeg: "public.jpeg" as CFString
        case .png: "public.png" as CFString
        case .heic: "public.heic" as CFString
        }
    }
}

enum ResizePreset: String, CaseIterable, Identifiable, Sendable {
    case thumbnail
    case blog
    case socialSquare
    case fullHD
    case fourK

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thumbnail: "サムネイル"
        case .blog: "ブログ"
        case .socialSquare: "SNS 正方形"
        case .fullHD: "フルHD"
        case .fourK: "4K"
        }
    }

    var maxWidth: Double {
        switch self {
        case .thumbnail: 640
        case .blog: 1200
        case .socialSquare: 1080
        case .fullHD: 1920
        case .fourK: 3840
        }
    }

    var maxHeight: Double {
        switch self {
        case .thumbnail: 640
        case .blog: 800
        case .socialSquare: 1080
        case .fullHD: 1080
        case .fourK: 2160
        }
    }

    var sizeLabel: String {
        "\(Int(maxWidth)) x \(Int(maxHeight)) px"
    }
}

struct ResizeOptions: Equatable, Sendable {
    var maxWidth: Double = 1920
    var maxHeight: Double = 1080
    var keepAspectRatio = true
    var allowUpscale = false
    var outputFormat: OutputFormat = .jpeg
    var jpegQuality: Double = 0.78
    var outputFolder: URL?

    mutating func apply(_ preset: ResizePreset) {
        maxWidth = preset.maxWidth
        maxHeight = preset.maxHeight
        keepAspectRatio = true
    }
}
