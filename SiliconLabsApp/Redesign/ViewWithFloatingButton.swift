//
//  ViewWithFloatingButton.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 30/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI
import UIKit

private enum ViewWithFloatingButtonMetrics {
    static let height: CGFloat = 50
    static let cornerRadius: CGFloat = 10
    static let horizontalPadding: CGFloat = 20
    static let titleSize: CGFloat = 14
}

struct ViewWithFloatingButton<MainContent : View>: View {
    let buttonTitle : String
    let buttonPresented : Bool
    let buttonAction : () -> ()
    let buttonColor : UIColor
    @ViewBuilder let mainBody : () -> MainContent
    
    var body: some View {
        ZStack {
            mainBody()
            if buttonPresented {
                ButtonView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding()
            }
        }
    }
    
    @ViewBuilder func ButtonView() -> some View {
        Button(action: buttonAction, label: {
            Text(buttonTitle)
                .font(Font(UIFont(name: "Stolzl-Medium", size: ViewWithFloatingButtonMetrics.titleSize)
                    ?? UIFont.systemFont(ofSize: ViewWithFloatingButtonMetrics.titleSize, weight: .medium)))
                .foregroundColor(.white)
                .padding(.horizontal, ViewWithFloatingButtonMetrics.horizontalPadding)
                .frame(height: ViewWithFloatingButtonMetrics.height)
                .background(RoundedRectangle(cornerRadius: ViewWithFloatingButtonMetrics.cornerRadius).fill(Color(buttonColor)))
        })
        .buttonStyle(.plain)
    }
    
}

struct ViewWithFloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        ViewWithFloatingButton(buttonTitle: "Create new", buttonPresented: true, buttonAction: {
            print("Akcja")
        }, buttonColor: .appPrimaryBrand, mainBody: {
            DemoView()
        })
    }
}
