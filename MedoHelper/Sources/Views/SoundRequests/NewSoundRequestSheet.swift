//
//  NewSoundRequestSheet.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import SwiftUI

struct NewSoundRequestSheet: View {

    let onConfirm: (_ title: String, _ requesterName: String, _ emailReceivedAt: Date) -> Void
    let onCancel: () -> Void

    @State private var title: String = ""
    @State private var requesterName: String = ""
    @State private var emailReceivedAt: Date = .now
    @State private var includeTime: Bool = true

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, requester
    }

    private var isConfirmDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            requesterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Novo Pedido de Som")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Título do Som", text: $title)
                    .focused($focusedField, equals: .title)
                    .onSubmit { focusedField = .requester }

                TextField("Nome do Solicitante", text: $requesterName)
                    .focused($focusedField, equals: .requester)
                    .onSubmit { confirmIfPossible() }

                DatePicker(
                    "E-mail Recebido em",
                    selection: $emailReceivedAt,
                    in: ...Date.now,
                    displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date]
                )

                Toggle("Incluir horário", isOn: $includeTime)
                    .toggleStyle(.checkbox)
            }

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Adicionar") {
                    confirmIfPossible()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isConfirmDisabled)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            focusedField = .title
        }
    }

    private func confirmIfPossible() {
        guard !isConfirmDisabled else { return }
        let resolvedDate = includeTime
            ? emailReceivedAt
            : Calendar.current.startOfDay(for: emailReceivedAt)
        onConfirm(title, requesterName, resolvedDate)
    }
}

#Preview {
    NewSoundRequestSheet(
        onConfirm: { _, _, _ in },
        onCancel: {}
    )
}
