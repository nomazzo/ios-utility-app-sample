import Foundation
import StoreKit

nonisolated struct PurchaseProductInfo: Equatable, Identifiable, Sendable {
    // StoreKitのProductをUIとテストで扱いやすい値型に変換する。
    var id: String
    var displayName: String
    var description: String
    var displayPrice: String
}

nonisolated enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    case pending
    case restored(Bool)
}

enum PurchaseError: Error, LocalizedError, Equatable {
    case productNotFound
    case productLoadFailed
    case purchaseFailed
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound, .productLoadFailed:
            L10n.text("pro.productLoadFailed.message", "購入情報を読み込めません。通信環境を確認してください。")
        case .purchaseFailed, .verificationFailed:
            L10n.text("pro.purchaseFailed", "購入を完了できませんでした。時間をおいてもう一度お試しください。")
        }
    }
}

nonisolated enum PurchaseClientResult: Equatable, Sendable {
    case success(Set<String>)
    case cancelled
    case pending
}

protocol PurchaseClient {
    // StoreKit依存を差し替えられるようにし、購入処理をユニットテスト可能にする。
    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo]
    func purchase(productID: String) async throws -> PurchaseClientResult
    func currentEntitlementProductIDs() async -> Set<String>
    func sync() async throws
}

struct StoreKitPurchaseClient: PurchaseClient {
    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo] {
        do {
            // App Store / StoreKit Configurationから表示名と価格を取得する。
            let products = try await Product.products(for: productIDs)
            return products
                .sorted { $0.id < $1.id }
                .map {
                    PurchaseProductInfo(
                        id: $0.id,
                        displayName: $0.displayName,
                        description: $0.description,
                        displayPrice: $0.displayPrice
                    )
                }
        } catch {
            throw PurchaseError.productLoadFailed
        }
    }

    func purchase(productID: String) async throws -> PurchaseClientResult {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        do {
            // 検証済みトランザクションだけを権利更新の対象にする。
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return .success(await currentEntitlementProductIDs())
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .pending
            }
        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.purchaseFailed
        }
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        var productIDs = Set<String>()

        // 失効済みの購入は除外し、現在有効な権利だけを見る。
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.revocationDate == nil else {
                continue
            }
            productIDs.insert(transaction.productID)
        }

        return productIDs
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            safe
        case .unverified:
            throw PurchaseError.verificationFailed
        }
    }
}

@MainActor
struct PurchaseManager {
    var client: PurchaseClient
    var entitlementStore: EntitlementStore
    var proProductID: String

    init(
        client: PurchaseClient = StoreKitPurchaseClient(),
        entitlementStore: EntitlementStore = EntitlementStore(),
        proProductID: String = CleanCueProductID.pro
    ) {
        self.client = client
        self.entitlementStore = entitlementStore
        self.proProductID = proProductID
    }

    func loadProducts() async throws -> [PurchaseProductInfo] {
        let products = try await client.products(for: [proProductID])
        guard !products.isEmpty else {
            throw PurchaseError.productNotFound
        }
        return products
    }

    @discardableResult
    func refreshEntitlements() async -> Bool {
        // 起動時や復元後に、購入状態をAppSettingsへ反映する。
        let ids = await client.currentEntitlementProductIDs()
        let isProUnlocked = ids.contains(proProductID)
        entitlementStore.updateProUnlocked(isProUnlocked)
        return isProUnlocked
    }

    func purchasePro() async throws -> PurchaseOutcome {
        let result = try await client.purchase(productID: proProductID)

        // キャンセルや承認待ちは失敗扱いにせず、UIで別メッセージを出せるように返す。
        switch result {
        case .success(let ids):
            let isProUnlocked = ids.contains(proProductID)
            entitlementStore.updateProUnlocked(isProUnlocked)
            return isProUnlocked ? .purchased : .pending
        case .cancelled:
            return .cancelled
        case .pending:
            return .pending
        }
    }

    func restorePurchases() async throws -> PurchaseOutcome {
        try await client.sync()
        let isProUnlocked = await refreshEntitlements()
        return .restored(isProUnlocked)
    }
}
