//
//  ContentView.swift
//  TestApp
//
//  Created by Vitalie Bancu on 26.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isMenuVisible = false
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .leading) {
                ClockView()
                    .disabled(isMenuVisible)
                    .blur(radius: isMenuVisible ? 1 : 0)
                    .overlay {
                        if isMenuVisible {
                            Color.black.opacity(0.25)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        isMenuVisible = false
                                    }
                                }
                        }
                    }

                SideMenuView(
                    isVisible: $isMenuVisible,
                    onSelectCalculator: {
                        withAnimation(.easeInOut) {
                            isMenuVisible = false
                        }
                        path.append(.calculator)
                    },
                    onSelectClock: {
                        withAnimation(.easeInOut) {
                            isMenuVisible = false
                        }
                    }
                )
            }
            .navigationTitle("Ceas")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut) {
                            isMenuVisible.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Open menu")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .calculator:
                    CalculatorView()
                        .navigationTitle("Calculator")
                }
            }
        }
    }
}

private enum Route: Hashable {
    case calculator
}

private struct SideMenuView: View {
    @Binding var isVisible: Bool
    let onSelectCalculator: () -> Void
    let onSelectClock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meniu")
                .font(.headline)
                .padding(.top, 40)

            Button("Calculator", action: onSelectCalculator)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Ceas", action: onSelectClock)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(width: 260)
        .background(Color(.systemBackground))
        .offset(x: isVisible ? 0 : -260)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 2, y: 0)
        .animation(.easeInOut, value: isVisible)
    }
}

private struct ClockView: View {
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            Text(Self.timeFormatter.string(from: now))
                .font(.system(size: 56, weight: .bold, design: .rounded))

            Text(Self.dateFormatter.string(from: now))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onReceive(timer) { date in
            now = date
        }
    }
}

private struct CalculatorView: View {
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
