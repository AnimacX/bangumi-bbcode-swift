import SwiftUI

extension BBCode {
    @MainActor
    func text(_ bbcode: String, args: [String: Any]? = nil) -> TextView {
        let worker: Worker = Worker(tagManager: tagManager)
        if let tree = worker.parse(bbcode) {
            handleTextNewlines(node: tree, tagManager: tagManager)
            if let render = textRenders[tree.type] {
                let content = render(tree, args)
                return content
            }
        }
        return .string(AttributedString(bbcode))
    }
}

extension Node {
    @MainActor
    func renderInnerText(_ args: [String: Any]?) -> TextView {
        var views: [AnyView] = []
        var texts: [Text] = []
        var strings: [AttributedString] = []
        for n in children {
            if let render = textRenders[n.type] {
                let content = render(n, args)
                switch content {
                case let .string(content):
                    strings.append(content)
                case let .text(content):
                    if !strings.isEmpty {
                        texts.append(Text(strings.reduce(AttributedString(), +)))
                        strings.removeAll()
                    }
                    texts.append(content)
                case let .view(content, _):
                    if !strings.isEmpty {
                        texts.append(Text(strings.reduce(AttributedString(), +)))
                        strings.removeAll()
                    }
                    if !texts.isEmpty {
                        views.append(AnyView(texts.reduce(Text(""), +)))
                        texts.removeAll()
                    }
                    views.append(content)
                }
            }
        }
        if views.count > 0 {
            if !strings.isEmpty {
                texts.append(Text(strings.reduce(AttributedString(), +)))
                strings.removeAll()
            }
            if !texts.isEmpty {
                views.append(AnyView(texts.reduce(Text(""), +)))
                texts.removeAll()
            }
            return .view(
                AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(views.indices, id: \.self) { i in
                            views[i]
                        }
                    }
                )
            )
        } else if texts.count > 0 {
            if !strings.isEmpty {
                texts.append(Text(strings.reduce(AttributedString(), +)))
                strings.removeAll()
            }
            return .text(texts.reduce(Text(""), +))
        } else if strings.count > 0 {
            return .string(strings.reduce(AttributedString(), +))
        } else {
            return .string(AttributedString())
        }
    }
}

