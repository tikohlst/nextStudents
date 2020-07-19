//
//  OfferTests.swift
//  nextDoorTests
//
//  Created by Tim Kohlstadt on 19.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import XCTest
import Firebase

class OfferTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMapping() throws {
        let testRawDataOffer = [ "title": "testTitle",
                                 "description": "testDescription",
                                 "date": Timestamp(),
                                 "duration": "testDuration",
                                 "type": "Offer"] as [String: Any]?
        
        let testRawDataOwner = [ "firstName": "testFirstName",
                                 "lastName": "testLastName"] as [String: Any]?
        
        var offer = Offer()
        
        do {
            offer = try Offer().mapData(uidOffer: "testUidOffer", dataOffer: testRawDataOffer,
                                        uidOwner: "testUidOwner", dataOwner: testRawDataOwner)
        } catch OfferError.mapDataError {
            print("OfferError.mapDataError: \(OfferError.mapDataError)")
        } catch UserError.mapDataError {
            print("UserError.mapDataError: \(UserError.mapDataError)")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        XCTAssertTrue(offer.uid == "testUidOffer", "Error offer.uid Test")
        XCTAssertTrue(offer.ownerUID == "testUidOwner", "Error offer.ownerUID Test")
        XCTAssertTrue(offer.ownerFirstName == "testFirstName", "Error offer.ownerFirstName Test")
        XCTAssertTrue(offer.ownerLastName == "testLastName", "Error offer.ownerLastName Test")
        XCTAssertTrue(offer.title == "testTitle", "Error offer.title Test")
        XCTAssertTrue(offer.description == "testDescription", "Error offer.description Test")
        XCTAssertTrue(offer.duration == "testDuration", "Error offer.duration Test")
        XCTAssertTrue(offer.type == "Offer", "Error offer.type Test")
    }
    
    func testMappingWithError() throws {
        let testRawDataOffer = [ "title": "testTitle",
                                 "date": Timestamp(),
                                 "duration": "testDuration",
                                 "type": "Offer"] as [String: Any]?
        
        let testRawDataOwner = [ "firstName": "testFirstName",
                                 "lastName": "testLastName"] as [String: Any]?
        
        XCTAssertThrowsError(try Offer().mapData(uidOffer: "testUidOffer", dataOffer: testRawDataOffer,
                                                 uidOwner: "testUidOwner", dataOwner: testRawDataOwner),
                             "Offer().mapData() should have thrown an error if 'desciption' is nil") { (errorThrown) in
                                XCTAssertEqual(errorThrown as? OfferError, OfferError.mapDataError)
        }
    }
    
}
