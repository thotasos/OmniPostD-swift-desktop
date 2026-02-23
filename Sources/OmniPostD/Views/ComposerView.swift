import SwiftUI
import UniformTypeIdentifiers

struct ComposerView: View {
    @EnvironmentObject private var store: AppStore

    @State private var content = ""
    @State private var selectedPlatforms: Set<PlatformID> = []
    @State private var overrides: [PlatformID: String] = [:]
    @State private var mediaPaths: [String] = []
    @State private var showingImporter = false
    @State private var notice = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Composer")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                    TextEditor(text: $content)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .glassCard()

                mediaSection
                platformSelector
                overrideSection
                previewSection
                actionRow

                if !notice.isEmpty {
                    Text(notice)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.image, .movie], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                mediaPaths.append(contentsOf: urls.map { $0.path })
            case .failure(let error):
                notice = "Media import failed: \(error.localizedDescription)"
            }
        }
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Media")
                .font(.headline)
            HStack {
                Button("Attach Media") {
                    showingImporter = true
                }
                .buttonStyle(.bordered)

                Text("\(mediaPaths.count) file(s) selected")
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Platforms")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(PlatformCatalog.all) { platform in
                    let connected = store.connectedPlatformIDs.contains(platform.id)
                    let selected = selectedPlatforms.contains(platform.id)

                    Button {
                        if selected {
                            selectedPlatforms.remove(platform.id)
                        } else {
                            selectedPlatforms.insert(platform.id)
                        }
                    } label: {
                        HStack {
                            Text(platform.name)
                                .lineLimit(1)
                            Spacer()
                            Text("\(platform.characterLimit)")
                                .font(.caption)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selected ? Theme.platformColor(platform.id).opacity(0.25) : Color.white.opacity(0.55))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!connected)
                    .opacity(connected ? 1.0 : 0.45)
                    .animation(.spring(duration: 0.25), value: selected)
                }
            }
        }
        .glassCard()
    }

    private var overrideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform Overrides")
                .font(.headline)
            if selectedPlatforms.isEmpty {
                Text("Select a platform to add an override")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(selectedPlatforms).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { platform in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(platform.rawValue.capitalized) Caption")
                            .font(.subheadline.weight(.semibold))
                        TextEditor(text: Binding(
                            get: { overrides[platform] ?? "" },
                            set: { overrides[platform] = $0 }
                        ))
                        .frame(minHeight: 70)
                        .padding(8)
                        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .glassCard()
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)
            Text(content.isEmpty ? "Your content will appear here..." : content)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !mediaPaths.isEmpty {
                Text("Attached: \(mediaPaths.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }

    private var actionRow: some View {
        HStack {
            Button("Post Now") {
                publishNow()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedPlatforms.isEmpty)

            Button("Queue") {
                queuePost()
            }
            .buttonStyle(.bordered)
            .disabled(selectedPlatforms.isEmpty)
        }
        .glassCard()
    }

    private func publishNow() {
        let result = store.publishNow(
            content: content,
            mediaPaths: mediaPaths,
            overrides: overrides,
            targets: Array(selectedPlatforms)
        )
        notice = result.success ? "Post published." : "Publish failed. Review Queue."
        resetComposer()
    }

    private func queuePost() {
        store.queue(content: content, mediaPaths: mediaPaths, overrides: overrides, targets: Array(selectedPlatforms))
        notice = "Post queued."
        resetComposer()
    }

    private func resetComposer() {
        content = ""
        selectedPlatforms = []
        overrides = [:]
        mediaPaths = []
    }
}
