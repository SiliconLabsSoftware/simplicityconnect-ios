//
//  UnderlineSegmentedControl.swift
//  BlueGecko
//
//  Created for Silicon Labs Connect App.
//  Copyright © 2026 SiliconLabs. All rights reserved.
//

import SwiftUI

struct UnderlineSegmentedControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<titles.count, id: \.self) { index in
                    SegmentButton(
                        title: titles[index],
                        isSelected: selectedIndex == index
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                    }
                }
            }
        }
        .background(Color.appNavigationPrimary)
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 11))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UnderlineSegmentedControl_Previews: PreviewProvider {
    static var previews: some View {
        UnderlineSegmentedControl(
            selectedIndex: .constant(0),
            titles: ["SCANNER", "RSSI GRAPH", "(0) ACTIVE\nCONNECTIONS"]
        )
        .previewLayout(.sizeThatFits)
    }
}
