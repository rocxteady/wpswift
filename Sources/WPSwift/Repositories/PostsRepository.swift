//
//  !isPresented.swift
//
//
//  Created by Ulaş Sancak on 6.10.2023.
//

import Foundation
import Resting

public struct PostsRepository: Sendable {
    public init() {}
    
    public func getPostsClient(page: Int = 1, perPage: Int = 10, order: OrderType = .descending, categories: [Int]? = nil, categoriesToExclude: [Int]? = nil, tags: [Int]? = nil, tagsToExclude: [Int]? = nil, include: [Int]? = nil) throws -> WPClient<EmptyModel, [Post]> {
        try .init(.init(endpoint: WPEndpoint.Posts.posts.path, parameters: .createParamsForPosts(page: page, perPage: perPage, order: order, categories: categories, categoriesToExclude: categoriesToExclude, tags: tags, tagsToExclude: tagsToExclude, include: include)))
    }
    
    public func getSearchPostsClient(term: String, page: Int = 1, perPage: Int = 10) throws -> WPClient<EmptyModel, [SimplePost]> {
        try .init(.init(endpoint: WPEndpoint.Posts.search.path, parameters: .createParamsForSearchPosts(term: term, page: page, perPage: perPage)))
    }
    
    public func getPostClient(by id: Int) throws -> WPClient<EmptyModel, Post> {
        try .init(.init(endpoint: WPEndpoint.Posts.post(id: id).path, parameters: .createParamsForPost()))
    }

    public func createPostClient(by post: PostToCreate) throws -> WPClient<PostToCreate, Post> {
        try .init(.init(endpoint: WPEndpoint.Posts.posts.path, method: .post, requestModel: post))
    }

    public func updatePostClient(by id: Int, post: PostToUpdate) throws -> WPClient<PostToUpdate, Post> {
        try .init(.init(endpoint: WPEndpoint.Posts.post(id: id).path, method: .post, requestModel: post))
    }
}

extension PostsRepository {
    public func getPostsClient(baseURL: String, page: Int = 1, perPage: Int = 10, order: OrderType = .descending, categories: [Int]? = nil, categoriesToExclude: [Int]? = nil, tags: [Int]? = nil, tagsToExclude: [Int]? = nil, include: [Int]? = nil) throws -> WPClient<EmptyModel, [Post]> {
        try .init(.init(baseURL: baseURL, endpoint: WPEndpoint.Posts.posts.path, parameters: .createParamsForPosts(page: page, perPage: perPage, order: order, categories: categories, categoriesToExclude: categoriesToExclude, tags: tags, tagsToExclude: tagsToExclude, include: include)))
    }
    
    public func getSearchPostsClient(baseURL: String, term: String, page: Int = 1, perPage: Int = 10) throws -> WPClient<EmptyModel, [SimplePost]> {
        try .init(.init(baseURL: baseURL, endpoint: WPEndpoint.Posts.search.path, parameters: .createParamsForSearchPosts(term: term, page: page, perPage: perPage)))
    }
    
    public func getPostClient(baseURL: String, by id: Int) throws -> WPClient<EmptyModel, Post> {
        try .init(.init(baseURL: baseURL, endpoint: WPEndpoint.Posts.post(id: id).path, parameters: .createParamsForPost()))
    }

    public func createPostClient(baseURL: String, by post: PostToCreate) throws -> WPClient<PostToCreate, Post> {
        try .init(.init(baseURL: baseURL, endpoint: WPEndpoint.Posts.posts.path, method: .post, requestModel: post))
    }

    public func updatePostClient(baseURL: String, by id: Int, post: PostToUpdate) throws -> WPClient<PostToUpdate, Post> {
        try .init(.init(baseURL: baseURL, endpoint: WPEndpoint.Posts.post(id: id).path, method: .post, requestModel: post))
    }
}
