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
    let rgvDebut: Bool?
    let lastShow: Bool?
    let start: String
    let end: String?
    let genre: [String]
    let start2: String?
    let end2: String?
    let status2: String?


    enum CodingKeys: String, CodingKey {
        case _id, name, link, location, medium, status, links, debut, albumDebut, rgvDebut, lastShow, start, end, genre, start2, end2, status2
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
        self.rgvDebut = try? container.decode(Bool.self, forKey: .rgvDebut)
        self.lastShow = try? container.decode(Bool.self, forKey: .lastShow)
        self.start = try container.decode(String.self, forKey: .start)
        self.end = try? container.decode(String.self, forKey: .end)
        self.genre = try container.decode([String].self, forKey: .genre)
        self.start2 = try? container.decode(String.self, forKey: .start2)
        self.end2 = try? container.decode(String.self, forKey: .end2)
        self.status2 = try? container.decode(String.self, forKey: .status2)

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
        try container.encodeIfPresent(rgvDebut, forKey: .rgvDebut)
        try container.encodeIfPresent(lastShow, forKey: .lastShow)
        try container.encode(start, forKey: .start)
        try container.encodeIfPresent(end, forKey: .end)
        try container.encode(genre, forKey: .genre)
        try container.encodeIfPresent(start2, forKey: .start2)
        try container.encodeIfPresent(end2, forKey: .end2)
        try container.encodeIfPresent(status2, forKey: .status2)

    }
}
