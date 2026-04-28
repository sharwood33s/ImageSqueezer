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

struct ResizeOptions: Equatable, Sendable {
    var maxWidth: Double = 1920
    var maxHeight: Double = 1080
    var keepAspectRatio = true
    var allowUpscale = false
    var outputFormat: OutputFormat = .jpeg
    var jpegQuality: Double = 0.78
    var outputFolder: URL?
}
