//
//  MainNavigationView.swift
//  MainNavigationView
//
//  Created by Anastazja Gradowska  on 21/06/2022.
//

import SwiftUI
import Introspect

struct MainNavigationView: View {
    @State var pickedTag = 0
    var body: some View {
        TabView(selection: $pickedTag) {
            DemoTab()
                .tabItem {
                    Image("demoTabIcon")
                    Text("Demo")
                }.tag(0)
            
            TestView()
                .tabItem {
                    Image("testTabIcon")
                    Text("Test")
                }.tag(1)
            
            ScanView()
                .tabItem {
                    Image("scanTabIcon")
                    Text("Scan")
                }.tag(2)
            
            ConfigureView()
                .tabItem {
                    Image( "configureTabIcon")
                    Text("Configure")
                }.tag(3)
            
            SettingsView()
                .tabItem {
                    Image("settingTabIcon")
                    Text("Settings")
                }.tag(4)
        }
        .padding(.bottom, 2)
        .tint(Color.appPrimaryBrand)
        .accentColor(Color.appPrimaryBrand)
        .edgesIgnoringSafeArea(.vertical)
        .introspectTabBarController { tabBarController in
            tabBarController.tabBar.tintColor = UIColor.appPrimaryBrand
            
            // Add red line on top of tab bar
            let topLine = UIView()
            topLine.backgroundColor = UIColor.appPrimaryBrand
            topLine.translatesAutoresizingMaskIntoConstraints = false
            topLine.tag = 999 // Tag to prevent duplicates
            
            // Remove existing line if any
            tabBarController.tabBar.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
            
            tabBarController.tabBar.addSubview(topLine)
            NSLayoutConstraint.activate([
                topLine.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
                topLine.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
                topLine.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor),
                topLine.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
    }
}

struct MainNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        
        MainNavigationView()
    }
}
