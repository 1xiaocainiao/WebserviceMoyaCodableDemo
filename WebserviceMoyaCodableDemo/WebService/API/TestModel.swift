

import UIKit


class TestModel: LXBaseModel {
    var user_info: UserInfo?
    var site: SiteModel?
}

class UserInfo: LXBaseModel {
    var username: String?
    var truename: String?
    var city: String?
    var age: Int?
    var sex: String?
    var school: String?
    
    enum CodingKeys: String, CodingKey {
        case age = "age"
        case city = "city"
        case school = "school"
        case sex = "sex"
        case truename = "truename"
        case username = "username"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        school = try container.decodeIfPresent(String.self, forKey: .school)
        sex = try container.decodeIfPresent(String.self, forKey: .sex)
        truename = try container.decodeIfPresent(String.self, forKey: .truename)
        username = try container.decodeIfPresent(String.self, forKey: .username)
    }
}

class SiteModel: LXBaseModel {
    var name: String = ""
    var url: String = ""
}
