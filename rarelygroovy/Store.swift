import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction

public enum StoreError: Error {
    case failedVerification
}

class Store: ObservableObject {

    @Published private(set) var products: [Product]
    @Published private(set) var purchasedProducts: [Product] = []
    
    var updateListenerTask: Task<Void, Error>? = nil

    init() {
        print("running Store  init process")
        // Initialize empty products, then do a product request asynchronously to fill them in.
        products = []

        // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions()

        Task {
            // During store initialization, request products from the App Store.
            await requestProducts()
            
            // Deliver products that the customer purchases.
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    // Always finish a transaction.
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification.")
                }
            }
        }
    }

    @MainActor
    func requestProducts() async {
        do {
            // Request products from the App Store
            // FOR PRODUDCTION: make sure this hardcoded "rarelygroovyplus" value is moved to database for instant speed changes to product availability
            let productIds: [String] = ["rarelygroovyplus"]
            
            products = try await Product.products(for: productIds)
            print("Products available for purchase:")
            for product in products {
                print("🛒 Product ID: \(product.id)")
                print("📦 Title: \(product.displayName)")
                print("📝 Description: \(product.description)")
                print("💵 Price: \(product.displayPrice)")
            }
        } catch {
            print("Failed product request from the App Store server. \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        // Begin purchasing the `Product` the user selects.
        let tokenString = AuthManager.shared.user!.appAccountToken_apple
        let appAccountToken = UUID(uuidString: tokenString)!
        
        let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])

        switch result {
        case .success(let verification):
            // Check whether the transaction is verified. If it isn't,
            // this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            // The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            // Always finish a transaction.
            await transaction.finish()

            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) async throws -> Bool {
        // Determine whether the user purchases a given product.
        switch product.type {

        case .nonConsumable:
            return purchasedProducts.contains(product)

        default:
            return false
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedProducts: [Product] = []
        
        guard let user = AuthManager.shared.user,
              let localAppAccountToken = UUID(uuidString: user.appAccountToken_apple) else {
            print("🛑 No user or invalid/missing appAccountToken — skipping entitlement check")
            return
        }
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                guard transaction.productType == .nonConsumable else { continue }
                
                print("🧾 Transaction Debug Info:")
                print("• Product ID: \(transaction.productID)")
                print("• Purchase Date: \(transaction.purchaseDate)")
                print("• Original Purchase Date: \(transaction.originalPurchaseDate)")
                print("• Transaction ID: \(transaction.id)")
                print("• App Account Token: \(transaction.appAccountToken?.uuidString ?? "nil")")
                print("• Ownership Type: \(transaction.ownershipType.rawValue)")
                print("• Revocation Date: \(transaction.revocationDate?.description ?? "none")")
                print("• Is Upgraded: \(transaction.isUpgraded)")
                print("• Expires Date: \(transaction.expirationDate?.description ?? "n/a")")

                guard let tokenFromApple = transaction.appAccountToken else {
                    print("🕳️ No appAccountToken found in transaction for \(transaction.productID) — skipping")
                    continue
                }

                guard tokenFromApple == localAppAccountToken else {
                    print("⚠️ Token mismatch — expected \(localAppAccountToken), got \(tokenFromApple)")
                    continue
                }

                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchasedProducts.append(product)
                    if product.id == "rarelygroovyplus" && !AuthManager.shared.user!.plus {
                        print("🚀 User qualifies for Plus and hasn't been marked yet — syncing with backend...")
                        await sendPlusifyRequest()
                    } else {
                        print("✅ User is already Plus or product doesn’t match — no action needed.")
                    }
                }
            } catch {
                print("❌ Failed transaction verification: \(error)")
            }
        }

        if purchasedProducts.isEmpty {
            print("❌ No products purchased with matching appAccountToken")
        } else {
            for product in purchasedProducts {
                print("🛒 Purchased product ID: \(product.id)")
                print("📦 Title: \(product.displayName)")
                print("📝 Description: \(product.description)")
                print("💵 Price: \(product.displayPrice)")
            }
        }

        self.purchasedProducts = purchasedProducts
    }
    
    func sendPlusifyRequest() async {
        guard let user = AuthManager.shared.user else { return }
        
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/user/\(user.id)/plusify") else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["userId": user.id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Plusify success")
                DispatchQueue.main.async {
                    AuthManager.shared.user?.plus = true
                }
            } else {
                let msg = String(data: data, encoding: .utf8) ?? "(no message)"
                print("❌ Plusify failed: \(msg)")
            }
        } catch {
            print("❌ Network error while plusifying: \(error)")
        }
    }

    
}

