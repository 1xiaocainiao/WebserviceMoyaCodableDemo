

import Foundation

/// 后端返回的code
public struct ResponseCode {
    static let successResponseStatusCode = 100000
}

public enum LXError: Error {
    // json 解析失败
    case jsonSerializationFailed(message: String)
    // json转字典失败
    case jsonToDictionaryFailed(message: String)
    // 服务器返回错误
    case serverResponseError(message: String?, code: String)
    // 自定义错误
    case exception(message: String)
    // 服务器返回数据初始化失败
    case serverDataFormatError
    // statucode
    case missStatuCode
    //
    case missDataContent
    //
    case dataContentTransformToModelFailed
    //
    case dataContentTransfromToModelArrayFailed
    
    case networkConnectFailed
}

class LXErrorHandle {
    static func checkErrorAndShowInfo(_ error: Error?) {
        guard let error = error else {
            return
        }
        
        if let error = error as? LXError {
//            SVProgressHUD.showError(withStatus: error.message)
        } else {
//            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
}

extension LXError {
    var message: String? {
        switch self {
        case let .serverResponseError(message: msg, code: _):
            return msg
        default:
            return nil
        }
    }
    
    var code: String {
        switch self {
        case let .serverResponseError(message: _, code: code):
            return code
        default:
            return "-1"
        }
    }
}
