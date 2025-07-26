//
//  ImageContext.swift
//  BBCode
//
//  Created by 显卡的香气 on 2025/7/26.
//
import Foundation

public final class ImageContext {
    public var enableContextMenu = true
    public var enableImagePreviewer = true
    public var delegateImagePreviwer = false
    public var imagePreviewerDelegate: (URL) -> Void = { _ in }
}
