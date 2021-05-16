//
//  FeedItems.swift
//  SumitFeed
//
//  Created by Prasadh M S on 26/02/21.
//  Copyright © 2021 Sumit. All rights reserved.
//

import Foundation

public struct FeedItem : Equatable{
    
    public let id : UUID
    public let description : String?
    public let location :String?
    public let imageURL : URL
    
    public init(id: UUID, description : String? ,location : String?,imageURL : URL){
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
    
}

