//
//  TranscriptSearchPanel.swift
//  MedoHelper
//
//  Right pane of the Sound Requests tab. Lets the operator search every
//  transcribed episode (SRT files hosted at `baseURL + "transcripts/v1/"`)
//  and jump to the matching moment so the sound bite can be cut directly
//  in Audacity.
//

import SwiftUI

struct TranscriptSearchPanel: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            searchField
                .padding(12)
            Divider()
            resultsArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await viewModel.onFirstAppear() }
        .alert(
            "Erro",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Busca em Transcrições")
                    .font(.headline)
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            downloadControls
        }
        .padding(12)
    }

    private var statusLine: String {
        if viewModel.isRebuildingIndex {
            return "Indexando transcrições localmente…"
        }
        switch viewModel.downloads.state {
        case .idle:
            if viewModel.downloads.localFileCount == 0 {
                return "Nenhuma transcrição baixada ainda."
            }
            return "\(viewModel.downloads.localFileCount) transcrição(ões) localizada(s)."
        case .preparing:
            return "Consultando servidor…"
        case .downloading(let current, let total):
            return "Baixando \(current) de \(total)…"
        case .completed(let downloaded, let failed):
            if downloaded == 0 && failed == 0 {
                return "Tudo atualizado — \(viewModel.downloads.localFileCount) arquivo(s) locais."
            }
            if failed == 0 {
                return "Download concluído: \(downloaded) arquivo(s) novo(s) ou atualizado(s)."
            }
            return "Download concluído: \(downloaded) baixado(s), \(failed) falha(s)."
        case .failed(let message):
            return "Falha: \(message)"
        }
    }

    /// True whenever the download pipeline or the post-download index rebuild is
    /// doing background work. The header swaps its action button for a progress
    /// indicator during this window.
    private var isBusy: Bool {
        if viewModel.isRebuildingIndex { return true }
        switch viewModel.downloads.state {
        case .preparing, .downloading: return true
        default: return false
        }
    }

    @ViewBuilder
    private var downloadControls: some View {
        HStack(spacing: 8) {
            if isBusy {
                progressIndicator
            } else {
                Button {
                    Task { await viewModel.onDownloadAllTapped() }
                } label: {
                    Label("Baixar/Sincronizar", systemImage: "arrow.down.circle")
                }

                Menu {
                    Button(role: .destructive) {
                        viewModel.onDeleteAllTapped()
                    } label: {
                        Label("Apagar todas as transcrições", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
            }
        }
    }

    @ViewBuilder
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            switch viewModel.downloads.state {
            case .downloading(let current, let total) where !viewModel.isRebuildingIndex:
                ProgressView(value: Double(current), total: Double(total))
                    .progressViewStyle(.linear)
                    .frame(width: 140)
                Text("\(current)/\(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 52, alignment: .trailing)
            default:
                // `.preparing` and post-download index rebuild have no knowable
                // progress — show an indeterminate spinner instead.
                ProgressView()
                    .controlSize(.small)
                Text(busyLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var busyLabel: String {
        if viewModel.isRebuildingIndex {
            return "Indexando…"
        }
        if case .preparing = viewModel.downloads.state {
            return "Preparando…"
        }
        return "Trabalhando…"
    }

    // MARK: - Search field

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    "Buscar nas transcrições (ex. elefante, bolsonaro, brasília)",
                    text: $viewModel.query
                )
                .textFieldStyle(.plain)

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            modePicker
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            Picker("Modo de busca", selection: $viewModel.mode) {
                ForEach(TranscriptSearchMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            Text(viewModel.mode.help)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsArea: some View {
        if viewModel.isSearching && viewModel.results.isEmpty {
            VStack {
                ProgressView("Buscando…")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            emptyHint
        } else if viewModel.results.isEmpty {
            ContentUnavailableView.search(text: viewModel.query)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            resultsList
        }
    }

    private var emptyHint: some View {
        ContentUnavailableView {
            Label("Digite para buscar", systemImage: "text.magnifyingglass")
        } description: {
            if viewModel.downloads.localFileCount == 0 {
                Text("Baixe as transcrições pela primeira vez para começar a buscar.")
            } else {
                Text("Digite ao menos 2 caracteres para buscar entre \(viewModel.search.indexedEpisodeCount) episódio(s).")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.results) { group in
                    episodeCard(for: group)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Episode card

    private func episodeCard(for group: EpisodeTranscriptGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            episodeHeader(for: group.episode)

            Divider()

            ForEach(group.matches) { match in
                matchRow(match: match, episode: group.episode)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    private func episodeHeader(for episode: PodcastEpisode) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.headline)
                    .lineLimit(2)
                if let date = episode.pubDate {
                    Text(date, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            audioActionButtons(for: episode)
        }
    }

    @ViewBuilder
    private func audioActionButtons(for episode: PodcastEpisode) -> some View {
        HStack(spacing: 6) {
            switch viewModel.audio.state {
            case .downloading(let id) where id == episode.id:
                ProgressView()
                    .controlSize(.small)
                Text("Baixando MP3…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .opening(let id) where id == episode.id:
                ProgressView()
                    .controlSize(.small)
                Text("Abrindo…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            default:
                Button {
                    viewModel.onOpenInAudacityTapped(episode)
                } label: {
                    Label("Abrir no Audacity", systemImage: "waveform")
                }
                .disabled(episode.audioURL == nil)
                .help(episode.audioURL == nil ? "URL de áudio não disponível" : "Baixar MP3 e abrir no Audacity")

                Button {
                    viewModel.onRevealInFinderTapped(episode)
                } label: {
                    Image(systemName: "folder")
                }
                .disabled(episode.audioURL == nil)
                .help("Mostrar no Finder")
            }
        }
    }

    private func matchRow(match: TranscriptMatch, episode: PodcastEpisode) -> some View {
        HStack(alignment: .top, spacing: 10) {
            previewButton(match: match, episode: episode)

            Text(match.formattedTimestamp)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .textSelection(.enabled)

            highlightedText(
                for: match.cueText,
                query: viewModel.query,
                mode: viewModel.mode
            )
            .font(.body)
            .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    /// Small play/stop button rendered ahead of each match row so the user can
    /// preview the excerpt in-place before committing to Audacity.
    private func previewButton(match: TranscriptMatch, episode: PodcastEpisode) -> some View {
        let excerpt = TranscriptPlaybackService.Excerpt(
            episodeId: episode.id,
            timestamp: match.timestamp
        )
        let isPreparing = viewModel.playback.preparing == excerpt
        let isPlaying = viewModel.playback.playing == excerpt
        let disabled = episode.audioURL == nil

        return Button {
            viewModel.onTogglePreviewTapped(match: match, episode: episode)
        } label: {
            ZStack {
                Circle()
                    .fill(isPlaying ? Color.accentColor.opacity(0.2) : Color.clear)
                    .frame(width: 24, height: 24)

                if isPreparing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            disabled ? Color.secondary
                                     : (isPlaying ? Color.accentColor : Color.primary)
                        )
                }
            }
            .frame(width: 24, height: 24)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(
            disabled
                ? "URL de áudio indisponível"
                : (isPlaying ? "Parar prévia" : "Tocar prévia a partir de \(match.formattedTimestamp)")
        )
    }

    /// Case- and diacritic-insensitive highlighter.
    ///
    /// In `.exact` mode the whole query string is highlighted as one span.
    /// In `.anyGap` mode each query token is highlighted separately, in order —
    /// so the user sees *why* a cue matched when the tokens are far apart.
    private func highlightedText(
        for text: String,
        query: String,
        mode: TranscriptSearchMode
    ) -> Text {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return Text(text) }

        // Build a character-index-aligned version of `text` for matching.
        // We fold diacritics but preserve character count so ranges map back
        // to the original string directly.
        let haystack = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()

        let needles: [String]
        switch mode {
        case .exact:
            let n = trimmedQuery
                .folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
            needles = n.isEmpty ? [] : [n]
        case .anyGap:
            needles = trimmedQuery
                .folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
                .filter { !$0.isEmpty }
        }

        guard !needles.isEmpty else { return Text(text) }

        // Walk `haystack` in order, collecting non-overlapping ranges.
        var ranges: [Range<String.Index>] = []
        var cursor = haystack.startIndex
        for needle in needles {
            guard let r = haystack.range(of: needle, range: cursor..<haystack.endIndex) else {
                continue
            }
            ranges.append(r)
            cursor = r.upperBound
        }
        guard !ranges.isEmpty else { return Text(text) }

        // Splice the original text, highlighting each matched span.
        var result = Text("")
        var lastEnd = text.startIndex
        for range in ranges {
            let lowerOffset = haystack.distance(from: haystack.startIndex, to: range.lowerBound)
            let upperOffset = haystack.distance(from: haystack.startIndex, to: range.upperBound)
            let lower = text.index(text.startIndex, offsetBy: lowerOffset)
            let upper = text.index(text.startIndex, offsetBy: upperOffset)

            result = result + Text(String(text[lastEnd..<lower]))
            result = result + Text(String(text[lower..<upper])).bold().foregroundColor(.accentColor)
            lastEnd = upper
        }
        result = result + Text(String(text[lastEnd..<text.endIndex]))
        return result
    }
}

#Preview {
    TranscriptSearchPanel()
        .frame(width: 600, height: 500)
}
