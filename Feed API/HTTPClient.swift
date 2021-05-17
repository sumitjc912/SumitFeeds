//
//  HTTPClient.swift
//  SumitFeed
//
//  Created by Prasadh M S on 01/04/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import Foundation


public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
