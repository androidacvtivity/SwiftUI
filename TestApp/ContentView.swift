//
//  ContentView.swift
//  TestApp
//
//  Created by Vitalie Bancu on 26.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var displayText = "0"
    @State private var storedValue: Double? = nil
    @State private var pendingOperation: Operation? = nil
    @State private var shouldResetDisplay = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Simple Calculator")
                .font(.title2)
                .fontWeight(.semibold)

            Text(displayText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.black.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 12) {
                calculatorRow(["7", "8", "9", "+"])
                calculatorRow(["4", "5", "6", "-"])
                calculatorRow(["1", "2", "3", "×"])
                calculatorRow(["C", "0", "=", "÷"])
            }
        }
        .padding()
    }

    private func calculatorRow(_ labels: [String]) -> some View {
        HStack(spacing: 12) {
            ForEach(labels, id: \.self) { label in
                Button {
                    handleTap(label)
                } label: {
                    Text(label)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(backgroundColor(for: label))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func handleTap(_ label: String) {
        switch label {
        case "0"..."9":
            appendDigit(label)
        case "+", "-", "×", "÷":
            setOperation(label)
        case "=":
            evaluate()
        case "C":
            clearAll()
        default:
            break
        }
    }

    private func appendDigit(_ digit: String) {
        if shouldResetDisplay || displayText == "0" {
            displayText = digit
            shouldResetDisplay = false
        } else {
            displayText.append(digit)
        }
    }

    private func setOperation(_ symbol: String) {
        if let currentValue = Double(displayText) {
            if let existingOperation = pendingOperation, let storedValue {
                let result = existingOperation.apply(lhs: storedValue, rhs: currentValue)
                displayText = format(result)
                self.storedValue = result
            } else {
                storedValue = currentValue
            }
        }

        pendingOperation = Operation(symbol: symbol)
        shouldResetDisplay = true
    }

    private func evaluate() {
        guard let operation = pendingOperation,
              let storedValue,
              let currentValue = Double(displayText) else {
            return
        }

        let result = operation.apply(lhs: storedValue, rhs: currentValue)
        displayText = format(result)
        self.storedValue = nil
        pendingOperation = nil
        shouldResetDisplay = true
    }

    private func clearAll() {
        displayText = "0"
        storedValue = nil
        pendingOperation = nil
        shouldResetDisplay = false
    }

    private func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }

    private func backgroundColor(for label: String) -> Color {
        switch label {
        case "+", "-", "×", "÷", "=":
            return Color.orange
        case "C":
            return Color.red
        default:
            return Color.blue
        }
    }

    private struct Operation {
        let symbol: String

        func apply(lhs: Double, rhs: Double) -> Double {
            switch symbol {
            case "+":
                return lhs + rhs
            case "-":
                return lhs - rhs
            case "×":
                return lhs * rhs
            case "÷":
                return rhs == 0 ? 0 : lhs / rhs
            default:
                return rhs
            }
        }
    }
}

#Preview {
    ContentView()
}
