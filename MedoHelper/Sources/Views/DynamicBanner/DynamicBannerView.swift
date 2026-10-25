//
//  DynamicBannerView.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

struct DynamicBannerView: View {

    @StateObject private var viewModel = ViewModel()
    @State private var isPreviewExpanded: Bool = true
    @State private var previewColorScheme: ColorScheme = .light

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 28) {
                    statusRow
                    headerSection
                    paragraphsSection
                    buttonsSection
                    publishSection
                }
                .frame(minWidth: 400, maxWidth: 580)
                .disabled(viewModel.isLoading || !viewModel.hasLoaded)

                VStack(spacing: 16) {
                    Picker("Aparência", selection: $previewColorScheme) {
                        Text("Claro").tag(ColorScheme.light)
                        Text("Escuro").tag(ColorScheme.dark)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)

                    BannerPhonePreview(
                        banner: viewModel.draft.banner,
                        isExpanded: $isPreviewExpanded,
                        colorScheme: previewColorScheme
                    )

                    Text("Toque no banner para abrir e fechar. Os botões de copiar mostram o aviso.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .navigationTitle("Banner Dinâmico")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.onReloadSelected() }
                } label: {
                    Label("Recarregar", systemImage: "arrow.clockwise")
                }
                .help("Recarregar do servidor, descartando o que não foi publicado")
                .disabled(viewModel.isLoading)
            }
        }
        .confirmationDialog(
            "Publicar o banner para todo mundo?",
            isPresented: $viewModel.showPublishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Publicar") {
                Task { await viewModel.onPublishConfirmed() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Substitui o banner atual. O app mostra a nova versão na próxima vez que abrir, para quem pode ver pedidos de doação.")
        }
        .confirmationDialog(
            "Tirar o banner do app?",
            isPresented: $viewModel.showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Tirar do app", role: .destructive) {
                Task { await viewModel.onRemoveConfirmed() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Some na próxima vez que o app buscar o banner. O texto continua aqui no editor para publicar de novo quando quiser.")
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .task {
            await viewModel.onViewAppear()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var statusRow: some View {
        if viewModel.hasLoaded {
            HStack(spacing: 8) {
                if viewModel.published == nil {
                    // Also what's left after removing: the draft stays for putting it back.
                    Label("Nenhum banner no app agora", systemImage: "eye.slash.circle.fill")
                        .foregroundStyle(.secondary)
                } else if viewModel.hasUnpublishedChanges {
                    Label("Alterações não publicadas", systemImage: "pencil.circle.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Descartar alterações", role: .destructive) {
                        viewModel.onDiscardChangesSelected()
                    }
                } else {
                    Label("Igual ao que está no servidor", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.callout.weight(.medium))
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Cabeçalho", caption: "Aparece sempre, com o banner fechado.")

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: viewModel.symbolIsUnknownHere || viewModel.draft.symbol.isEmpty ? "questionmark.square.dashed" : viewModel.draft.symbol)
                    .font(.title2)
                    .foregroundStyle(.pink)
                    .frame(width: 32)

                TextField("Símbolo (SF Symbol)", text: $viewModel.draft.symbol)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
            }
            if viewModel.symbolIsUnknownHere {
                Label("Esse símbolo não existe neste aparelho. Pode existir na versão do iOS de quem usa o app, mas confira no app SF Symbols.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            TextField("Título", text: $viewModel.draft.title, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .lineLimit(1...3)
        }
    }

    private var paragraphsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Texto", caption: "Aparece ao abrir o banner. Aceita Markdown: **negrito**, *itálico* e [links](https://…).")

            ForEach($viewModel.draft.paragraphs) { $paragraph in
                HStack(alignment: .top, spacing: 8) {
                    TextField("Parágrafo", text: $paragraph.text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...10)

                    rowControls(for: paragraph.id, in: $viewModel.draft.paragraphs)
                }
            }

            Button {
                viewModel.onAddParagraph()
            } label: {
                Label("Adicionar parágrafo", systemImage: "plus")
            }
        }
    }

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Botões", caption: "Ficam embaixo do texto, na ordem abaixo.")

            ForEach(Array($viewModel.draft.buttons.enumerated()), id: \.element.id) { index, $button in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Botão \(index + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        rowControls(for: button.id, in: $viewModel.draft.buttons)
                    }

                    TextField("Título do botão", text: $button.title)
                        .textFieldStyle(.roundedBorder)

                    Picker("Ação", selection: $button.type) {
                        ForEach(DynamicBannerButtonType.allCases) { type in
                            Text(type.name).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(button.type == .copyText ? "Texto a copiar (ex.: chave Pix)" : "Link (https://…)", text: $button.data)
                        .textFieldStyle(.roundedBorder)
                        .font(.body.monospaced())

                    if button.type == .copyText {
                        TextField("Aviso depois de copiar (opcional)", text: $button.additionalData)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                viewModel.onAddButton()
            } label: {
                Label("Adicionar botão", systemImage: "plus")
            }
        }
    }

    private var publishSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            let problems = viewModel.problems
            if !problems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(problems, id: \.self) { problem in
                        Label(problem, systemImage: "xmark.octagon.fill")
                    }
                }
                .font(.callout)
                .foregroundStyle(.red)
            }

            Button {
                viewModel.onPublishSelected()
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isPublishing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "megaphone.fill")
                    }
                    Text(viewModel.isPublishing ? "Publicando…" : "Publicar banner")
                }
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .controlSize(.extraLarge)
            .disabled(!viewModel.canPublish)
            .keyboardShortcut(.return, modifiers: .command)

            if viewModel.published != nil {
                Button(role: .destructive) {
                    viewModel.onRemoveSelected()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isRemoving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "eye.slash")
                        }
                        Text(viewModel.isRemoving ? "Removendo…" : "Tirar banner do app")
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .disabled(!viewModel.canRemove)
            }

            DisclosureGroup("JSON que vai para o servidor") {
                Text(viewModel.publishedJSON)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 6)
            }
            .font(.callout)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    /// Move up, move down and remove for one row of a list in the draft.
    private func rowControls<Row: Identifiable>(for id: Row.ID, in rows: Binding<[Row]>) -> some View {
        let index = rows.wrappedValue.firstIndex { $0.id == id }
        return HStack(spacing: 2) {
            Button {
                guard let index else { return }
                withAnimation(.snappy) { rows.wrappedValue.swapAt(index, index - 1) }
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(index == nil || index == 0)
            .help("Subir")

            Button {
                guard let index else { return }
                withAnimation(.snappy) { rows.wrappedValue.swapAt(index, index + 1) }
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(index == nil || index == rows.wrappedValue.count - 1)
            .help("Descer")

            Button(role: .destructive) {
                guard let index else { return }
                withAnimation(.snappy) { _ = rows.wrappedValue.remove(at: index) }
            } label: {
                Image(systemName: "trash")
            }
            .disabled(index == nil)
            .help("Remover")
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    DynamicBannerView()
        .frame(width: 1100, height: 900)
}
