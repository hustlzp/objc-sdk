//
//  Extension.swift
//  AVOSCloud-iOS
//
//  Created by hustlzp on 2019/4/25.
//  Copyright © 2019 LeanCloud Inc. All rights reserved.
//

@_exported import PromiseKit
import Foundation

extension AVCloud {
    public class func callFunction(_: PMKNamespacer, name: String, parameters: [String: Any]?) -> Promise<Any?> {
        return Promise {
            callFunction(inBackground: name, withParameters: parameters, block: $0.resolve)
        }
    }
    
    public class func rpcFunction<T>(_: PMKNamespacer, name: String, cachePolicy: AVCachePolicy, maxCacheAge: TimeInterval,b parameters: [String: Any?]?) -> Promise<T> {
        return Promise { resolver in
            rpcFunction(inBackground: name, withParameters: parameters, cachePolicy: cachePolicy, maxCacheAge: maxCacheAge, block: { (result, fromCache, error) in
                guard error == nil else {
                    resolver.reject(error!)
                    return
                }
                
                guard let object = result as? T else {
                    resolver.reject(NSError(domain: kLeanCloudErrorDomain, code: kAVErrorIncorrectType, userInfo: [NSLocalizedDescriptionKey: "Return data's type should be \(T.self)"]))
                    return
                }
                
                resolver.fulfill(object)
            })
        }
    }
}
