//
//  Multi_Clients_Interact_TestCase.swift
//  AVOS
//
//  Created by zapcannon87 on 09/03/2018.
//  Copyright © 2018 LeanCloud Inc. All rights reserved.
//

import XCTest

let file: String = "\(URL.init(fileURLWithPath: #file).deletingPathExtension().lastPathComponent)"

class Multi_Clients_Interact_TestCase: LCIMTestBase {
    
    static var client1: AVIMClient_Wrapper!
    
    static var client2: AVIMClient_Wrapper!
    
    override class func setUp() {
        super.setUp()
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            let client1: AVIMClient_Wrapper = AVIMClient_Wrapper(with: "\(file)\(#line)")
            
            semaphore.increment()
            
            client1.client.open(callback: { (succeeded: Bool, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
    
                XCTAssertTrue(succeeded)
                XCTAssertNil(error)
                
                if succeeded {
                    
                    self.client1 = client1
                }
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            let client2: AVIMClient_Wrapper = AVIMClient_Wrapper(with: "\(file)\(#line)")
            
            semaphore.increment()
            
            client2.client.open(callback: { (succeeded: Bool, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertTrue(succeeded)
                XCTAssertNil(error)
                
                if succeeded {
                    
                    self.client2 = client2
                }
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func createUniqueConversationByClient1() -> AVIMConversation? {
        
        guard let client1: AVIMClient_Wrapper = type(of: self).client1,
            let client2: AVIMClient_Wrapper = type(of: self).client2 else
        {
            return nil
        }
        
        var conversation: AVIMConversation?
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            semaphore.increment()
            
            client1.client.createConversation(
                withName: "\(file)\(#line)",
                clientIds: [client1.client.clientId, client2.client.clientId],
                attributes: nil,
                options: [.unique]
            ) { (conv: AVIMConversation?, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertNotNil(conv)
                XCTAssertNil(error)
                
                if let conv: AVIMConversation = conv {
                    
                    conversation = conv
                }
            }
            
        }, failure: {
            
            XCTFail("timeout")
        })
        
        return conversation
    }
    
    func test_recall_message() {
        
        guard let client1: AVIMClient_Wrapper = type(of: self).client1,
            let client2: AVIMClient_Wrapper = type(of: self).client2 else {
                XCTFail()
                return
        }
        
        guard let uniqueConversation: AVIMConversation = self.createUniqueConversationByClient1() else {
            XCTFail()
            return
        }
        
        var message: AVIMMessage?
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            let sendingMessage: AVIMTextMessage = AVIMTextMessage.init(text: "test", attributes: nil)
            
            semaphore.increment()
            
            uniqueConversation.send(sendingMessage, callback: { (succeeded: Bool, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertTrue(succeeded)
                XCTAssertNil(error)
                
                if succeeded {
                    
                    message = sendingMessage
                }
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
        
        guard let _message: AVIMMessage = message else {
            XCTFail()
            return
        }
        
        uniqueConversation.add(client1)
        
        uniqueConversation.add(client2)
        
        self.runloopTestingAsync(timeout: 60, async: { (semaphore: RunLoopSemaphore) in
            
            semaphore.increment()
            
            client1.messageHasBeenUpdatedClosure = { (conv: AVIMConversation, message: AVIMMessage) in
                
                semaphore.decrement()
                
                XCTAssertEqual(message.messageId, _message.messageId)
            }
            
            semaphore.increment()
            
            client2.messageHasBeenUpdatedClosure = { (conv: AVIMConversation, message: AVIMMessage) in
                
                semaphore.decrement()
                
                XCTAssertEqual(message.messageId, _message.messageId)
            }
            
            semaphore.increment()
            
            uniqueConversation.recall(_message, callback: { (succeeded: Bool, error: Error?, recalledMessage: AVIMMessage?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertTrue(succeeded)
                XCTAssertNil(error)
                
                XCTAssertEqual(_message.messageId, recalledMessage?.messageId)
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
    }
    
    func test_sendReceive_imageMessage() {
        
        guard let _: AVIMClient_Wrapper = type(of: self).client1,
            let client2: AVIMClient_Wrapper = type(of: self).client2 else {
                XCTFail()
                return
        }
        
        guard let uniqueConversation: AVIMConversation = self.createUniqueConversationByClient1() else {
            XCTFail()
            return
        }
        
        var receiveTypedMessage: AVIMTypedMessage!
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            let imageMessage: AVIMImageMessage = {
                
                let filePath: String = Bundle(for: type(of: self)).path(forResource: "testImage", ofType: "png")!
                
                let url: URL = URL.init(fileURLWithPath: filePath)
                
                let data: Data = try! Data.init(contentsOf: url)
                
                let file: AVFile = AVFile(data: data, name: "testImage.png")
                
                let imageMessage: AVIMImageMessage = AVIMImageMessage(text: "test", file: file, attributes: nil)
                
                return imageMessage
            }()
            
            semaphore.increment()
            
            client2.didReceiveTypedMessageClosure = { (conv: AVIMConversation, message: AVIMTypedMessage) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertEqual(message.messageId, imageMessage.messageId)
                
                if message.messageId == imageMessage.messageId {
                    
                    receiveTypedMessage = message
                }
            }
            
            semaphore.increment()
            
            uniqueConversation.send(imageMessage, callback: { (succeeded: Bool, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)
                
                XCTAssertTrue(succeeded)
                XCTAssertNil(error)
                
                XCTAssertNotNil(imageMessage.messageId)
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
        
        guard receiveTypedMessage != nil, receiveTypedMessage.file != nil else {
            XCTFail()
            return
        }
        
        self.runloopTestingAsync(async: { (semaphore: RunLoopSemaphore) in
            
            semaphore.increment()
            
            receiveTypedMessage.file?.download(completionHandler: { (url: URL?, error: Error?) in
                
                semaphore.decrement()
                
                XCTAssertTrue(Thread.isMainThread)

                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url: URL = url {
                    
                    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                }
            })
            
        }, failure: {
            
            XCTFail("timeout")
        })
    }
    
}

class AVIMClient_Wrapper: NSObject {
    
    let client: AVIMClient
    
    var messageHasBeenUpdatedClosure: ((AVIMConversation, AVIMMessage) -> Void)?
    
    var didReceiveTypedMessageClosure: ((AVIMConversation, AVIMTypedMessage) -> Void)?
    
    init(with clientId: String) {
        
        self.client = AVIMClient.init(clientId: clientId)
        
        super.init()
        
        self.client.delegate = self
    }
    
}

extension AVIMClient_Wrapper: AVIMClientDelegate, AVIMConversationDelegate {
    
    func imClientClosed(_ imClient: AVIMClient, error: Error?) {}
    func imClientResuming(_ imClient: AVIMClient) {}
    func imClientResumed(_ imClient: AVIMClient) {}
    func imClientPaused(_ imClient: AVIMClient) {}
    
    func conversation(_ conversation: AVIMConversation, messageHasBeenUpdated message: AVIMMessage) {
        self.messageHasBeenUpdatedClosure?(conversation, message)
    }
    
    func conversation(_ conversation: AVIMConversation, didReceive message: AVIMTypedMessage) {
        self.didReceiveTypedMessageClosure?(conversation, message)
    }
    
}