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
    
    /// 调用云函数
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func callFunction(_: PMKNamespacer, name: String, parameters: [String: Any]?) -> Promise<Any?> {
        return Promise {
            callFunction(inBackground: name, withParameters: parameters, block: $0.resolve)
        }
    }
    
    /// RPC 调用云函数
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - cachePolicy: <#cachePolicy description#>
    ///   - maxCacheAge: <#maxCacheAge description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
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

public protocol PromiseAVObject { }

extension AVObject: PromiseAVObject {
}

extension PromiseAVObject where Self: AVObject {
    public func fetch(_: PMKNamespacer, withKeys keys: [String]? = nil) -> Promise<Self> {
        return Promise<Self>(resolver: { (seal) in
            fetchInBackground(withKeys: keys, block: { (result, error) in
                seal.resolve(result as? Self, error)
            })
        })
    }
    
    public func save(_: PMKNamespacer) -> Promise<Self> {
        return Promise<Self>(resolver: { (seal) in
            saveInBackground({ (succeeded, error) in
                seal.resolve(self, error)
            })
        })
    }
}

extension AVUser {
    
    /// 用户名登录
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - username: <#username description#>
    ///   - password: <#password description#>
    /// - Returns: <#return value description#>
    public class func logInWithUsername(_: PMKNamespacer, _ username: String, password: String) -> Promise<AVUser> {
        return Promise<AVUser>(resolver: { (seal) in
            AVUser.logInWithUsername(inBackground: username, password: password, block: { (user, error) in
                seal.resolve(user, error)
            })
        })
    }
    
    /// 邮箱登录
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - email: <#email description#>
    ///   - password: <#password description#>
    /// - Returns: <#return value description#>
    public class func loginWithEmail(_: PMKNamespacer, email: String, password: String) -> Promise<AVUser> {
        return Promise<AVUser>(resolver: { (seal) in
            AVUser.login(withEmail: email, password: password, block: { (user, error) in
                seal.resolve(user, error)
            })
        })
    }
    
    /// 请求验证邮箱
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - email: <#email description#>
    /// - Returns: <#return value description#>
    public class func requestEmailVerify(_: PMKNamespacer, email: String) -> Promise<Void> {
        return Promise<Void>(resolver: { (resolver) in
            AVUser.requestEmailVerify(email, with: { (succeeded, error) in
                resolver.resolve(error)
            })
        })
    }
    
    /// 发送密码重置邮件
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - email: <#email description#>
    /// - Returns: <#return value description#>
    public class func requestPasswordResetForEmail(_: PMKNamespacer, email: String) -> Promise<Void> {
        return Promise<Void>(resolver: { (resolver) in
            AVUser.requestPasswordResetForEmail(inBackground: email
                , block: { (succeeded, error) in
                resolver.resolve(error)
            })
        })
    }
}
