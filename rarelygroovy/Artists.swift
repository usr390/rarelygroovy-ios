import Foundation

struct Artist: Identifiable, Codable {
    let id: String
    let name: String
    let link: String
    let location: String
    let medium: String?
    let status: String?
    let links: [String: String]?
    let debut: Bool?
    let albumDebut: Bool?
    let lastShow: Bool?
    let start: String
    let end: String?
    let genre: [String]

    enum CodingKeys: String, CodingKey {
        case _id, name, link, location, medium, status, links, debut, albumDebut, lastShow, start, end, genre
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

        self.name = try container.decode(String.self, forKey: .name)
        self.link = try container.decode(String.self, forKey: .link)
        self.location = try container.decode(String.self, forKey: .location)
        self.medium = try? container.decode(String.self, forKey: .medium)
        self.status = try? container.decode(String.self, forKey: .status)
        self.links = try? container.decode([String: String].self, forKey: .links)
        self.debut = try? container.decode(Bool.self, forKey: .debut)
        self.albumDebut = try? container.decode(Bool.self, forKey: .albumDebut)
        self.lastShow = try? container.decode(Bool.self, forKey: .lastShow)
        self.start = try container.decode(String.self, forKey: .start)
        self.end = try? container.decode(String.self, forKey: .end)
        self.genre = try container.decode([String].self, forKey: .genre)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(["$oid": id], forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encode(link, forKey: .link)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(medium, forKey: .medium)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(links, forKey: .links)
        try container.encodeIfPresent(debut, forKey: .debut)
        try container.encodeIfPresent(albumDebut, forKey: .albumDebut)
        try container.encodeIfPresent(lastShow, forKey: .lastShow)
        try container.encode(start, forKey: .start)
        try container.encodeIfPresent(end, forKey: .end)
        try container.encode(genre, forKey: .genre)
    }
}
