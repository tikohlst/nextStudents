//
//  MessageTests.swift
//  nextStudentsTests
//
//  Created by Tim Kohlstadt on 19.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import XCTest
import Firebase

class MessageTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMapping() throws {
        let testRawData = [ "id": "testID",
                            "senderID": "testSenderID",
                            "created": Timestamp(),
                            "content": "testContent"] as [String: Any]?
        
        var message = Message()
        
        do {
            message = try Message().mapData(data: testRawData)!
        } catch MessageError.mapDataError {
            print("MessageError.mapDataError: \(MessageError.mapDataError)")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        XCTAssertTrue(message.id == "testID", "Error message.id Test")
        XCTAssertTrue(message.senderUID == "testSenderID", "Error message.senderUID Test")
        XCTAssertTrue(message.content == "testContent", "Error message.content Test")
    }
    
    func testMappingWithError() throws {
        
        let testRawData = [ "id": "testID",
                            "senderID": "testSenderID",
                            "content": "testContent"] as [String: Any]?
        
        XCTAssertThrowsError(try Message().mapData(data: testRawData),
                             "Message().mapData() should have thrown an error if 'created' is missing") { (errorThrown) in
                                XCTAssertEqual(errorThrown as? MessageError, MessageError.mapDataError)
        }
    }
    
}
