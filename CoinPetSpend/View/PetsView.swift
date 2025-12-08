//
//  PetsView.swift
//  CoinPetSpend
//
//  Created by Алексей Авер on 08.12.2025.
//

import SwiftUI

struct PetsView: View {
    @EnvironmentObject private var store: PetStore
    
    @State private var showAdd = false
    
    private let buttonHorizontalPadding: CGFloat = 69
    private let buttonOffsetFromBottom: CGFloat = 28
    private let buttonHeight: CGFloat = 60
    
    private var contentBottomPadding: CGFloat {
        buttonHeight + buttonOffsetFromBottom + 16
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavigationBar(title: "MY PETS", onBack: nil, onMore: nil)
                
                ZStack {
                    if store.pets.isEmpty {
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Text("NO PETS ADDED")
                                    .appFont(.arialBold, size: 24)
                                    .foregroundColor(.appAccentYellow)
                                
                                Text("Add a new pet to see statistics and limits")
                                    .appFont(.agText, size: 18)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                        .padding(.bottom, contentBottomPadding)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(store.pets) { pet in
                                    PetCardView(pet: pet)
                                        .environmentObject(store)
                                }
                            }
                            .padding(.top, 12)
                            .padding(.horizontal, 16)
                            .padding(.bottom, contentBottomPadding)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            PrimaryActionButton(title: "Add A Pet") {
                showAdd.toggle()
            }
            .frame(height: buttonHeight)
            .padding(.horizontal, buttonHorizontalPadding)
            .padding(.bottom, buttonOffsetFromBottom)
        }
        .navigationDestination(isPresented: $showAdd) {
            AddPetView()
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        
    }
}


#Preview("With") {
    NavigationStack {
        PetsView()
            .environmentObject(PetStore.preview)
    }
}

#Preview("Empty") {
    NavigationStack {
        PetsView()
            .environmentObject(PetStore())
    }
}
