//
//  EventUpdate.swift
//  rarelygroovy
//
//  Created by abs on 3/24/25.
//

import Foundation

struct EventUpdate: Decodable {
    let date: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case date, message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // parse date from { "$date": "2025-03-21T21:51:51.186Z" }
        if let dateObj = try? container.nestedContainer(keyedBy: DateKeys.self, forKey: .date) {
            self.date = try? dateObj.decode(String.self, forKey: .date)
        } else {
            self.date = nil
        }
        
        self.message = try? container.decode(String.self, forKey: .message)
    }
}

private enum DateKeys: String, CodingKey {
    case date = "$date"
}
