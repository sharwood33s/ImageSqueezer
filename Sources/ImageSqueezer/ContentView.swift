import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var jobs: [ImageJob] = []
    @State private var options = ResizeOptions()
    @State private var isDropTargeted = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 0) {
                sidebar
                Divider()
                mainPanel
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo.stack")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 3) {
                Text("ImageSqueezer")
                    .font(.system(size: 24, weight: .bold))
                Text("画像をまとめてリサイズ・圧縮")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                chooseImages()
            } label: {
                Label("画像を追加", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            Button {
                processAll()
            } label: {
                Label("書き出し", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(jobs.isEmpty || isProcessing)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        .background(.bar)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("書き出し設定")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Text("プリセット")
                    .font(.subheadline.weight(.semibold))
                Menu {
                    ForEach(ResizePreset.allCases) { preset in
                        Button {
                            options.apply(preset)
                        } label: {
                            Label("\(preset.label)（\(preset.sizeLabel)）", systemImage: "photo")
                        }
                    }
                } label: {
                    Label("サイズを選択", systemImage: "aspectratio")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("最大サイズ")
                    .font(.subheadline.weight(.semibold))
                HStack {
                    LabeledContent("幅") {
                        TextField("1920", value: $options.maxWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 88)
                    }
                    LabeledContent("高さ") {
                        TextField("1080", value: $options.maxHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 88)
                    }
                }
            }

            Toggle("縦横比を維持", isOn: $options.keepAspectRatio)
            Toggle("元画像より拡大する", isOn: $options.allowUpscale)

            VStack(alignment: .leading, spacing: 10) {
                Text("形式")
                    .font(.subheadline.weight(.semibold))
                Picker("形式", selection: $options.outputFormat) {
                    ForEach(OutputFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("品質")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(options.jpegQuality * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $options.jpegQuality, in: 0.1...1.0, step: 0.01)
                    .disabled(options.outputFormat == .png)
                Menu {
                    ForEach(CompressionPreset.allCases) { preset in
                        Button {
                            options.apply(preset)
                        } label: {
                            Label("\(preset.label)（\(preset.qualityLabel)）", systemImage: "slider.horizontal.3")
                        }
                    }
                } label: {
                    Label("圧縮率を選択", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                .disabled(options.outputFormat == .png)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("保存先")
                    .font(.subheadline.weight(.semibold))
                Button {
                    chooseOutputFolder()
                } label: {
                    Label(options.outputFolder == nil ? "元画像と同じ場所" : options.outputFolder!.lastPathComponent, systemImage: "folder")
                        .lineLimit(1)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(role: .destructive) {
                jobs.removeAll()
            } label: {
                Label("一覧をクリア", systemImage: "trash")
            }
            .disabled(jobs.isEmpty || isProcessing)
        }
        .padding(24)
        .frame(width: 300)
    }

    private var mainPanel: some View {
        VStack(spacing: 18) {
            dropZone

            if jobs.isEmpty {
                ContentUnavailableView(
                    "画像がありません",
                    systemImage: "photo.badge.plus",
                    description: Text("JPEG、PNG、HEIC、TIFF、WebP を追加できます")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                jobList
            }
        }
        .padding(24)
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(isDropTargeted ? Color.teal : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8]))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDropTargeted ? Color.teal.opacity(0.12) : Color.secondary.opacity(0.05))
            )
            .overlay {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc")
                        .font(.title2)
                        .foregroundStyle(.teal)
                    Text("ここに画像をドラッグ＆ドロップ")
                        .font(.headline)
                    Spacer()
                    Button("選択") {
                        chooseImages()
                    }
                }
                .padding(.horizontal, 22)
            }
            .frame(height: 92)
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
            }
    }

    private var jobList: some View {
        List {
            ForEach(jobs) { job in
                HStack(spacing: 14) {
                    Image(systemName: iconName(for: job.status))
                        .foregroundStyle(color(for: job.status))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.sourceURL.lastPathComponent)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(Int(job.originalSize.width)) x \(Int(job.originalSize.height)) px ・ \(formatBytes(job.originalBytes))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(job.status.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color(for: job.status))
                        if let outputBytes = job.outputBytes {
                            Text(formatBytes(outputBytes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .onDelete { offsets in
                jobs.remove(atOffsets: offsets)
            }
        }
        .listStyle(.inset)
    }

    private func chooseImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            addFiles(panel.urls)
        }
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            options.outputFolder = panel.url
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else {
                    return
                }

                DispatchQueue.main.async {
                    addFiles([url])
                }
            }
        }
        return true
    }

    private func addFiles(_ urls: [URL]) {
        for url in urls where ImageProcessor.supportedExtensions.contains(url.pathExtension.lowercased()) {
            guard !jobs.contains(where: { $0.sourceURL == url }),
                  let inspected = try? ImageProcessor.inspect(url: url)
            else {
                continue
            }

            jobs.append(ImageJob(sourceURL: url, originalSize: inspected.size, originalBytes: inspected.bytes))
        }
    }

    private func processAll() {
        isProcessing = true
        let currentJobs = jobs
        let currentOptions = options

        Task.detached {
            for job in currentJobs {
                await update(jobID: job.id, status: .processing)

                do {
                    let result = try ImageProcessor.process(job: job, options: currentOptions)
                    await update(jobID: job.id, status: .completed, outputURL: result.url, outputBytes: result.bytes)
                } catch {
                    await update(jobID: job.id, status: .failed(error.localizedDescription))
                }
            }

            await MainActor.run {
                isProcessing = false
            }
        }
    }

    @MainActor
    private func update(jobID: UUID, status: ImageJob.Status, outputURL: URL? = nil, outputBytes: Int64? = nil) {
        guard let index = jobs.firstIndex(where: { $0.id == jobID }) else { return }
        jobs[index].status = status
        jobs[index].outputURL = outputURL ?? jobs[index].outputURL
        jobs[index].outputBytes = outputBytes ?? jobs[index].outputBytes
    }

    private func iconName(for status: ImageJob.Status) -> String {
        switch status {
        case .pending: "circle"
        case .processing: "clock"
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    private func color(for status: ImageJob.Status) -> Color {
        switch status {
        case .pending: .secondary
        case .processing: .orange
        case .completed: .green
        case .failed: .red
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
