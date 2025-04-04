//
//  EventsViewModel.swift
//  rarelygroovy
//
//  Created by abs on 3/24/25.
//

import Foundation
import SwiftUI
import Combine

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    private var firstLoad = true
    private var logoutObserver: Any?

    init() {
        logoutObserver = NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogout"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchEvents()
        }
        // refresh events on login
        NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogin"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchEvents()
        }
    }
    
    deinit {
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
//    func fetchEvents(userInitiated: Bool = false) {
//        if firstLoad || !userInitiated {
//            DispatchQueue.main.async { self.isLoading = true }
//        }
//        
//        // assuming events API takes username as query param when logged in
//        let username = AuthManager.shared.user?.username
//        var urlComponents = URLComponents(string: "https://enm-project-production.up.railway.app/api/enmEvents")
//        if let username = username {
//            urlComponents?.queryItems = [ URLQueryItem(name: "username", value: username) ]
//        }
//        guard let url = urlComponents?.url else {
//            print("Invalid events URL")
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            DispatchQueue.main.async { self.isLoading = false }
//            
//            if let error = error {
//                print("Error fetching events: \(error)")
//                return
//            }
//            guard let data = data else {
//                print("No event data received")
//                return
//            }
//            do {
//                let decoded = try JSONDecoder().decode([Event].self, from: data)
//                DispatchQueue.main.async {
//                    self.events = decoded
//                    self.firstLoad = false
//                }
//            } catch {
//                print("Error decoding events: \(error)")
//            }
//        }.resume()
//    }
    func fetchEvents(userInitiated: Bool = false) {
    }

}
