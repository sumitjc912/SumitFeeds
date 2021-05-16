//
//  RemoteFeedLoaderTest.swift
//  SumitFeedTests
//
//  Created by Prasadh M S on 01/03/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import XCTest
import SumitFeed



class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load(completion: {_ in})
        XCTAssertEqual(client.requestedURLs, [url])
    }
    func test_loadTwise_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load{_ in}
        sut.load{_ in}
        
        XCTAssertEqual(client.requestedURLs, [url,url])
    }
    
    //If HTTP failed then what error to be shown to End user or how to handle that errors.
    func test_load_deliversErrorOnClientError(){
        
        let(sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: faliure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with : clientError)
        })
        
    }
    //Now we will check test case for invalid data
    func test_load_deliversErrorOnNon200HTTPResponse(){
        
        let(sut,client) = makeSUT()
        
        
            let sample = [199,201,202,203,300,299,301,399,400,401,499,500,501]
        
            sample.enumerated().forEach { index , code in
                
                expect(sut, toCompleteWith: faliure(.invalidData), when: {
                    let json = makeItemsJson([])
                     client.complete(withStatusCode : code ,data: json, at: index)
                })
        }
        
    }
    func test_load_deliversErroron200HTTPResponseWithInvalidJSON(){
        
        let(sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: faliure(.invalidData), when:{
           let invlaidJSON = Data(_: "invalid json".utf8)
           client.complete(withStatusCode : 200,  data: invlaidJSON)
        })
        
    }
    func test_load_deliversNoItemsOn200HTTPReponseWithEmptyJSONList(){

        let (sut,client)  = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeItemsJson([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    
    }
    //Happy path
    func test_load_deliversItemsOn200HTTPResponseWithJSONItem(){
        
        let (sut ,client) = makeSUT()
        
        //Item 1
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!)
        
        
        //Item 2
        let item2 = makeItem(
        id: UUID(),
        description: "A description",
        location: "A location",
        imageURL: URL(string: "http://another-url.com")!)
        
       
        
        
        let items = [item1.model,item2.model]
        expect(sut, toCompleteWith: .success(items), when: {
            let json = makeItemsJson([item1.json,item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
        
    }
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated(){
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJson([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!,file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        
        return (sut, client)
    }
    
    private func faliure (_ error : RemoteFeedLoader.Error) -> RemoteFeedLoader.Result{
        return .failure(error)
    }
    
    private func makeItem(id : UUID, description : String? = nil,location : String? = nil,imageURL : URL) -> (model:FeedItem , json: [String : Any]){
        let item = FeedItem(
            id : id,description: description,location: location,imageURL: imageURL
        )
        let json = [
            "id" : id.uuidString,
            "description" : description,
            "location" : location,
            "image" : imageURL.absoluteString
            ].reduce(into: [String:Any]()){(acct, e) in
                if let value = e.value {acct[e.key] = value}
        }
        return (item,json)
    }
    private func makeItemsJson(_ items:[[String:Any]]) -> Data{
        let json = ["items":  items]
        return  try! JSONSerialization.data(withJSONObject: json)
    }
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
    let exp = expectation(description: "Wait for load completion")

    sut.load { receivedResult in
        switch (receivedResult, expectedResult) {
        case let (.success(receivedItems), .success(expectedItems)):
            XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

        case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)

        default:
            XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
        }

        exp.fulfill()
     }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    private class HTTPClientSpy: HTTPClient {
        
        
        //Noe do all in singal array
        private var message = [(url:URL ,completion:( HTTPClientResult )->Void )]()
        
        var requestedURLs : [URL]{
            return message.map {$0.url}
        }

        func get(from url: URL , completion:@escaping( HTTPClientResult )->Void) {
            message.append((url,completion))
        }
        
        func complete(with error : Error, at index : Int = 0 ){
            message[index].completion(.failure(error))
        }
        func complete(withStatusCode code : Int ,data : Data, at index : Int = 0){
            
            let response = HTTPURLResponse(url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            
            message[index].completion(.success(data,response))
        }
    }

}
