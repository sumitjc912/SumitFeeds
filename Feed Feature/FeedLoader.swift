//
//  FeedLoader.swift
//  SumitFeed
//
//  Created by Prasadh M S on 26/02/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import Foundation

public enum LoadFeedResult  {
    case success ([FeedItem])
    case failure (Error)
}

public protocol  FeedLoader {
    func load(completion : @escaping (LoadFeedResult)-> Void)
}


