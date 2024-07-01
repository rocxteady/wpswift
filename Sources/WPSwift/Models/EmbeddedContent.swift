//
//  EmbeddedContent.swift
//
//
//  Created by Ulaş Sancak on 30.06.2024.
//

import Foundation

public struct EmbeddedContent: Decodable {
    public var author: Author? {
        _author.first
    }
    public var featuredMedia: FeaturedMedia? {
        _featuredMedia.first
    }
    public var tag: Term? {
        terms.first { $0.taxonomy == .tag }
    }
    public var category: Term? {
        terms.first { $0.taxonomy == .category }
    }
    private let _author: [Author]
    private let _featuredMedia: [FeaturedMedia]
    private let terms: [Term]

    public init(author: Author? = nil, featuredMedia: FeaturedMedia? = nil, tag: Term? = nil, category: Term? = nil) {
        _author = if let author {
            [author]
        } else {
            []
        }
        _featuredMedia = if let featuredMedia {
            [featuredMedia]
        } else {
            []
        }
        var terms: [Term] = []
        if let tag {
            terms.append(tag)
        }
        if let category {
            terms.append(category)
        }
        self.terms = terms
    }
    
    private enum CodingKeys: String, CodingKey {
        case _author = "author"
        case _featuredMedia = "wp:featuredmedia"
        case terms = "wp:term"
    }
}
