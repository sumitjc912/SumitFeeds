//
//  URLSessionHTTPClientTests.swift
//  SumitFeedTests
//
//  Created by Prasadh M S on 11/05/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import XCTest
import SumitFeed


class URLSessionHTTPClientTests: XCTestCase {
    
    //Setup methode is called before each test
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    //Tear down methode is called after each test run
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    //Now test for URL
    func test_getFromURL_performsGETRequestWithURL(){
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequest{request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            
            exp.fulfill()
        }
        makeSUT().get(from: url, completion: { _ in})
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError(){
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        XCTAssertEqual(receivedError as NSError?, requestError)
    }
    
    //MARK : Check for all nil values / SAD PATH
    func test_getFromURL_fialsOnAllInvalidRepresentationCases(){
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    //MARK:- Sucess cases / HAPPY PATH
     func test_getFromURL_suceedsOnHTTPURLResponseWithData(){
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        
        let receivedValue = resultValueFor(data: data, response: response, error: nil)
         
         XCTAssertEqual(receivedValue?.data, data)
         XCTAssertEqual(receivedValue?.response.url, response.url)
         XCTAssertEqual(receivedValue?.response.statusCode, response.statusCode)
    }
    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithNilData(){
        let response = anyHTTPURLResponse()
        
        let receivedValue = resultValueFor(data: nil, response: response, error: nil)
        
       let emptyData = Data()
        XCTAssertEqual(receivedValue?.data, emptyData)
        XCTAssertEqual(receivedValue?.response.url, response.url)
        XCTAssertEqual(receivedValue?.response.statusCode, response.statusCode)
            
    }
    
    
    //MARK:- Helper
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient{
       let sut = URLSessionHTTPClient()
       trackForMemoryLeaks(sut,file: file,line: line)
       return sut
    }
    //Extract case for Data and response
    private func  resultValueFor(data:Data?, response:URLResponse? , error:Error?,file: StaticString = #file, line: UInt = #line) -> (data:Data,response : HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error,file: file,line: line)
                
        switch result {
            case let .success(data, response):
                return (data,response)
            default : XCTFail("Expected success , got \(result) insted ",file: file,line: line)
                return nil
        }
    }
    //Extract case for Error
    private func  resultErrorFor(data:Data?, response:URLResponse? , error:Error?,file: StaticString = #file, line: UInt = #line) -> Error? {
        
        let result = resultFor(data: data, response: response, error: error,file: file,line: line)
         
        switch result {
            case let .failure(error):
                return error
            default : XCTFail("Expected failure , got \(result) insted ",file: file,line: line)
             return nil
        }
    }
    private func resultFor(data:Data?, response:URLResponse? , error:Error?,file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub( data :data,response : response,error: error)
        let sut  = makeSUT(file:file,line:line)
        let exp = expectation(description: "wait for complition")
        var receivedResult : HTTPClientResult!
        
        sut.get(from: anyURL()){ result in
            receivedResult = result
            exp.fulfill()
        }
            wait(for: [exp], timeout: 1.0)
        return receivedResult
        
    }
    
    private func anyURL() -> URL{
        return URL(string: "https://a-given-url.com")!
    }
    private func anyData() -> Data{
        return Data("qqqeq".utf8)
    }
    private func anyNSError() -> NSError{
        return NSError(domain: "Any Error", code: 0)
    }
    private func nonHTTPURLResponse() -> URLResponse{
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    private func anyHTTPURLResponse() -> HTTPURLResponse{
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    private class URLProtocolStub : URLProtocol{
        private static var stub : Stub?
        private static var requestObserver : ((URLRequest) -> Void)?
        
        private struct Stub {
            let data : Data?
            let response : URLResponse?
            let error : Error?
        }
        static func stub( data:Data? , response:URLResponse?, error :Error? ){
            stub = Stub(data: data, response: response, error: error)
        }
        static func observeRequest(observer : @escaping (URLRequest) -> Void){
            requestObserver = observer
        }
        static func startInterceptingRequest(){
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        static func stopInterceptingRequest(){
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        //Check for every URL
        override class func canInit(with request: URLRequest) -> Bool {
            
            return true
        }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            requestObserver?(request)
            return request
        }
        override func startLoading() {
           
            if let data = URLProtocolStub.stub?.data{
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response{
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error{
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {}
        
    }
    
}
