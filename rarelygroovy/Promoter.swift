import Foundation

struct Promoter: Identifiable, Codable {
    let id: String
    let name: String?
    let link: String?

    enum CodingKeys: String, CodingKey {
        case _id, name, link
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
        self.link = try? container.decode(String.self, forKey: .link)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(["$oid": id], forKey: ._id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(link, forKey: .link)
    }
}
