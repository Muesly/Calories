//
//  ContentView.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftUI
import CoreData

struct CaloriesView: View {
    private let viewModel: CaloriesViewModel

    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAlert = false
    @State private var totalCaloriesConsumed = 0.0
    @State private var isShowingFailureToAuthoriseAlert = false
    @State private var foodDescription: String = ""
    @State private var calories: Int = 0
    @State var timeConsumed: Date = Date()

    init(viewModel: CaloriesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Food", text: $foodDescription)
                    TextField("Calories", value: $calories, formatter: NumberFormatter())
                }
                DatePicker("Time consumed", selection: $timeConsumed, displayedComponents: .hourAndMinute)

                Button {
                    Task {
                        do {
                            try await viewModel.addFood(foodDescription: foodDescription,
                                                        calories: calories,
                                                        timeConsumed: timeConsumed)
                            totalCaloriesConsumed = try await viewModel.totalCaloriesConsumed()
                        } catch {
                            isShowingFailureToAuthoriseAlert = true
                        }
                    }
                } label: {
                    Text("Add")
                }
                Text("\(totalCaloriesConsumed) total calories consumed")
                List {
                    ForEach(viewModel.foodEntries) { foodEntry in
                        NavigationLink {
                            Text("Item at \(foodEntry.timeConsumed!, formatter: itemFormatter)")
                        } label: {
                            Text("\(foodEntry.timeConsumed ?? Date(), formatter: itemFormatter) / \(foodEntry.foodDescription) / \(foodEntry.calories)")
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Calories")
            .onAppear() {
                Task {
                    totalCaloriesConsumed = try await viewModel.totalCaloriesConsumed()
                }
            }
            .alert("Failed to access vehicle health",
                   isPresented: $isShowingFailureToAuthoriseAlert) {
                Button("OK", role: .cancel) {}
            }
            Text("Select an item")
        }
    }

    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { viewModel.foodEntries[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
