//
//  DonorsView.swift
//  MedoHelper
//
//  Created by Claude on 03/07/26.
//

import SwiftUI

struct DonorsView: View {

    @StateObject private var viewModel = ViewModel()
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            addBar
            Divider()
            content
        }
        .navigationTitle("Doadores")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Ordenar", selection: $viewModel.sortOrder) {
                    ForEach(DonorsView.SortOrder.allCases) { order in
                        Text(order.label).tag(order)
                    }
                }
                .help("Ordenar")

                Button {
                    Task { await viewModel.onReloadSelected() }
                } label: {
                    Label("Recarregar", systemImage: "arrow.clockwise")
                }
                .help("Recarregar do servidor")

                Button {
                    Task { await viewModel.onPublish() }
                } label: {
                    if viewModel.isPublishing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Enviar ao Servidor", systemImage: "square.and.arrow.up")
                    }
                }
                .disabled(viewModel.isPublishing || viewModel.donors.isEmpty)
                .help("Enviar a lista completa ao servidor (set-donor-names)")
            }
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

    // MARK: - Add Bar

    private var addBar: some View {
        HStack(spacing: 12) {
            TextField("Nome do doador", text: $viewModel.draftName)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 160)
                .focused($addFieldFocused)
                .onSubmit {
                    viewModel.onAddDonor()
                    addFieldFocused = true
                }

            Picker("", selection: $viewModel.draftRecurrence) {
                ForEach(DonorRecurrence.allCases) { tier in
                    Text(tier.label).tag(tier)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .help("Tipo de recorrência")

            Toggle("Já doou antes", isOn: $viewModel.draftHasDonatedBefore)
                .toggleStyle(.checkbox)

            Button {
                viewModel.onAddDonor()
                addFieldFocused = true
            } label: {
                Label("Adicionar", systemImage: "plus")
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(viewModel.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando Doadores...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let donors):
            if donors.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum Doador", systemImage: "heart")
                } description: {
                    Text("Adicione doadores usando o campo acima. Quando terminar, use \"Enviar ao Servidor\".")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                donorsTable(donors)
            }

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Tentar Novamente") {
                    Task { await viewModel.onReloadSelected() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func donorsTable(_ donors: [Donor]) -> some View {
        VStack(spacing: 0) {
            Table(donors, selection: $viewModel.selection) {
                TableColumn("Nome", value: \.name)

                TableColumn("Recorrência") { donor in
                    Picker("", selection: recurrenceBinding(for: donor)) {
                        ForEach(DonorRecurrence.allCases) { tier in
                            Text(tier.label).tag(tier)
                        }
                    }
                    .labelsHidden()
                }
                .width(min: 150, ideal: 170)

                TableColumn("Já doou antes") { donor in
                    Toggle("", isOn: hasDonatedBinding(for: donor))
                        .labelsHidden()
                }
                .width(min: 90, ideal: 100, max: 120)

                TableColumn("Adicionado") { donor in
                    Text(donor.createdAt, format: .dateTime.day().month().year(.twoDigits))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .width(min: 90, ideal: 110, max: 130)
            }
            .contextMenu(forSelectionType: Donor.ID.self) { ids in
                if !ids.isEmpty {
                    Button("Excluir", role: .destructive) {
                        viewModel.selection = ids
                        viewModel.onRemoveSelected()
                    }
                }
            }
            .onDeleteCommand {
                viewModel.onRemoveSelected()
            }

            footer(count: donors.count)
        }
    }

    private func footer(count: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(count) doador(es)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.hasUnsentChanges {
                Label("Alterações não enviadas", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Label("Sincronizado", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Inline Bindings

    private func hasDonatedBinding(for donor: Donor) -> Binding<Bool> {
        Binding(
            get: { donor.hasDonatedBefore },
            set: { viewModel.setHasDonatedBefore($0, for: donor.id) }
        )
    }

    private func recurrenceBinding(for donor: Donor) -> Binding<DonorRecurrence> {
        Binding(
            get: { donor.recurrence },
            set: { viewModel.setRecurrence($0, for: donor.id) }
        )
    }
}

#Preview {
    DonorsView()
        .frame(width: 900, height: 600)
}
