import SwiftUI

struct ContentView: View {
    @StateObject private var org = Organizer()
    @State private var root: URL?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.55), .teal.opacity(0.45), .purple.opacity(0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill.badge.gearshape")
                        .font(.title)
                    Text("Tidy").font(.largeTitle.bold())
                    Spacer()
                }

                HStack {
                    Button("Choose Folder", systemImage: "folder") { pickFolder() }
                        .buttonStyle(.glass)
                    Text(root?.path ?? "No folder selected")
                        .font(.callout).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                }

                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Scan", systemImage: "magnifyingglass") {
                            if let r = root { org.buildPlan(root: r) }
                        }
                        .buttonStyle(.glass)
                        .disabled(root == nil || org.isScanning)

                        Button("Organize", systemImage: "wand.and.stars") { org.apply() }
                            .buttonStyle(.glassProminent)
                            .disabled(org.plan.isEmpty)

                        Button("Undo", systemImage: "arrow.uturn.backward") { org.undoLast() }
                            .buttonStyle(.glass)
                            .disabled(org.history.isEmpty)

                        if org.isScanning { ProgressView().controlSize(.small) }
                        Spacer()
                    }
                }

                List(org.plan) { r in
                    HStack(spacing: 8) {
                        Image(systemName: "doc")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.from.lastPathComponent).lineLimit(1)
                            if r.from.lastPathComponent != r.to.lastPathComponent {
                                Text("Rename to \(r.to.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text(r.reason).font(.caption).foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                        Text(r.to.deletingLastPathComponent().lastPathComponent).bold()
                        Button { org.skip(r) } label: { Image(systemName: "xmark.circle") }
                            .buttonStyle(.plain)
                            .help("Skip this file")
                    }
                }
                .scrollContentBackground(.hidden)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))

                Text(org.status)
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .frame(minWidth: 680, minHeight: 480)
    }

    private func pickFolder() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true
        p.canChooseFiles = false
        p.prompt = "Choose"
        if p.runModal() == .OK { root = p.url; org.plan = [] }
    }
}
