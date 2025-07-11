//
//  VenueSearchViewModel.swift
//  rarelygroovy
//
//  Created by abs on 5/2/25.
//

import Foundation
class VenueSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var allVenues: [Venue] = []
    @Published var filteredVenues: [Venue] = []
    @Published var isLoading: Bool = true

    init(venues: [Venue]) {
        self.allVenues = venues
        self.filteredVenues = venues
        self.isLoading = false
    }

    func updateQuery(_ newQuery: String) {
        query = newQuery
        if query.isEmpty {
            filteredVenues = allVenues
        } else {
            filteredVenues = allVenues.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(query)
            }
        }
    }
}
