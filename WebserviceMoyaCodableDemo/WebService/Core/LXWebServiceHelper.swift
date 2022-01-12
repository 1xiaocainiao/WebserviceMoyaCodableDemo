

import Foundation
import Moya


open class LXWebServiceHelper<T> where T: Codable {
    typealias JSONObjectHandle = (Any) -> Void
    typealias ExceptionHandle = (Error?) -> Void
    typealias ResultContainerHandle = (LXRequestResultContainer<T>) -> Void
    
    
    @discardableResult
    func requestJSONObject<R: LXMoyaTargetType>(_ type: R,
                                                        progressBlock: ProgressBlock? = nil,
                                                        completionHandle: @escaping JSONObjectHandle,
                                                        exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return _WebServiceHelper.default.requestJSONObject(type,
                                                           progressBlock: progressBlock,
                                                           completionHandle: completionHandle,
                                                           exceptionHandle: exceptionHandle)
    }
    
    @discardableResult
    func requestJSONModel<R: LXMoyaTargetType>(_ type: R,
                                                       progressBlock: ProgressBlock? = nil,
                                                       completionHandle: @escaping ResultContainerHandle,
                                                       exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return _WebServiceHelper.default.requestJSONObject(type, progressBlock: progressBlock) { result in
            let container = LXRequestResultContainer<T>.init(jsonObject: result)
            if container.isValid {
                completionHandle(container)
            } else {
                exceptionHandle(container.error)
            }
        } exceptionHandle: { error in
            exceptionHandle(error)
        }
    }
}

fileprivate class _WebServiceHelper {
    static let `default` = _WebServiceHelper()
    
    // 可自定义加解密插件等
    private func createProvider<R: LXMoyaTargetType>(type: R) -> MoyaProvider<R> {
        let activityPlugin = NetworkActivityPlugin { state, targetType in
            self.networkActiviyIndicatorVisible(visibile: state == .began)
        }
        
        //        let aesPlugin = LXHandleRequestPlugin()
        
        let crePlugin = type.credentials
        
        var plugins = [PluginType]()
        plugins.append(activityPlugin)
        
        if crePlugin != nil {
            plugins.append(crePlugin!)
        }
        
        let provider = MoyaProvider<R>(plugins: plugins)
        
        return provider
    }
    
    private func networkActiviyIndicatorVisible(visibile: Bool) {
        if #available(iOS 13, *) {
            
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = visibile
        }
    }
    
    @discardableResult
    func requestJSONObject<R: LXMoyaTargetType, T: LXBaseModel>(_ type: R,
                                                        progressBlock: ProgressBlock?,
                                                        completionHandle: @escaping LXWebServiceHelper<T>.JSONObjectHandle, exceptionHandle: @escaping (Error?) -> Void) -> Cancellable? {
        let provider = createProvider(type: type)
        let cancelable = provider.request(type, callbackQueue: nil, progress: progressBlock) { result in
            switch result {
            case .success(let successResponse):
                do {
                    let jsonObject = try successResponse.mapJSON()
                    
                    #if DEBUG
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    let json = String(data: jsonData, encoding: .utf8) ?? ""
                    printl(message: json)
                    #else
                    #endif
                    
                    let container = LXRequestResultContainer<T>(jsonObject: jsonObject)
                    if container.isValid {
                        completionHandle(jsonObject)
                    } else {
                        exceptionHandle(container.error)
                    }
                } catch  {
                    exceptionHandle(LXError.serverDataFormatError)
                }
                break
            case .failure(_):
                exceptionHandle(LXError.networkConnectFailed)
                break
            }
        }
        return cancelable
    }
}
