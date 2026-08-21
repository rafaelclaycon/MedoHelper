//
//  FolderResearchComponents.swift
//  MedoHelper
//
//  Created by Claude on 21/08/26.
//

import SwiftUI

// MARK: - Color Palette

/// Maps the app's named pastel folder colors to actual `Color` values. Names that
/// aren't recognized still render a stable, visually distinct color (hashed to a
/// hue) instead of falling back to a single generic gray.
enum FolderColorPalette {

    private static let known: [String: Color] = [
        "pastelPurple": Color(red: 0.80, green: 0.70, blue: 0.95),
        "pastelBrightGreen": Color(red: 0.68, green: 0.93, blue: 0.68),
        "pastelGreen": Color(red: 0.72, green: 0.88, blue: 0.75),
        "pastelBlue": Color(red: 0.70, green: 0.85, blue: 0.98),
        "pastelBrightBlue": Color(red: 0.55, green: 0.80, blue: 0.98),
        "pastelPink": Color(red: 0.98, green: 0.75, blue: 0.85),
        "pastelYellow": Color(red: 0.99, green: 0.93, blue: 0.65),
        "pastelOrange": Color(red: 0.99, green: 0.80, blue: 0.60),
        "pastelRed": Color(red: 0.95, green: 0.65, blue: 0.65),
        "pastelTeal": Color(red: 0.65, green: 0.90, blue: 0.88),
        "pastelGray": Color(red: 0.85, green: 0.85, blue: 0.87),
        "pastelBrown": Color(red: 0.80, green: 0.68, blue: 0.58)
    ]

    static func color(for name: String) -> Color {
        if let known = known[name] { return known }
        var hasher = Hasher()
        hasher.combine(name)
        let hue = Double(abs(hasher.finalize()) % 360) / 360.0
        return Color(hue: hue, saturation: 0.45, brightness: 0.95)
    }
}

// MARK: - Relative Time

enum FolderResearchDateFormatting {

    static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt-BR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    static func monthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt-BR")
        formatter.dateFormat = "MMM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Chips Row

struct FolderResearchChipsRow: View {
    let title: String
    let items: [FolderResearchNamedCount]
    var showsColorSwatch: Bool = false

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            HStack(spacing: 6) {
                                if showsColorSwatch {
                                    Circle()
                                        .fill(FolderColorPalette.color(for: item.name))
                                        .frame(width: 10, height: 10)
                                }
                                Text(item.name)
                                    .font(.caption)
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - User Row

struct FolderResearchUserRow: View {
    let user: FolderResearchUser
    let isExpanded: Bool
    let expandedFolderID: String?
    let onToggleUser: () -> Void
    let onToggleFolder: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(user.folders) { folder in
                            FolderTileView(
                                folder: folder,
                                isExpanded: expandedFolderID == folder.id,
                                onTap: { onToggleFolder(folder.id) }
                            )
                        }
                    }

                    if let expandedFolderID, let folder = user.folders.first(where: { $0.id == expandedFolderID }) {
                        FolderDetailView(folder: folder)
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    private var header: some View {
        Button(action: onToggleUser) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(shortInstallId)
                            .font(.system(.body, design: .monospaced))
                        Button {
                            copyToClipboard(user.installId)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help("Copiar install ID completo")
                    }

                    if !user.devices.isEmpty {
                        Text("📱 " + user.devices.map(\.modelName).joined(separator: " → "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 12) {
                        Label("\(user.folderCount)", systemImage: "folder")
                        Label("\(user.contentCount)", systemImage: "square.stack.3d.up")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let date = user.lastActivityDate {
                        Text(FolderResearchDateFormatting.relative(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var shortInstallId: String {
        String(user.installId.prefix(8)) + "…"
    }

    private func copyToClipboard(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}

// MARK: - Folder Tile

struct FolderTileView: View {
    let folder: FolderResearchFolder
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(folder.symbol)
                        .font(.system(size: 32))
                    Spacer()
                    Text("\(folder.contentCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                Text(folder.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let lastUpdated = folder.lastUpdatedDate {
                    Text("editada \(FolderResearchDateFormatting.relative(lastUpdated))")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FolderColorPalette.color(for: folder.backgroundColor).opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isExpanded ? Color.accentColor : .clear, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Detail

struct FolderDetailView: View {
    let folder: FolderResearchFolder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FolderTimelineView(
                dates: folder.historyDates,
                createdAt: folder.createdAtDate,
                lastUpdated: folder.lastUpdatedDate,
                changeCount: folder.changeCount
            )

            if folder.contents.isEmpty {
                Text("Nenhum conteúdo nesta pasta.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(folder.contents) { content in
                        HStack(spacing: 8) {
                            Image(systemName: content.isSound ? "waveform" : "music.note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16)

                            Text(content.title)
                                .font(.caption)
                                .lineLimit(1)

                            if let author = content.authorName {
                                Text("· \(author)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.18))
        .cornerRadius(10)
    }
}

// MARK: - Folder Timeline

/// A small date-axis sparkline: one dot per snapshot in `dates`, positioned by
/// its proportional distance between the first and last snapshot.
struct FolderTimelineView: View {
    let dates: [Date]
    let createdAt: Date?
    let lastUpdated: Date?
    let changeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let createdAt, let lastUpdated {
                Text("criada \(FolderResearchDateFormatting.monthYear(createdAt)) · editada \(changeCount)x · último toque \(FolderResearchDateFormatting.monthYear(lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if dates.count > 1, let first = dates.first, let last = dates.last, last > first {
                let span = last.timeIntervalSince1970 - first.timeIntervalSince1970
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(height: 3)

                        ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                            let progress = (date.timeIntervalSince1970 - first.timeIntervalSince1970) / span
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .position(x: CGFloat(progress) * geo.size.width, y: 1.5)
                        }
                    }
                }
                .frame(height: 12)
            }
        }
    }
}
