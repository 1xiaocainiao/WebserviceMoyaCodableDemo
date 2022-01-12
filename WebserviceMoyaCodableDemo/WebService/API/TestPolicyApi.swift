

import Foundation
import Moya

enum TestRequestType {
    case baidu
    case upload([LXUploadFileInfo],[String: Any]? = nil)
}

extension TestRequestType: LXMoyaTargetType {
    var parameters: [String : Any] {
        switch self {
        case .baidu:
            return ["username": "postman", "password": "123465"]
        case let .upload(_, params):
            return params ?? [:]
        }
    }
    
    var uploadFiles: [LXUploadFileInfo]? {
        switch self {
        case let .upload(files, _):
            return files
        default:
            return nil
        }
    }
    
    
    var method: Moya.Method {
        return .post
    }
}
