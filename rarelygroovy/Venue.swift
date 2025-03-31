import Foundation

struct Venue: Identifiable, Decodable {
    let id: String
    
    let name: String?
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, address, city, state, country, link
    }
    
    // We decode `_id` as an object with "$oid"
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // parse _id object
        if let idContainer = try? container.nestedContainer(keyedBy: OIDKeys.self, forKey: ._id) {
            let oid = try idContainer.decode(String.self, forKey: .oid)
            self.id = oid
        } else {
            self.id = UUID().uuidString
        }
        
        self.name = try? container.decode(String.self, forKey: .name)
        self.address = try? container.decode(String.self, forKey: .address)
        self.city = try? container.decode(String.self, forKey: .city)
        self.state = try? container.decode(String.self, forKey: .state)
        self.country = try? container.decode(String.self, forKey: .country)
        self.link = try? container.decode(String.self, forKey: .link)
    }
}

// helper for the "_id" { "$oid": ... }
private enum OIDKeys: String, CodingKey {
    case oid = "$oid"
}
