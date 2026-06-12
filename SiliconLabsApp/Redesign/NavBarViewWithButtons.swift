//
//  NavBarViewWithButtons.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI
import Introspect

struct NavBarViewWithButtons<Content : View, Buttons : View>: View {
    let title : String
    let innerView: Content
    let trailingInNavBar : Buttons
    let lineColor: Color
    
    init(title : String, lineColor: Color = Color.appPrimaryBrand, @ViewBuilder innerView: () -> Content, @ViewBuilder trailingInNavBar : () -> Buttons ){
        self.title = title
        self.lineColor = lineColor
        self.innerView = innerView()
        self.trailingInNavBar = trailingInNavBar()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if lineColor != .clear {
                    Rectangle()
                        .fill(lineColor)
                        .frame(height: 1)
                }
                innerView
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarItems(leading: Text(title).font(.custom("Stolzl-Medium", size: 17)).foregroundColor(.white) ,trailing:
                trailingInNavBar
            )
        }.navigationViewStyle(.stack)
            .accentColor(.white)
            .introspectNavigationController { navigationController in
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.appNavigationPrimary
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.stolzlMedium(size: 17) as Any
                ]
                appearance.shadowColor = .clear
                appearance.shadowImage = UIImage()
                
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.compactAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
                navigationController.navigationBar.tintColor = .white
            }
    }
}

struct NavBarViewWithButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavBarViewWithButtons(title: "", innerView: {
        }, trailingInNavBar: {HStack {
            Button(action: {
                print("Icon pressed...")
            }) {
                Image(systemName: "person.crop.circle").imageScale(.large)
            }
        
            Button(action: {
                print("Icon pressed...")
            }) {
                Image(systemName: "person.crop.circle").imageScale(.large)
            }
        }})
    }
}
