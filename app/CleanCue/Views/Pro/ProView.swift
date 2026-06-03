import SwiftUI

struct ProView: View {
    @Environment(\.dismiss) private var dismiss

    private let settingsStore: AppSettingsStore
    private let purchaseManager: PurchaseManager
    private let dismissAfterUnlockAcknowledgement: Bool

    @State private var settings: AppSettings
    @State private var product: PurchaseProductInfo?
    @State private var isLoadingProduct = false
    @State private var isPurchasing = false
    @State private var message: String?
    @State private var isShowingUnlockAlert = false

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        purchaseManager: PurchaseManager? = nil,
        dismissAfterUnlockAcknowledgement: Bool = false
    ) {
        self.settingsStore = settingsStore
        self.purchaseManager = purchaseManager ?? PurchaseManager(
            entitlementStore: EntitlementStore(settingsStore: settingsStore)
        )
        self.dismissAfterUnlockAcknowledgement = dismissAfterUnlockAcknowledgement
        _settings = State(initialValue: settingsStore.load())
    }

    var body: some View {
        List {
            Section(L10n.text("pro.section.status", "現在の状態")) {
                LabeledContent("Pro", value: settings.proUnlocked ? L10n.text("pro.status.active", "有効") : L10n.text("pro.status.notPurchased", "未購入"))
                if let product {
                    LabeledContent(L10n.text("pro.price", "価格"), value: product.displayPrice)
                } else if isLoadingProduct {
                    HStack {
                        ProgressView()
                        Text(L10n.text("pro.loadingProduct", "購入情報を読み込み中"))
                    }
                } else {
                    Text(L10n.text("pro.productLoadFailed.title", "購入情報を読み込めません"))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text(L10n.text("pro.demoNotice", "この公開用ビルドでは、XcodeのStoreKit Configurationを使ってIAPの購入・復元・Entitlement反映を確認できます。実際のApp Store商品IDは含めていません。"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.text("pro.section.benefits", "Proでできること")) {
                proBenefit(L10n.text("pro.benefit.unlimitedPlaces", "場所を無制限に追加"), systemImage: "house")
                proBenefit(L10n.text("pro.benefit.unlimitedTasks", "掃除を無制限に追加"), systemImage: "checklist")
                proBenefit(L10n.text("pro.benefit.multipleNotifications", "追加通知"), systemImage: "bell.badge")
                proBenefit(L10n.text("pro.benefit.futureFeatures", "今後のPro機能も利用可能"), systemImage: "sparkles")
            }

            Section {
                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text(settings.proUnlocked ? L10n.text("pro.purchased", "購入済み") : L10n.text("pro.purchase", "Proを購入"))
                    }
                }
                .disabled(settings.proUnlocked || product == nil || isPurchasing)
                .accessibilityLabel(L10n.text("pro.purchase", "Proを購入"))

                Button(L10n.text("pro.restore", "購入を復元")) {
                    Task {
                        await restore()
                    }
                }
                .disabled(isPurchasing)
                .accessibilityLabel(L10n.text("pro.restore", "購入を復元"))
            }

            if let message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.text("settings.section.links", "リンク")) {
                Link(L10n.text("settings.terms", "利用規約"), destination: URL(string: "https://example.com/home-routine-demo/terms")!)
                Link(L10n.text("settings.privacyPolicy", "プライバシーポリシー"), destination: URL(string: "https://example.com/home-routine-demo/privacy")!)
            }
        }
        .cleanCueScrollableBottomInset()
        .navigationTitle("Pro")
        .task {
            await refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanCueSettingsDidChange)) { _ in
            settings = settingsStore.load()
        }
        .alert(
            L10n.text("pro.unlock.title", "Proが有効になりました"),
            isPresented: $isShowingUnlockAlert
        ) {
            Button(L10n.text("common.close", "閉じる")) {
                if dismissAfterUnlockAcknowledgement {
                    dismiss()
                }
            }
        } message: {
            Text(L10n.text("pro.unlock.message", "場所と掃除の登録上限が解除されました。追加通知も使えるようになりました。"))
        }
    }

    private func proBenefit(
        _ title: String,
        systemImage: String,
        suffix: String? = nil
    ) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            if let suffix {
                Text(suffix)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func refresh() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        _ = await purchaseManager.refreshEntitlements()
        settings = settingsStore.load()

        do {
            product = try await purchaseManager.loadProducts().first
            message = nil
        } catch {
            product = nil
            message = L10n.text("pro.productLoadFailed.message", "購入情報を読み込めません。通信環境を確認してください。")
        }
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let outcome = try await purchaseManager.purchasePro()
            settings = settingsStore.load()

            switch outcome {
            case .purchased:
                showUnlockSuccess()
            case .cancelled:
                message = nil
            case .pending:
                message = L10n.text("pro.purchasePending", "購入は保留中です。完了後に自動で反映されます。")
            case .restored:
                showUnlockSuccess()
            }
        } catch {
            message = L10n.text("pro.purchaseFailed", "購入を完了できませんでした。時間をおいてもう一度お試しください。")
        }
    }

    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let outcome = try await purchaseManager.restorePurchases()
            settings = settingsStore.load()

            switch outcome {
            case .restored(true):
                showUnlockSuccess()
            case .restored(false):
                message = L10n.text("pro.restoreEmpty", "復元できる購入は見つかりませんでした。")
            case .purchased, .cancelled, .pending:
                message = nil
            }
        } catch {
            message = L10n.text("pro.restoreFailed", "購入を復元できませんでした。時間をおいてもう一度お試しください。")
        }
    }

    private func showUnlockSuccess() {
        message = L10n.text("pro.purchaseSuccess", "Proが有効になりました。")
        isShowingUnlockAlert = true
    }
}

#Preview {
    NavigationStack {
        ProView()
    }
}
