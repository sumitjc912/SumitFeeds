//
//  SumitFeedApiEndToEndTests.swift
//  SumitFeedApiEndToEndTests
//
//  Created by Prasadh M S on 17/05/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import XCTest
import SumitFeed

class SumitFeedApiEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData(){
        
        let testServiceURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test/api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: testServiceURL, client: client)
        let exp = expectation(description: "Wait for load completion")
        var receivedURL : LoadFeedResult?
        loader.load {result in
            receivedURL = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        
        switch receivedURL {
        case let .success(items)?:
            XCTAssertEqual(items.count,8, "Expected 8 items in thetest account feed")
        case let .failure(error)?:
            XCTFail("Expected sumits feed result \(error) instead")
        default:
            XCTFail("Expected successfull feed result , got no result instead")
        }
    }

}
