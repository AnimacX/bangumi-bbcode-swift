import SwiftUI

enum MaskTextColor: Int {
    case show = 0xFFFFFF
    case hide = 0x555555

    var color: Color {
        Color(hex: rawValue)
    }
}

struct MaskView<Content: View>: View {
    let inner: () -> Content

    @State private var revealed: Bool = false

    init(@ViewBuilder inner: @escaping () -> Content) {
        self.inner = inner
    }

    var body: some View {
        inner()
            .foregroundColor(revealed ? .primary : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: MaskTextColor.hide.rawValue))
                    .opacity(revealed ? 0 : 1)
            )
            .animation(.default, value: revealed)
            .contentShape(Rectangle())
            .onTapGesture {
                revealed = true
            }
            .onHover { hovering in
                guard BBCodeContext.shared.mask.enableHovering else { return }
                revealed = hovering
            }
    }
}
