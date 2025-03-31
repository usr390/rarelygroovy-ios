struct Artist: Codable, Identifiable {
    let id: String       // mapping _id to id for Identifiable conformance
    let name: String
    let link: String
    let location: String
    let medium: String?
    let status: String?
    let links: [String: String]?
    let debut: Bool?       // optional now
    let albumDebut: Bool?  // optional
    let lastShow: Bool?    // optional
    let start: String
    let end: String?
    let genre: [String]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, link, location, medium, status, links, debut, albumDebut, lastShow, start, end, genre
    }
}
