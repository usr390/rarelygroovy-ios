import Foundation

struct Venue: Identifiable, Codable {
    let id: String
    let name: String?
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let link: String?
    let debut: Bool?

    enum CodingKeys: String, CodingKey {
        case _id, name, address, city, state, country, link, debut
    }

    private enum OIDKeys: String, CodingKey {
        case oid = "$oid"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let oidContainer = try? container.nestedContainer(keyedBy: OIDKeys.self, forKey: ._id),
           let oid = try? oidContainer.decode(String.self, forKey: .oid) {
            self.id = oid
        } else if let idString = try? container.decode(String.self, forKey: ._id) {
            self.id = idString
        } else {
            throw DecodingError.dataCorruptedError(forKey: ._id, in: container, debugDescription: "Invalid or missing _id")
        }

        self.name = try? container.decode(String.self, forKey: .name)
        self.address = try? container.decode(String.self, forKey: .address)
        self.city = try? container.decode(String.self, forKey: .city)
        self.state = try? container.decode(String.self, forKey: .state)
        self.country = try? container.decode(String.self, forKey: .country)
        self.link = try? container.decode(String.self, forKey: .link)
        self.debut = try? container.decode(Bool.self, forKey: .debut)

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(["$oid": id], forKey: ._id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encodeIfPresent(debut, forKey: .debut)
    }
}
