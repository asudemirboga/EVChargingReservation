//
//  MainTabView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 22.03.2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var showMenu = false

    

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {

                TabView {
                    MapScreen()
                        .tabItem { Label("Map", systemImage: "map") }

                    BestSlotView()
                        .tabItem { Label("Explore", systemImage: "bolt.fill") }

                    UserReservationsView()
                        .tabItem { Label("Profile", systemImage: "person") }
                }
                .disabled(showMenu) 
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showMenu.toggle() }) {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }



                
                if showMenu {
                    SideMenuView()
                        .frame(width: 250)
                        .transition(.move(edge: .leading))
                        .zIndex(1)

                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showMenu = false
                            }
                        }
                }
            }
            .navigationTitle("")
        }
    }
}



