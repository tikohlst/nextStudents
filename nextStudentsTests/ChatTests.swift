//
//  ChatTests.swift
//  nextStudentsTests
//
//  Created by Tim Kohlstadt on 19.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import XCTest
import Firebase

class ChatTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMapping() throws {
        let testRawDataUser = [ "firstName": "testFirstName",
                                "lastName": "testLastName",
                                "street": "testStreet",
                                "housenumber": "testHousenumber",
                                "zipcode": "12345",
                                "gpsCoordinates": GeoPoint(latitude: 0, longitude: 0),
                                "radius": 100,
                                "bio": "testBio",
                                "skills": "testSkills"] as [String: Any]?
        
        var chatPartner = User()
        
        do {
            chatPartner = try User().mapData(uid: "testUID", data: testRawDataUser)
        } catch UserError.mapDataError {
            print("UserError.mapDataError: \(UserError.mapDataError)")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        let testRawDataChat = [ "id": "testChatUID",
                                "content": "testLatestMessage",
                                "created": Timestamp()] as [String: Any]?
        
        var chat = Chat()
        
        do {
            chat = try Chat().mapData(data: testRawDataChat, chatPartner: chatPartner)!
        } catch ChatError.mapDataError {
            print("ChatError.mapDataError: \(ChatError.mapDataError)")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        XCTAssertTrue(chat.localChatID == "testChatUID", "Error chat.localChatID Test")
        XCTAssertTrue(chat.chatPartner.uid == chatPartner.uid, "Error chat.chatPartner Test")
        XCTAssertTrue(chat.latestMessage == "testLatestMessage", "Error chat.latestMessage Test")
    }
    
    func testMappingWithError() throws {
        let testRawDataChat = [ "id": 123,
                                "content": "testLatestMessage",
                                "created": Timestamp()] as [String: Any]?
        
        let chatPartner = User()
        
        XCTAssertThrowsError(try Chat().mapData(data: testRawDataChat, chatPartner: chatPartner),
                             "Chat().mapData() should have thrown an error if 'chatPartner' is nil") { (errorThrown) in
                                XCTAssertEqual(errorThrown as? ChatError, ChatError.mapDataError)
        }
    }
    
}
