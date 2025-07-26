//
//  BBCodeContext.swift
//  BBCode
//
//  Created by 显卡的香气 on 2025/7/26.
//

public final class BBCodeContext {
    @MainActor public static let shared = BBCodeContext()
    
    public let image = ImageContext()
}
