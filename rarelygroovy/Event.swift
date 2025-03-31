import Foundation

// Minimal model to parse your JSON.
// We'll treat `_id` and date fields as simple Strings for now.
struct Event: Identifiable, Decodable {
    let id: String
    
    let tags: [String]?
    let venue: Venue?
    let date: String?         // e.g. "2025-04-11T05:00:00.000Z"
    let doorTime: String?
    let dateTime: String?
    let cover: Int?
    let artists: [Artist]?
    let promoter: Promoter?
    let promoter2: Promoter?
    let flyer: String?
    let creationDateTime: String?
    let updates: [EventUpdate]?

    enum CodingKeys: String, CodingKey {
        case _id, tags, venue, date, doorTime, dateTime, cover, artists, promoter, promoter2, flyer, creationDateTime, updates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // parse _id { "$oid": "..." }
        if let idContainer = try? container.nestedContainer(keyedBy: OIDKeys.self, forKey: ._id) {
            let oid = try idContainer.decode(String.self, forKey: .oid)
            self.id = oid
        } else {
            self.id = UUID().uuidString
        }
        
        self.tags = try? container.decode([String].self, forKey: .tags)
        self.venue = try? container.decode(Venue.self, forKey: .venue)
        
        // decode date fields, checking both object-with-$date or a direct string
        self.date = decodeDateField(container, key: .date)
        self.doorTime = decodeDateField(container, key: .doorTime)
        self.dateTime = decodeDateField(container, key: .dateTime)
        self.creationDateTime = decodeDateField(container, key: .creationDateTime)
        
        self.cover = try? container.decode(Int.self, forKey: .cover)
        self.artists = try? container.decode([Artist].self, forKey: .artists)
        self.promoter = try? container.decode(Promoter.self, forKey: .promoter)
        self.promoter2 = try? container.decode(Promoter.self, forKey: .promoter2)
        self.flyer = try? container.decode(String.self, forKey: .flyer)
        self.updates = try? container.decode([EventUpdate].self, forKey: .updates)
    }
}

// handle _id { "$oid": "..." }
private enum OIDKeys: String, CodingKey {
    case oid = "$oid"
}

// helper for "date": { "$date": "..." }
private enum DateKeys: String, CodingKey {
    case date = "$date"
}

// tries to decode either:
//   1) { "$date": "someString" }
//   2) a direct string
// returns nil if all fail
private func decodeDateField(_ container: KeyedDecodingContainer<Event.CodingKeys>,
                             key: Event.CodingKeys) -> String?
{
    // 1) check if it's an object with $date
    if let nested = try? container.nestedContainer(keyedBy: DateKeys.self, forKey: key) {
        if let dateStr = try? nested.decode(String.self, forKey: .date) {
            return dateStr
        }
    }
    // 2) if that fails, see if it's just a direct string
    if let directString = try? container.decode(String.self, forKey: key) {
        return directString
    }
    // 3) otherwise, nil
    return nil
}
