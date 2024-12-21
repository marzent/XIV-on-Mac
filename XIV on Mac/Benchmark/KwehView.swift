//
//  KwehView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 4/17/24.
//

import SwiftUI

struct KwehView: View {
    private let chocoWalkTimer = Timer.publish(
        every: 0.2, on: .main, in: .common
    ).autoconnect()
    var chocoWalkUnits: CGFloat = 100
    var chocoFence: CGFloat = 1000
    @State var chocoWalkFrame: UInt = 0
    @State var chocoWalkOffset: CGFloat = 0
    @State var chocoFacing: Bool = false  // false = left, true = right

    var body: some View {
        GeometryReader { geometry in
            Image(
                nsImage: NSImage(
                    named: chocoWalkFrame == 0 ? "ChocoboWalk1" : "ChocoboWalk2"
                )!
            )
            .aspectRatio(contentMode: .fit)
            .onReceive(self.chocoWalkTimer) { _ in
                chocoWalkFrame = (chocoWalkFrame + 1) % 2

                // Turn around if we've hit a boundary
                if !chocoFacing && chocoWalkOffset < (chocoFence * -1) {
                    chocoFacing = true
                    return
                } else if chocoFacing && chocoWalkOffset >= chocoFence {
                    chocoFacing = false
                    return
                }
                if !chocoFacing {
                    chocoWalkOffset -= chocoWalkUnits
                } else {
                    chocoWalkOffset += chocoWalkUnits
                }
            }
            // Flip the Chocobo image to face the other way if needed
            .transformEffect(
                CGAffineTransform(scaleX: chocoFacing ? -1 : 1, y: 1)
            )
            .offset(x: (chocoFacing ? 128 : 0) + chocoWalkOffset)

        }
    }
}

#Preview {
    KwehView()
}
