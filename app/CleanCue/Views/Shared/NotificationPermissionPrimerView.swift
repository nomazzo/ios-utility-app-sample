import SwiftUI

struct NotificationPermissionPrimerView: View {
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("notification.primer.title", "掃除の予定を忘れないように通知します"))
                        .font(.title3.bold())
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text("notification.primer.body", "指定した時刻に、今日の掃除・場所・所要時間を端末内のローカル通知でお知らせします。ログインやサーバー送信はありません。"))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NotificationPreviewCard()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 12) {
                    primerPoint(
                        icon: "checklist",
                        text: L10n.text("notification.primer.pointConcrete", "通知には具体的な掃除が表示されます。")
                    )
                    primerPoint(
                        icon: "hand.tap",
                        text: L10n.text("notification.primer.pointActions", "通知から完了・明日・今週スキップを選べます。")
                    )
                    primerPoint(
                        icon: "gearshape",
                        text: L10n.text("notification.primer.pointControl", "通知はいつでも設定からオフにできます。")
                    )
                }

                Spacer()

                VStack(spacing: 10) {
                    Button(action: primaryAction) {
                        Text(L10n.text("notification.primer.allow", "通知を許可する"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: secondaryAction) {
                        Text(L10n.text("common.notNow", "あとで"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .navigationTitle(L10n.text("notification.primer.navigationTitle", "通知"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func primerPoint(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
        }
    }
}

private struct NotificationPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(CleanCueTheme.primaryBlue)
                    .frame(width: 34, height: 34)
                    .background(CleanCueTheme.softBlue, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("HomeRoutine Demo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("notification.primer.previewTitle", "浴室: 排水口掃除"))
                        .font(.headline)
                    Text(L10n.text("notification.primer.previewBody", "そろそろです・8分"))
                        .font(.subheadline)
                        .foregroundStyle(CleanCueTheme.secondaryText)
                }
            }

            HStack(spacing: 8) {
                previewAction(L10n.text("action.complete", "完了"), tint: CleanCueTheme.cleanMint)
                previewAction(L10n.text("action.tomorrow", "明日"), tint: CleanCueTheme.primaryBlue)
                previewAction(L10n.text("action.skipThisWeek", "今週スキップ"), tint: CleanCueTheme.secondaryText)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CleanCueTheme.separator.opacity(0.8), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    private func previewAction(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(Color(.systemGray6), in: Capsule())
    }
}

#Preview {
    NotificationPermissionPrimerView(
        primaryAction: {},
        secondaryAction: {}
    )
}
