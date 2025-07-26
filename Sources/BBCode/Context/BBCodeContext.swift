//
//  BBCodeContext.swift
//  BBCode
//
//  Created by 显卡的香气 on 2025/7/26.
//

class BBCodeContext {
    @MainActor static let shared = BBCodeContext()
    
    let image = ImageContext()
}