@MainActor
var textRenders: [BBType: TextRender] {
    let inQuoteKey = "inQuote";
    
    return [
        .plain: { (n: Node, _: [String: Any]?) in
                .string(AttributedString(n.value))
        },
        .br: { (_: Node, _: [String: Any]?) in
                .string(AttributedString("\n"))
        },
        .paragraphStart: { (_: Node, _: [String: Any]?) in
                .string(AttributedString(""))
        },
        .paragraphEnd: { (_: Node, _: [String: Any]?) in
                .string(AttributedString(""))
        },
        .background: { (_: Node, _: [String: Any]?) in
                .string(AttributedString(""))
        },
        .avatar: { (_: Node, _: [String: Any]?) in
                .string(AttributedString(""))
        },
        .float: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case let .string(content):
                return .string(content)
            case let .text(content):
                return .text(content)
            case let .view(content, _):
                return .view(content)
            }
        },
        .root: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case let .string(content):
                return .string(content)
            case let .text(content):
                return .text(content)
            case let .view(content, _):
                return .view(content)
            }
        },
        .list: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            return .view(
                AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                        inner
                    }.padding(.leading, 12)
                )
            )
        },
        .listitem: { (n: Node, args: [String: Any]?) in
            switch n.renderInnerText(args) {
            case let .string(content):
                return .text(Text("• \(content)"))
            case let .text(content):
                return .text(Text("• ") + content)
            case .view:
                return .text(Text("• "))
            }
        },
        .center: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            return .view(
                AnyView(
                    VStack(alignment: .center, spacing: 0) {
                        inner.multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity, alignment: .center)
                )
            )
        },
        .left: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            return .view(
                AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                        inner.multilineTextAlignment(.leading)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                )
            )
        },
        .right: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            return .view(
                AnyView(
                    VStack(alignment: .trailing, spacing: 0) {
                        inner.multilineTextAlignment(.trailing)
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                )
            )
        },
        .align: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            switch n.attr.lowercased() {
            case "left":
                return .view(
                    AnyView(
                        VStack(alignment: .leading, spacing: 0) {
                            inner
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    )
                )
            case "right":
                return .view(
                    AnyView(
                        VStack(alignment: .trailing, spacing: 0) {
                            inner
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                    )
                )
            case "center":
                return .view(
                    AnyView(
                        VStack(alignment: .center, spacing: 0) {
                            inner
                        }.frame(maxWidth: .infinity, alignment: .center)
                    )
                )
            default:
                return .view(inner)
            }
        },
        .code: { (n: Node, args: [String: Any]?) in
            var inner: AnyView = AnyView(Text(""))
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = AnyView(Text(content))
            case let .text(content):
                inner = AnyView(content)
            case let .view(content, _):
                inner = content
            }
            return .view(
                AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                        inner
                            .font(.system(.footnote, design: .monospaced))
                            .padding(.horizontal, 12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            }
                    }.padding(.vertical, 8)
                )
            )
        },
        .quote: { (n: Node, args: [String: Any]?) in
            var before = AttributedString("\u{201C} ")
            before.foregroundColor = .secondary.opacity(0.5)
            var after = AttributedString(" \u{201D}")
            after.foregroundColor = .secondary.opacity(0.5)
            var innerArgs = args ?? [:]
            innerArgs[inQuoteKey] = true
            switch n.renderInnerText(innerArgs) {
            case let .string(content):
                var inner = AttributedString(content.characters.filter({ !$0.isNewline }))
                inner.foregroundColor = .secondary
                return .view(
                    AnyView(
                        VStack(alignment: .leading, spacing: 0) {
                            Text(before + inner + after)
                        }
                        .padding(.bottom, 2.5)
                    )
                )
            case let .text(content):
                let inner = content.foregroundColor(.secondary)
                
                return .view(
                    AnyView(
                        VStack(alignment: .leading, spacing: 0) {
                            Text(before) + inner + Text(after)
                        }
                        .padding(.bottom, 2.5)
                    )
                )
            case let .view(content, _):
                return .view(
                    AnyView(
                        HStack(alignment: .top, spacing: 4) {
                            Text(before)
                            content.foregroundStyle(.secondary)
                            Text(after)
                        }
                        .padding(.bottom, 2.5)
                    )
                )
            }
        },
        .subject: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            var subjectID = n.attr
            if subjectID.isEmpty {
                switch n.renderInnerText(args) {
                case let .string(content):
                    subjectID = String(content.characters)
                default:
                    return .string(AttributedString(n.value))
                }
            }
            let url = "https://bgm.tv/subject/\(subjectID)"
            guard let link = URL(string: url) else {
                switch inner {
                case let .string(content):
                    return .string(content)
                case let .text(content):
                    return .text(content)
                case let .view(content, _):
                    return .view(content)
                }
            }
            switch inner {
            case var .string(content):
                content.link = link
                content.foregroundColor = Color(hex: 0x0084B4)
                return .string(content)
            case let .text(content):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            case let .view(content, _):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            }
        },
        .user: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            var username = n.attr
            if username.isEmpty {
                switch n.renderInnerText(args) {
                case let .string(content):
                    username = String(content.characters)
                default:
                    return .string(AttributedString(n.value))
                }
            }
            let url = "https://bgm.tv/user/\(username)"
            guard let link = URL(string: url) else {
                switch inner {
                case let .string(content):
                    return .string(content)
                case let .text(content):
                    return .text(content)
                case let .view(content, _):
                    return .view(content)
                }
            }
            switch inner {
            case var .string(content):
                content = "@" + content
                content.link = link
                content.foregroundColor = Color(hex: 0x0084B4)
                return .string(content)
            case let .text(content):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            Text("@") + content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            case let .view(content, _):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            }
        },
        .url: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            var url = n.attr
            if url.isEmpty {
                switch n.renderInnerText(args) {
                case let .string(content):
                    url = String(content.characters)
                default:
                    return .string(AttributedString(n.value))
                }
            }
            guard let link = URL(string: url) else {
                switch inner {
                case let .string(content):
                    return .string(content)
                case let .text(content):
                    return .text(content)
                case let .view(content, _):
                    return .view(content)
                }
            }
            switch inner {
            case var .string(content):
                content.link = link
                content.foregroundColor = Color(hex: 0x0084B4)
                return .string(content)
            case let .text(content):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            case let .view(content, _):
                return .view(
                    AnyView(
                        Link(destination: link) {
                            content
                        }.foregroundStyle(Color(hex: 0x0084B4))
                    )
                )
            }
        },
        .image: { (n: Node, args: [String: Any]?) in
            if let inQuote = args?[inQuoteKey] as? Bool, inQuote {
                return .text(Text(""))
            }
            switch n.renderInnerText(args) {
            case let .string(content):
                let url = String(content.characters)
                guard let link = URL(string: url) else {
                    return .string(AttributedString(n.value))
                }
                let allowed = [
                    "avif", "avifs", "svg",
                    "gif", "png", "jpg", "jpeg",
                    "webp", "heic", "heif", "jxl",
                ]
                let ext = url.split(separator: ".").last?.lowercased() ?? "unknown"
                if !allowed.contains(ext) {
                    var content = AttributedString(url + "\n")
                    content.link = link
                    return .string(content)
                }
                let size = n.attr.split(separator: ",")
                if size.count == 2 {
                    let width = Int(size[0]) ?? 0
                    let height = Int(size[1]) ?? 0
                    if width > 0 && height > 0 {
                        return .view(
                            AnyView(
                                ImageView(url: link)
                                    .frame(maxWidth: CGFloat(width), maxHeight: CGFloat(height))
                            ),
                            .image
                        )
                    }
                }
                return .view(AnyView(ImageView(url: link)), .image)
            default:
                return .string(AttributedString(n.value))
            }
        },
        .photo: { (n: Node, args: [String: Any]?) in
            var url = "https://lain.bgm.tv/pic/photo/l/"
            switch n.renderInnerText(args) {
            case let .string(content):
                url += String(content.characters)
            default:
                return .string(AttributedString(n.value))
            }
            guard let link = URL(string: url) else {
                return .string(AttributedString(n.value))
            }
            return .view(AnyView(ImageView(url: link)))
        },
        .bold: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case var .string(content):
                if let font = content.font {
                    content.font = font.bold()
                } else {
                    content.font = .body.bold()
                }
                return .string(content)
            case let .text(content):
                return .text(content.bold())
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.bold()
                    )
                )
            }
        },
        .italic: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case var .string(content):
                if let font = content.font {
                    content.font = font.italic()
                } else {
                    content.font = .body.italic()
                }
                return .string(content)
            case let .text(content):
                return .text(content.italic())
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.italic()
                    )
                )
            }
        },
        .underline: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case var .string(content):
                content.underlineStyle = .single
                return .string(content)
            case let .text(content):
                return .text(content.underline())
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.underline()
                    )
                )
            }
        },
        .delete: { (n: Node, args: [String: Any]?) in
            let inner = n.renderInnerText(args)
            switch inner {
            case var .string(content):
                content.strikethroughStyle = .single
                return .string(content)
            case let .text(content):
                return .text(content.strikethrough())
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.strikethrough()
                    )
                )
            }
        },
        .color: { (n: Node, args: [String: Any]?) in
            if n.attr.isEmpty {
                return n.renderInnerText(args)
            }
            guard let color = Color(n.attr) else {
                return n.renderInnerText(args)
            }
            switch n.renderInnerText(args) {
            case var .string(content):
                content.foregroundColor = color
                return .string(content)
            case let .text(content):
                return .text(content.foregroundColor(color))
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.foregroundColor(color)
                    )
                )
            }
        },
        .size: { (n: Node, args: [String: Any]?) in
            if n.attr.isEmpty {
                return n.renderInnerText(args)
            }
            guard var size = Int(n.attr) else {
                return n.renderInnerText(args)
            }
            if size < 8 {
                size = 8
            }
            if size > 50 {
                size = 50
            }
            switch n.renderInnerText(args) {
            case var .string(content):
                // FIXME: preserve inner font style
                content.font = .system(size: CGFloat(size))
                return .string(content)
            case let .text(content):
                return .text(content.font(.system(size: CGFloat(size))))
            case let .view(content, _):
                return .view(
                    AnyView(
                        content.font(.system(size: CGFloat(size)))
                    )
                )
            }
        },
        .mask: { (n: Node, args: [String: Any]?) in
            if let inQuote = args?[inQuoteKey] as? Bool, inQuote {
                return .text(Text(""))
            }
            var inner: Text = Text("")
            switch n.renderInnerText(args) {
            case let .string(content):
                inner = Text(content)
            case let .text(content):
                inner = content
            case .view:
                inner = Text("")
            }
            return .view(
                AnyView(
                    MaskView {
                        inner
                    }
                ), .mask
            )
        },
        .smilies: { (n: Node, args: [String: Any]?) in
            if let inQuote = args?[inQuoteKey] as? Bool, inQuote {
                return .text(Text(""))
            }
            let img = Image(packageResource: "bgm\(n.attr)", ofType: "gif")
            return .text(Text(img))
        },
    ]
}

func handleTextNewlines(node: Node, tagManager: TagManager) {
    // Trim head "br"s
    while node.children.first?.type == .br {
        node.children.removeFirst()
    }
    // Trim tail "br"s
    while node.children.last?.type == .br {
        node.children.removeLast()
    }
    
    var previous: Node?
    for n in node.children {
        if n.type == .br {
            if previous?.description?.isBlock ?? false {
                n.setTag(tag: tagManager.getInfo(type: .plain)!)
                previous = nil
                handleNewlineAndParagraph(node: n, tagManager: tagManager)
            } else {
                previous = n
            }
        } else {
            previous = n
        }
    }
}
