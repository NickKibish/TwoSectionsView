//
//  ContentView.swift
//  StickyView
//
//  Created by Nick Kibysh on 01/07/2024.
//

import SwiftUI

struct ContainerView<Content: View>: View {
    let content: () -> Content
    @EnvironmentObject var presenter: ModalPresenter
    
    init(content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        SwiftUI.EmptyView()
            .onAppear {
                presenter.sheet {
                    content()
                }
            }
            .modalPresenter(presenter)
    }
}

struct StyledText: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = Color(.systemBackground)) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
        }
        .padding()
        .background(color.opacity(0.3))
        .cornerRadius(10)
    }
}

struct SubContentView: View {
    @State var text: String = ""
    
    var body: some View {
        VStack {
            TwoSectionScrollView {
                VStack {
                    StyledText("This is the top section", color: .yellow)
                    StyledText("This is the top section", color: .yellow)
                    StyledText("This is the top section", color: .yellow)
                    StyledText("This is the top section", color: .yellow)
                    StyledText("This is the top section", color: .yellow)
                    StyledText("This is the top section", color: .yellow)
                }
                .background(Color.red)
            } bottom: {
                VStack {
                    Button("Button To Click") { }
                    StyledText("This is 2 line bottom section\nwith a new line character", color: .blue)
                    if #available(iOS 15.0, *) {
                        TextField(text: $text) {
                            Text("Enter the text")
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            .padding()

            Button("Action Button") { }
                .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct ContentView: View {
    @ObservedObject var presenter = ModalPresenter()
    
    var body: some View {
        Button("Show Content") {
            presenter.sheet(style: .full) {
                SubContentView()
                    .environmentObject(presenter)
            }
        }
        .modalPresenter(presenter)
    }
}

@available(iOS 17, *)
#Preview("", traits: .sizeThatFitsLayout) {
    ContentView()
}
