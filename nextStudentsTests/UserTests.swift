//
//  UserTests.swift
//  nextStudentsTests
//
//  Created by Tim Kohlstadt on 17.07.20.
//  Copyright © 2020 Tim Kohlstadt. All rights reserved.
//

import XCTest
import Firebase

class UserTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMapping() throws {
        let testRawData = [ "firstName": "testFirstName",
                            "lastName": "testLastName",
                            "street": "testStreet",
                            "housenumber": "testHousenumber",
                            "zipcode": "12345",
                            "gpsCoordinates": GeoPoint(latitude: 0, longitude: 0),
                            "radius": 100,
                            "bio": "testBio",
                            "skills": "testSkills",
                            "school": "testSchool",
                            "degreeProgram": "testDegreeProgram"] as [String: Any]?
        
        var user = User()
        
        do {
            user = try User().mapData(uid: "testUID", data: testRawData)
        } catch UserError.mapDataError {
            print("UserError.mapDataError: \(UserError.mapDataError)")
        } catch {
            print("Unexpected error: \(error)")
        }
        
        XCTAssertTrue(user.firstName == "testFirstName", "Error user.firstName Test")
        XCTAssertTrue(user.lastName == "testLastName", "Error user.lastName Test")
        XCTAssertTrue(user.street == "testStreet", "Error user.street Test")
        XCTAssertTrue(user.housenumber == "testHousenumber", "Error user.housenumber Test")
        XCTAssertTrue(user.zipcode == "12345", "Error user.zipcode Test")
        XCTAssertTrue(user.gpsCoordinates == GeoPoint(latitude: 0, longitude: 0), "Error user.gpsCoordinates Test")
        XCTAssertTrue(user.radius == 100, "Error user.radius Test")
        XCTAssertTrue(user.bio == "testBio", "Error user.bio Test")
        XCTAssertTrue(user.skills == "testSkills", "Error user.skills Test")
        XCTAssertTrue(user.school == "testSchool", "Error user.school Test")
        XCTAssertTrue(user.degreeProgram == "testDegreeProgram", "Error user.degreeProgram Test")
    }
    
    func testMappingWithError() throws {
        
        let testRawData = [ "firstName": "testFirstName",
                            "lastName": "testLastName",
                            "street": "testStreet",
                            "housenumber": "testHousenumber",
                            "zipcode": "12345",
                            "gpsCoordinates": GeoPoint(latitude: 0, longitude: 0),
                            "bio": "testBio",
                            "skills": "testSkills",
                            "school": "testSchool",
                            "degreeProgram": "testDegreeProgram"] as [String: Any]?
        
        XCTAssertThrowsError(try User().mapData(uid: "testUID", data: testRawData),
                             "User().mapData() should have thrown an error if 'radius' is missing") { (errorThrown) in
                                XCTAssertEqual(errorThrown as? UserError, UserError.mapDataError)
        }
    }
    
}
