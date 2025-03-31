import Foundation

struct Promoter: Identifiable, Decodable {
    let id: String
    let name: String?
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, link
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
        
        self.name = try? container.decode(String.self, forKey: .name)
        self.link = try? container.decode(String.self, forKey: .link)
    }
}

private enum OIDKeys: String, CodingKey {
    case oid = "$oid"
}
