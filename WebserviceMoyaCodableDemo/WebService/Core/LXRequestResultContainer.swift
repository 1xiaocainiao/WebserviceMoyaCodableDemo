

import Foundation



public class LXRequestResultContainer<T> where T: Codable {
    public var success: Bool = false
    public var value: T?
    public var code: String = ""
    
    public var message: String = ""
    
    public var originObject: Any? {
        didSet {
            decodeJSONObject()
        }
    }
    
    public var error: LXError?
    
    public var isValid: Bool = true
    
    public init(jsonObject: Any) {
        self.originObject = jsonObject
        self.decodeJSONObject()
    }
    
    private func setupDefaultErrorStatus() {
        success = false
        value = nil
        code = ""
        message = "数据解析出错了"
        isValid = false
    }
    
    
    private func decodeJSONObject() {
        guard let jsonObject = self.originObject as? [String: Any] else {
            setupDefaultErrorStatus()
            self.error = LXError.serverDataFormatError
            return
        }
        
        guard let statuCode = jsonObject[ServerKey.code.rawValue] as? Int else {
            setupDefaultErrorStatus()
            self.error = LXError.serverDataFormatError
            return
        }
        
        self.success = jsonObject[ServerKey.success.rawValue] as? Bool ?? false
        self.code = "\(statuCode)"
        self.message = jsonObject[ServerKey.message.rawValue] as? String ?? ""
        
        if statuCode == ResponseCode.successResponseStatusCode {
            guard let jsonValue = jsonObject[ServerKey.value.rawValue] else {
                setupDefaultErrorStatus()
                self.error = LXError.missDataContent
                return
            }
            
            // 如果data就是结果，直接赋值
            if let dataObject = jsonValue as? T {
                value = dataObject
                return
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonValue, options: .prettyPrinted) else {
                setupDefaultErrorStatus()
                self.error = LXError.jsonSerializationFailed(message: "json data 解析失败")
                return
            }
            
            do {
                let model = try JSONDecoder().decode(T.self, from: jsonData)
                value = model
            } catch DecodingError.keyNotFound(let key, let context) {
                setupDefaultErrorStatus()
                self.error = LXError.dataContentTransformToModelFailed
                print("keyNotFound: \(key) is not found in JSON: \(context.debugDescription)")
            } catch DecodingError.valueNotFound(let type, let context) {
                setupDefaultErrorStatus()
                self.error = LXError.dataContentTransformToModelFailed
                print("valueNotFound: \(type) is not found in JSON: \(context.debugDescription)")
            } catch DecodingError.typeMismatch(let type, let context) {
                setupDefaultErrorStatus()
                self.error = LXError.dataContentTransformToModelFailed
                print("typeMismatch: \(type) is mismatch in JSON: \(context.debugDescription)")
            } catch DecodingError.dataCorrupted(let context) {
                setupDefaultErrorStatus()
                self.error = LXError.dataContentTransformToModelFailed
                print("dataCorrupted: \(context.debugDescription)")
            } catch let error {
                print("error: \(error.localizedDescription)")
                setupDefaultErrorStatus()
                self.error = LXError.exception(message: error.localizedDescription)
            }
            
        } else {
            setupDefaultErrorStatus()
            self.error = LXError.serverResponseError(message: jsonObject[ServerKey.message.rawValue] as? String, code: self.code)
        }
    }
}
