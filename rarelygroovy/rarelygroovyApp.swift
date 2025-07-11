//
//  rarelygroovyApp.swift
//  rarelygroovy
//
//  Created by abs on 3/18/25.
//

import SwiftUI

@main
struct rarelygroovyApp: App {
    @StateObject var store: Store = Store()
    @StateObject private var plusStats = PlusStatsViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()  // replaces the default ContentView()
                .environmentObject(store)
                .environmentObject(plusStats)

        }
    }
}
