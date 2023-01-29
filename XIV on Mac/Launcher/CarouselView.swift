//
//  CarouselView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/16/23.
//

import SwiftUI

struct CarouselView<Content>: View where Content: View {
    @Binding var index: Int
    let maxIndex: Int
    let content: () -> Content
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    @State private var offset = CGFloat.zero
    @State private var dragging = false

    init(index: Binding<Int>, maxIndex: Int, @ViewBuilder content: @escaping () -> Content) {
        self._index = index
        self.maxIndex = maxIndex
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        self.content()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                }
                .content.offset(x: self.offset(in: geometry), y: 0)
                .frame(width: geometry.size.width, alignment: .leading)
                .gesture(
                    DragGesture().onChanged { value in
                        self.dragging = true
                        self.offset = -CGFloat(self.index) * geometry.size.width + value.translation.width
                    }
                    .onEnded { value in
                        let predictedEndOffset = -CGFloat(self.index) * geometry.size.width + value.predictedEndTranslation.width
                        let predictedIndex = Int(round(predictedEndOffset / -geometry.size.width))
                        self.index = self.clampedIndex(from: predictedIndex)
                        withAnimation(.easeOut) {
                            self.dragging = false
                        }
                    }
                )
            }
            .clipped()

            ItemControl(index: $index, maxIndex: maxIndex)
                .onReceive(self.timer) { _ in
                    if maxIndex > 0 {
                        self.index = (self.index + 1) % maxIndex
                    }
                }
        }
    }

    func offset(in geometry: GeometryProxy) -> CGFloat {
        if self.dragging {
            return max(min(self.offset, 0), -CGFloat(self.maxIndex) * geometry.size.width)
        }
        else {
            return -CGFloat(self.index) * geometry.size.width
        }
    }

    func clampedIndex(from predictedIndex: Int) -> Int {
        let newIndex = min(max(predictedIndex, self.index - 1), self.index + 1)
        guard newIndex >= 0 else { return 0 }
        guard newIndex <= self.maxIndex else { return self.maxIndex }
        return newIndex
    }
}

struct ItemControl: View {
    @Binding var index: Int
    let maxIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< maxIndex, id: \.self) { index in
                Circle()
                    .strokeBorder(Color.black, lineWidth: 1)
                    .background(Circle().foregroundColor(index == self.index ? Color.white : Color.gray))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(15)
    }
}
