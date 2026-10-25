//
//  BroadcastProgressCard.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

/// How far the server is in sending a broadcast, refreshed by polling.
struct BroadcastProgressCard: View {

    let broadcast: PushBroadcastStatus
    let isCancelling: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(broadcast.processed.formattedString)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: Double(broadcast.processed)))
                    Text("de \(broadcast.total.formattedString)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(stateColor)
                }

                ProgressView(value: Double(broadcast.processed), total: Double(max(broadcast.total, 1)))
                    .progressViewStyle(.linear)
                    .tint(stateColor)
                    .controlSize(.large)
            }
            .animation(.smooth, value: broadcast.processed)

            HStack(spacing: 12) {
                stat("Enviados", value: broadcast.sent, symbol: "checkmark.circle.fill", color: .green)
                stat("Falharam", value: broadcast.failed, symbol: "xmark.circle.fill", color: .red)
                stat("Tokens removidos", value: broadcast.removedTokens, symbol: "trash.circle.fill", color: .orange)
            }

            TimelineView(.periodic(from: broadcast.startedAt, by: 1)) { context in
                timing(now: context.date)
            }

            if !broadcast.recentErrors.isEmpty {
                DisclosureGroup("Erros recentes (\(broadcast.recentErrors.count))") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(broadcast.recentErrors.enumerated()), id: \.offset) { _, error in
                            Text(error)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.callout)
            }
        }
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(stateColor.opacity(0.35), lineWidth: 1)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: stateSymbol)
                .font(.title2)
                .foregroundStyle(stateColor)
                .symbolEffect(.pulse, isActive: broadcast.state == .sending)

            VStack(alignment: .leading, spacing: 2) {
                Text(stateTitle)
                    .font(.headline)
                Text(broadcast.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if broadcast.state == .sending {
                Button(role: .destructive, action: onCancel) {
                    if isCancelling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Cancelar envio", systemImage: "stop.fill")
                    }
                }
                .disabled(isCancelling)
                .help("O servidor para antes do próximo aparelho. Quem já recebeu, recebeu.")
            }
        }
    }

    private func stat(_ label: String, value: Int, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(color)
            Text(value.formattedString)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func timing(now: Date) -> some View {
        let end = broadcast.finishedAt ?? now
        let elapsed = max(end.timeIntervalSince(broadcast.startedAt), 0)
        let rate = elapsed > 0 ? Double(broadcast.processed) / elapsed : 0
        let remaining = broadcast.total - broadcast.processed

        return HStack(spacing: 20) {
            timingItem("Tempo", value: Self.duration(elapsed))
            timingItem("Velocidade", value: rate > 0 ? "\(rate.formatted(.number.precision(.fractionLength(1)))) /s" : "—")
            if broadcast.state == .sending {
                timingItem("Faltam", value: rate > 0 ? "~" + Self.duration(Double(remaining) / rate) : "—")
            }
        }
        .font(.callout)
    }

    private func timingItem(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
        }
    }

    // MARK: - State

    private var fraction: Double {
        broadcast.total == 0 ? 1 : Double(broadcast.processed) / Double(broadcast.total)
    }

    private var stateTitle: String {
        switch broadcast.state {
        case .sending: return "Enviando…"
        case .finished: return "Envio concluído"
        case .cancelled: return "Envio cancelado"
        }
    }

    private var stateSymbol: String {
        switch broadcast.state {
        case .sending: return "paperplane.fill"
        case .finished: return "checkmark.seal.fill"
        case .cancelled: return "stop.circle.fill"
        }
    }

    private var stateColor: Color {
        switch broadcast.state {
        case .sending: return .accentColor
        case .finished: return .green
        case .cancelled: return .orange
        }
    }

    private static func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded()).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow, maximumUnitCount: 2))
    }
}

#Preview {
    BroadcastProgressCard(
        broadcast: PushBroadcastStatus(
            id: UUID(),
            title: "Amanhã tem apuração do 2º turno",
            body: "Depois de votar, abra o app.",
            state: .sending,
            total: 24_580,
            processed: 9_312,
            sent: 9_201,
            failed: 12,
            removedTokens: 99,
            startedAt: .now.addingTimeInterval(-480),
            finishedAt: nil,
            recentErrors: ["ABC-123: timeout"]
        ),
        isCancelling: false,
        onCancel: {}
    )
    .frame(width: 520)
    .padding()
}
