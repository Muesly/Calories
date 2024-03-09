//
//  AddPlantView.swift
//  Calories
//
//  Created by Tony Short on 14/01/2024.
//

import CoreData
import HealthKit
import SwiftUI

struct AddPlantView: View {
    private let viewModel: AddPlantEntryViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State var name: String
    @State var points: Int = 0
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var pointsIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    private let defName: String
    @Binding var searchText: String
    @Binding var plantAdded: Bool

    init(viewModel: AddPlantEntryViewModel,
         defName: String,
         searchText: Binding<String>,
         plantAdded: Binding<Bool>) {
        self.viewModel = viewModel
        self.defName = defName
        _searchText = searchText
        _name = State(initialValue: defName)
        _points = State(initialValue: 1)
        _plantAdded = plantAdded
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Food")
                    TextField("Enter plant, seed or herb...", text: $name)
                        .focused($descriptionIsFocused)
                        .padding(5)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                }
                VStack(alignment: .leading) {
                    Text("Points")
                    TextField("", value: $points, formatter: numberFormatter)
                        .frame(maxWidth: 60)
                        .focused($pointsIsFocused)
                        .keyboardType(.numberPad)
                        .padding(5)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                }
            }

            Button {
                Task(priority: .high) {
                    do {
                        descriptionIsFocused = false
                        pointsIsFocused = false
                        try await viewModel.addPlant(name: name, points: points)
                        name = ""
                        points = 1
                        searchText = ""
                        dismiss()
                        plantAdded = true
                    } catch {
                        isShowingFailureToAuthoriseAlert = true
                    }
                }
            } label: {
                Text("Add \(name)")
                    .padding(10)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty)
        }
        .padding()
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
        Spacer()
        .onChange(of: scenePhase) { newPhase in
            Task {
                name = ""
                points = 1
            }
        }
        .alert("Failed to access vehicle health",
               isPresented: $isShowingFailureToAuthoriseAlert) {
            Button("OK", role: .cancel) {}
        }
        .padding()
        .cornerRadius(10)
        .font(.brand)
    }
}

struct AddPlantView_Previews: PreviewProvider {
    static var previews: some View {
        AddPlantView(viewModel: AddPlantEntryViewModel(),
                     defName: "Banana",
                     searchText: .constant(""),
                     plantAdded: .constant(false))
    }
}

class AddPlantEntryViewModel {
    let container: NSPersistentContainer
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer = PersistenceController.shared.container) {
        self.healthStore = healthStore
        self.container = container
    }

    func setDateForEntries(_ date: Date) {
        dateForEntries = date
    }

    func addPlant(name: String, points: Int) async throws {
        try await healthStore.authorize()
        let _ = Plant(context: container.viewContext, name: name, points: Float(points))
        try container.viewContext.save()
    }
}
