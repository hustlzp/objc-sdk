//
//  AVOSCloud+Helper.swift
//  xcz
//
//  Created by hustlzp on 16/3/19.
//  Copyright © 2016年 Zhipeng Liu. All rights reserved.
//

import Foundation
import PromiseKit

extension AVQuery {
    func range(_ page: Int, firstPage: Int, perPage: Int) {
        skip = (page == 1) ? 0 : firstPage + perPage * (page - 2)
        limit = (page == 1) ? firstPage : perPage
    }
}

extension AVCloud {
    class func callFunction(_: PMKNamespacer, name: String, parameters: [String: Any]?) -> Promise<Any?> {
        return Promise {
            callFunction(inBackground: name, withParameters: parameters, block: $0.resolve)
        }
    }
    
    class func rpcFunction<T>(_: PMKNamespacer, name: String, cachePolicy: AVCachePolicy, maxCacheAge: TimeInterval, parameters: [String: Any?]?) -> Promise<T> {
        return Promise { resolver in
            rpcFunction(inBackground: name, withParameters: parameters, cachePolicy: cachePolicy, maxCacheAge: maxCacheAge, block: { (result, fromCache, error) in
                guard error == nil else {
                    resolver.reject(error!)
                    return
                }
                
                guard let object = result as? T else {
                    resolver.reject(XCZError("返回数据的格式错误".localized()))
                    return
                }
                
                resolver.fulfill(object)
            })
        }
    }
}

protocol PromiseAVObject { }

extension AVObject: PromiseAVObject {
}

extension PromiseAVObject where Self: AVObject {
    func fetch(_: PMKNamespacer, withKeys keys: [String]? = nil) -> Promise<Self> {
        return Promise<Self>(resolver: { (seal) in
            fetchInBackground(withKeys: keys, block: { (result, error) in
                seal.resolve(result as? Self, error)
            })
        })
    }
    
    func save(_: PMKNamespacer) -> Promise<Self> {
        return Promise<Self>(resolver: { (seal) in
            saveInBackground({ (succeeded, error) in
                seal.resolve(self, error)
            })
        })
    }
}

extension AVUser {
    class func logInWithUsername(_: PMKNamespacer, _ username: String, password: String) -> Promise<User> {
        return Promise<User>(resolver: { (seal) in
            User.logInWithUsername(inBackground: username, password: password, block: { (user, error) in
                seal.resolve(user as? User, error)
            })
        })
    }
    
    class func loginWithEmail(_: PMKNamespacer, email: String, password: String) -> Promise<User> {
        return Promise<User>(resolver: { (seal) in
            User.login(withEmail: email, password: password, block: { (user, error) in
                seal.resolve(user as? User, error)
            })
        })
    }
    
    class func requestPasswordResetForEmail(_: PMKNamespacer, email: String) -> Promise<Void> {
        return Promise<Void>(resolver: { (resolver) in
            User.requestPasswordResetForEmail(inBackground: email
                , block: { (_, error) in
                guard error == nil else {
                    resolver.reject(error!)
                    return
                }
                    
                resolver.fulfill(())
            })
        })
    }
}
