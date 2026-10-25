//
//  EditorWithPreview.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

/// A form next to a phone preview, or above it where there's no room for both side by
/// side (an iPhone, or a narrow iPad window).
struct EditorWithPreview<Editor: View, Preview: View>: View {

    var editorMinWidth: CGFloat = 380
    @ViewBuilder let editor: Editor
    @ViewBuilder let preview: Preview

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var stacksVertically: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        let layout = stacksVertically
            ? AnyLayout(VStackLayout(spacing: 32))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 40))

        layout {
            editor
                .frame(minWidth: stacksVertically ? nil : editorMinWidth, maxWidth: 580)
            preview
        }
        .padding(stacksVertically ? 16 : 32)
        .frame(maxWidth: .infinity)
    }
}
