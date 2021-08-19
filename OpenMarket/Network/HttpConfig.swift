//
//  httpConfig.swift
//  OpenMarket
//
//  Created by kjs on 2021/08/16.
//

import Foundation

enum HttpConfig {
    static let baseURL = "https://camp-open-market-2.herokuapp.com/"
    
    static let invailedPath = "AppError: current path is invailed"
    static let unknownError = "Error: unknown error occured"
    
    static let requestHeader = "multipart/form-data; boundary="
    static let contentType = "Content-Type"
    static let boundaryPrefix = "--"
    static var boundary: String {
        return UUID().uuidString
    }
}


