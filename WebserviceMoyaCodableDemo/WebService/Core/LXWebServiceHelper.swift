

import Foundation
import Moya


open class LXWebServiceHelper<T> where T: Codable {
    typealias JSONObjectHandle = (Any) -> Void
    typealias ExceptionHandle = (Error?) -> Void
    typealias ResultContainerHandle = (LXRequestResultContainer<T>) -> Void
    
    @discardableResult
    func requestJSONModel<R: LXMoyaTargetType>(_ type: R,
                                               progressBlock: ProgressBlock? = nil,
                                               completionHandle: @escaping ResultContainerHandle,
                                               exceptionHandle: @escaping ExceptionHandle) -> Cancellable? {
        return requestJSONObject(type, progressBlock: progressBlock) { result in
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
    private func requestJSONObject<R: LXMoyaTargetType>(_ type: R,
                                                progressBlock: ProgressBlock?,
                                                completionHandle: @escaping JSONObjectHandle,
                                                exceptionHandle: @escaping (Error?) -> Void) -> Cancellable? {
        let provider = createProvider(type: type)
        let cancelable = provider.request(type, callbackQueue: nil, progress: progressBlock) { result in
            switch result {
            case .success(let successResponse):
                do {
#if DEBUG
                    let json = String(data: successResponse.data, encoding: .utf8) ?? ""
                    print(json)
#else
#endif
                    let jsonObject = try successResponse.mapJSON()
                    
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

