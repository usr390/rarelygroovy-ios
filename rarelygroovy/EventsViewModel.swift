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
    @Published var extraEvents: Int? = nil
    @Published var pastEvents: [Event] = []
    @Published var furthestMonth: String? = nil
    
    private var firstLoadPast = true
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
        fetchFreeExtraCount()
    }
    
    deinit {
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    func fetchEvents(userInitiated: Bool = false) {
        
        if firstLoad || !userInitiated {
            DispatchQueue.main.async { self.isLoading = true }
        }
        
        // assuming events API takes username as query param when logged in
        let username = AuthManager.shared.user?.username
        var urlComponents = URLComponents(string: "https://enm-project-production.up.railway.app/api/enmEventsTrans")
        if let username = username {
            urlComponents?.queryItems = [ URLQueryItem(name: "username", value: username) ]
        }
        guard let url = urlComponents?.url else {
            print("Invalid events URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                print("Error fetching events: \(error)")
                return
            }
            guard let data = data else {
                print("No event data received")
                return
            }
            do {
                let decoded = try JSONDecoder().decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.events = decoded
                    self.firstLoad = false
                }
            } catch {
                print("Error decoding events: \(error)")
            }
        }.resume()
    }
    
    func fetchPastEvents(userInitiated: Bool = false) {
        // only fetch once, unless this was a manual “userInitiated” refresh
        guard firstLoadPast || userInitiated else { return }
        
        // show loader on first load (or on manual refresh)
        DispatchQueue.main.async { self.isLoading = true }
        
        let username = AuthManager.shared.user?.username
        var components = URLComponents(string: "https://enm-project-production.up.railway.app/api/enmEvents/pastTrans")
        if let u = username {
            components?.queryItems = [ .init(name: "username", value: u) ]
        }
        guard let url = components?.url else {
            print("Invalid past-events URL"); return
        }
        
        URLSession.shared.dataTask(with: url) { data, resp, error in
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                print("Error fetching past events:", error)
                return
            }
            guard let http = resp as? HTTPURLResponse, let data = data else {
                print("No response/data"); return
            }
            guard http.statusCode == 200 else {
                let text = String(data: data, encoding: .utf8) ?? "<no body>"
                print("HTTP \(http.statusCode):\n\(text)")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.pastEvents = decoded
                    self.firstLoadPast = false  // mark that we’ve loaded once
                }
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "<binary>"
                print("Error decoding past events:", error, "\nraw:\n", raw)
            }
        }.resume()
    }
    
    func fetchFreeExtraCount() {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/enmEvents/number-of-events-passed-free-limit") else {
            print("❌ Invalid URL"); return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Error fetching count:", error); return
            }
            guard let data = data else {
                print("❌ No data"); return
            }
            do {
                let resp = try JSONDecoder().decode(FreeExtraCountResponse.self, from: data)
                DispatchQueue.main.async {
                    self.extraEvents   = resp.extraEvents
                    self.furthestMonth = resp.furthestMonth
                }
            } catch {
                print("❌ Decoding failed:", error)
            }
        }.resume()
    }
}

