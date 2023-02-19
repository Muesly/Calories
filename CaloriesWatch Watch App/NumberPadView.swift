//
//  NumberPadView.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 18/02/2023.
//

import SwiftUI

struct NumberPadView: View {
    @Environment(\.dismiss) var dismiss
    @State var numberStr: String = "0"
    @Binding var number: Int

    init(number: Binding<Int>) {
        self._number = number
    }

    var body: some View {
        VStack {
            Text(numberStr)
                .padding(10)
            HStack {
                NumberButtonView(number: 1, numberStr: $numberStr)
                NumberButtonView(number: 2, numberStr: $numberStr)
                NumberButtonView(number: 3, numberStr: $numberStr)
            }
            HStack {
                NumberButtonView(number: 4, numberStr: $numberStr)
                NumberButtonView(number: 5, numberStr: $numberStr)
                NumberButtonView(number: 6, numberStr: $numberStr)
            }
            HStack {
                NumberButtonView(number: 7, numberStr: $numberStr)
                NumberButtonView(number: 8, numberStr: $numberStr)
                NumberButtonView(number: 9, numberStr: $numberStr)
            }
            HStack {
                Button {
                    delete()
                } label: {
                    Text("Del")
                        .padding(2)
                }.buttonStyle(NumberPadButtonStyle())

                NumberButtonView(number: 0, numberStr: $numberStr)
                Button {
                    submit()
                } label: {
                    Text("Sub").foregroundColor(Color.black)
                        .padding(2)
                }
                .buttonStyle(NumberPadButtonStyle(backgroundColour: Color.green))
            }
        }
        .padding(10)
    }

    private func delete() {
        numberStr.removeLast()
        if numberStr.isEmpty {
            numberStr = "0"
        }
    }

    private func submit() {
        let nf = NumberFormatter()
        number = (nf.number(from: numberStr) ?? 0).intValue
        print(number)
        dismiss()
    }
}

struct NumberButtonView: View {
    var number: Int = 0
    @Binding var numberStr: String

    var body: some View {
        Button {
            addNumber(number)
        } label: {
            Text("\(number)").font(.brand)
                .padding(2)
        }
        .buttonStyle(NumberPadButtonStyle())
    }

    private func addNumber(_ number: Int) {
        if numberStr == "0" {
            numberStr = ""
        }
        numberStr.append("\(number)")
    }
}

struct NumberPadButtonStyle: ButtonStyle {
    let backgroundColour: Color

    init(backgroundColour: Color = Colours.backgroundSecondary) {
        self.backgroundColour = backgroundColour
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColour)
            .cornerRadius(10)
            .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
    }
}
