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
    
    /// 调用云函数（类型推导）
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func callFunction<T>(_: PMKNamespacer, name: String, parameters: [String: Any]?) -> Promise<T> {
        return Promise { resolver in
            callFunction(inBackground: name, withParameters: parameters, block: { (result, error) in
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
    
    /// 调用云函数（传入类型）
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func callFunction<T>(_: PMKNamespacer, name: String, parameters: [String: Any]?, type: T.Type) -> Promise<T> {
        return Promise { resolver in
            callFunction(inBackground: name, withParameters: parameters, block: { (result, error) in
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
    
    /// RPC 调用云函数（传入类型）
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - cachePolicy: <#cachePolicy description#>
    ///   - maxCacheAge: <#maxCacheAge description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func rpcFunction<T>(_: PMKNamespacer, name: String, cachePolicy: AVCachePolicy, maxCacheAge: TimeInterval, parameters: [String: Any?]?, type: T.Type) -> Promise<T> {
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
    
    /// RPC 调用云函数（类型推导）
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - cachePolicy: <#cachePolicy description#>
    ///   - maxCacheAge: <#maxCacheAge description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func rpcFunction<T>(_: PMKNamespacer, name: String, cachePolicy: AVCachePolicy, maxCacheAge: TimeInterval, parameters: [String: Any?]?) -> Promise<T> {
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

    /// RPC 调用云函数
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - name: <#name description#>
    ///   - cachePolicy: <#cachePolicy description#>
    ///   - maxCacheAge: <#maxCacheAge description#>
    ///   - parameters: <#parameters description#>
    /// - Returns: <#return value description#>
    public class func rpcFunction(_: PMKNamespacer, name: String, cachePolicy: AVCachePolicy, maxCacheAge: TimeInterval, parameters: [String: Any?]?) -> Promise<Any> {
        return Promise { resolver in
            rpcFunction(inBackground: name, withParameters: parameters, cachePolicy: cachePolicy, maxCacheAge: maxCacheAge, block: { (result, fromCache, error) in
                resolver.resolve(result, error)
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
    
    /// 删除对象
    ///
    /// - Parameter _: <#_ description#>
    /// - Returns: <#return value description#>
    public func delete(_: PMKNamespacer) -> Promise<Void> {
        return Promise<Void>(resolver: { (seal) in
            deleteInBackground({ (succeeded, error) in
                guard succeeded else {
                    seal.reject(error ?? NSError(domain: kLeanCloudErrorDomain, code: kAVErrorInternalServer, userInfo: nil))
                    return
                }
                
                seal.resolve(error)
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
    
    public class func logInWithMobilePhone(_: PMKNamespacer, _ phone: String, password: String) -> Promise<AVUser> {
        return Promise<AVUser>(resolver: { (seal) in
            AVUser.logInWithMobilePhoneNumber(inBackground: phone, password: password, block: { (user, error) in
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
    
    public func updatePassword(_: PMKNamespacer, _ oldPassword: String, _ newPassword: String) -> Promise<Void> {
        return Promise<Void>(resolver: { (seal) in
            self.updatePassword(oldPassword, newPassword: newPassword) { (_, error) in
                seal.resolve(error)
            }
        })
    }
    
    /// 注册
    ///
    /// - Parameter _: <#_ description#>
    /// - Returns: <#return value description#>
    public func signUp(_: PMKNamespacer) -> Promise<Void> {
        return Promise(resolver: { (seal) in
            self.signUpInBackground({ (succeeded, error) in
                seal.resolve(error)
            })
        })
    }
    
    public class func requestPasswordReset(_: PMKNamespacer, withPhoneNumber phoneNumber: String) -> Promise<Void> {
        return Promise(resolver: { (seal) in
            AVUser.requestPasswordReset(withPhoneNumber: phoneNumber, block: { (_, error) in
                seal.resolve(error)
            })
        })
    }
    
    public class func resetPassword(_: PMKNamespacer, withSmsCode code: String, newPassword: String) -> Promise<Void> {
        return Promise(resolver: { (seal) in
            self.resetPassword(withSmsCode: code, newPassword: newPassword, block: { (_, error) in
                seal.resolve(error)
            })
        })
    }
    
    /// 关注
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - userId: <#userId description#>
    /// - Returns: <#return value description#>
    public func follow(_: PMKNamespacer, _ userId: String) -> Promise<Void> {
        return Promise(resolver: { (seal) in
            follow(userId, andCallback: { (succeeded, error) in
                guard succeeded else {
                    seal.reject(error ?? NSError(domain: kLeanCloudErrorDomain, code: kAVErrorInternalServer, userInfo: nil))
                    return
                }
                
                seal.resolve(error)
            })
        })
    }
    
    /// 取消关注
    ///
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - userId: <#userId description#>
    /// - Returns: <#return value description#>
    public func unfollow(_: PMKNamespacer, _ userId: String) -> Promise<Void> {
        return Promise(resolver: { (seal) in
            unfollow(userId, andCallback: { (succeeded, error) in
                guard succeeded else {
                    seal.reject(error ?? NSError(domain: kLeanCloudErrorDomain, code: kAVErrorInternalServer, userInfo: nil))
                    return
                }
                
                seal.resolve(error)
            })
        })
    }
    
}

extension AVFile {
    public func upload(_: PMKNamespacer, progress: ((Int) -> Void)? = nil) -> Promise<AVFile> {
        return Promise(resolver: { (seal) in
            self.upload(progress: progress, completionHandler: { (succeeded, error) in
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                seal.fulfill(self)
            })
        })
    }
    
}

extension AVSMS {
    /// 发送验证码
    ///
    /// - Parameters:
    ///   - mobilePhoneNumber: <#mobilePhoneNumber description#>
    ///   - applicationName: <#applicationName description#>
    ///   - operation: <#operation description#>
    ///   - ttl: <#ttl description#>
    /// - Returns: <#return value description#>
    public class func sendSmsCode(_: PMKNamespacer, _ mobilePhoneNumber: String, applicationName: String, operation: String, ttl: Int = 10) -> Promise<Void> {
        let option = AVShortMessageRequestOptions()
        option.ttl = ttl
        option.applicationName = applicationName
        option.operation = operation
        
        return Promise { resolver in
            requestShortMessage(forPhoneNumber: mobilePhoneNumber, options: option, callback: { (_, error) in
                resolver.resolve(error)
            })
        }
    }
    
    /// 验证验证码
    ///
    /// - Parameters:
    ///   - code: <#code description#>
    ///   - mobilePhoneNumber: <#mobilePhoneNumber description#>
    /// - Returns: <#return value description#>
    public class func verifySmsCode(_: PMKNamespacer, _ code: String, mobilePhoneNumber: String) -> Promise<Void> {
        return Promise { resolver in
            AVOSCloud.verifySmsCode(code, mobilePhoneNumber: mobilePhoneNumber, callback: { (succeeded, error) in
                resolver.resolve(error)
            })
        }
    }
    
}
