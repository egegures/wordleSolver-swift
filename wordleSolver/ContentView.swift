//
//  ContentView.swift
//  wordleSolver
//
//  Created by Ege Gures on 2024-09-23.
//

import SwiftUI

struct ContentView: View {
    @State var selectedLanguage: String = "Turkish"
    @State var includedLetters: String = ""
    @State var excludedLetters: String = ""
    @State var wordsCount: Int = 0
    
    @State var foundWords: [String] = []
    @State var suggestedWords: [String] = []
    
    @State var box0: String = ""
    @State var box1: String = ""
    @State var box2: String = ""
    @State var box3: String = ""
    @State var box4: String = ""
    
    @State var removeWord: String = ""
    @State var isWordRemoved: Bool = false
    @State var showMessage: Bool = false
    
    let languages: [String] = ["Turkish", "English"]
    
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case box0, box1, box2, box3, box4
    }
    
    
    var body: some View {
        
        let foundWordsString = Binding<String>(
            get: { foundWords.joined(separator: "\n") },
            set: { newValue in
                foundWords = newValue.components(separatedBy: "\n").filter { !$0.isEmpty }
            }
        )
        
        // TODO: Filter words with duplicate letters from suggested words
        let suggestedWordsString = Binding<String>(
            get: { suggestedWords.joined(separator: "\n") },
            set: { newValue in
                suggestedWords = newValue.components(separatedBy: "\n").filter { !$0.isEmpty }
            })
        
        VStack {
            Picker("", selection: $selectedLanguage) {
                ForEach(languages, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .frame(width: 150)
            .onChange(of: selectedLanguage) {
                clearFields()
            }
            HStack {
                OneCharTextField(text: $box0, nextFocus: $focusedField, currentFocus: .box0, nextFocusField: .box1)
                OneCharTextField(text: $box1, nextFocus: $focusedField, currentFocus: .box1, nextFocusField: .box2)
                OneCharTextField(text: $box2, nextFocus: $focusedField, currentFocus: .box2, nextFocusField: .box3)
                OneCharTextField(text: $box3, nextFocus: $focusedField, currentFocus: .box3, nextFocusField: .box4)
                OneCharTextField(text: $box4, nextFocus: $focusedField, currentFocus: .box4, nextFocusField: nil)
            }
            .onAppear {
                focusedField = .box1
            }
            Text("Included Letters (format: a:1,2 b:3)")
            TextField("", text: $includedLetters)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("Excluded letters (not comma separated)")
            TextField("", text: $excludedLetters)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                foundWords = filter()
                suggestedWords = filterSuggested()
            }, label: {
                Text("Filter Words")
            } )
            HStack {
                VStack {
                    Text("Words found: \(wordsCount)")
                    TextEditor(text: foundWordsString)
                        .frame(height: 200)
                        .disabled(true)
                }
                VStack {
                    Text("Suggested words")
                    TextEditor(text: suggestedWordsString)
                        .frame(height: 200)
                        .disabled(true)
                }
            }
            
            Button(action: {
                clearFields()
            }, label: {
                Text("Clear fields")
            })
            .padding(.bottom)
            HStack {
                TextField("", text: $removeWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                Button(action: {
                    removeWordFromList()
                }, label: {
                    Text("Remove word")
                })
            }
            if showMessage {
                if !isWordRemoved {
                    Text("Word is not in the list")
                        .foregroundColor(.red)
                } else {
                    Text("Word removed")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
    
    func filter() -> [String] {
        var list = readFromFile()
        let known: [String] = [box0, box1, box2, box3, box4].filter {
            return $0 != ""}
        let includedLetters: [Character: [Int]] = parseIncludedLetters(input: includedLetters)
        
        let includedKeys = Set(includedLetters.keys)
        let excludedLetters: [Character] = Array(excludedLetters).filter {
            return !includedKeys.contains($0) && !known.contains(String($0))
        }
        list = list.filter { word in //known letters
            let characters = Array(word)
            return (box0.isEmpty || box0 == String(characters[0])) &&
            (box1.isEmpty || box1 == String(characters[1])) &&
            (box2.isEmpty || box2 == String(characters[2])) &&
            (box3.isEmpty || box3 == String(characters[3])) &&
            (box4.isEmpty || box4 == String(characters[4]))
        }
        list = list.filter { word in //excluded letters
            return excludedLetters.allSatisfy { !Array(word).contains($0) }
        }
        list = list.filter { word in //included letters
            return includedKeys.allSatisfy { Array(word).contains($0) }
        }
        list = list.filter { word in //remove included letters from excluded positions
            let characters = Array(word)
            for (letter, excludedPositions) in includedLetters {
                for position in excludedPositions {
                    if position - 1 >= 0 &&
                        position - 1 < characters.count &&
                        characters[position - 1] == letter {
                        return false
                    }
                }
            }
            return true
        }
        wordsCount = list.count
        return list
    }
    func filterSuggested() -> [String] {
        var list = readFromFile()
        let known: [String] = [box0, box1, box2, box3, box4].filter {
            return $0 != ""}
        let includedLetters: [Character: [Int]] = parseIncludedLetters(input: includedLetters)
        
        let includedKeys = Set(includedLetters.keys)
        let excludedLetters: [Character] = Array(excludedLetters).filter {
            return !includedKeys.contains($0) && !known.contains(String($0))
        }
        var allExcluded: [Character] = []
        
        for c in known {
            let char = Array(c)
            allExcluded.append(contentsOf: char)
        }
        for key in includedKeys {
            allExcluded.append(key)
        }
        allExcluded.append(contentsOf: excludedLetters)
        
        list = list.filter { word in
            return allExcluded.allSatisfy { !Array(word).contains($0) }
        }
        list = list.filter { word in
            return word.count == Set(Array(word)).count
        }
        return list
    }
    func readFromFile() -> [String] {
        print("reading from file")
        guard let fileURL = Bundle.main.path(forResource: "\(selectedLanguage.localizedLowercase)_cleaned", ofType: "txt") else {
            print("failed guard")
            return []
        }
        do {
            let contents = try String(contentsOfFile: fileURL, encoding: .utf8)
            let words = contents.components(separatedBy: CharacterSet.newlines).filter({!$0.isEmpty})
            return words
        }
        catch {
            print("Error reading file \(fileURL) : \(error.localizedDescription)")
            return []
        }
    }
    
    func writeToFile(list: [String]) -> Bool {
        guard let fileURL = Bundle.main.path(forResource: "\(selectedLanguage.localizedLowercase)_cleaned", ofType: "txt") else {
                print("File path not found.")
                return false
            }
            
            let updatedContents = list.joined(separator: "\n")
            
            do {
                try updatedContents.write(toFile: fileURL, atomically: true, encoding: .utf8)
                return true
            } catch {
                print("Error writing to file: \(error.localizedDescription)")
                return false
            }
    }
    func parseIncludedLetters(input: String) -> [Character: [Int]] {
        var includedLetters: [Character: [Int]] = [:]
        
        let conditions = input.split(separator: " ")
        for condition in conditions {
            let parts = condition.split(separator: ":")
            let letter = Character(String(parts[0]))
            let countString = parts[1]
            if let count = Int(countString) {
                includedLetters[letter] = Array(arrayLiteral: count)
            } else {
                let counts = countString.split(separator: ",")
                for count in counts {
                    if let count = Int(count) {
                        includedLetters[letter, default: []].append(count)
                    }
                }
            }
        }
        return includedLetters
    }
    
    func removeWordFromList() {
        var list = readFromFile()
        if let index = list.firstIndex(of: removeWord) {
            list.remove(at: index)
            isWordRemoved = writeToFile(list: list)
        } else {
            isWordRemoved = false
        }
        showMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showMessage = false
        }
    }
    
    func clearFields() {
        includedLetters = ""
        excludedLetters = ""
        box0 = ""
        box1 = ""
        box2 = ""
        box3 = ""
        box4 = ""
        foundWords = []
        suggestedWords = []
        wordsCount = 0
    }
    
}

struct OneCharTextField: View {
    @Binding var text: String
    var nextFocus: FocusState<ContentView.FocusField?>.Binding
    var currentFocus: ContentView.FocusField
    var nextFocusField: ContentView.FocusField?
    
    var body: some View {
        TextField("", text: $text)
            .focused(nextFocus, equals: currentFocus)
            .onChange(of: text) {
                if text.count > 1 {
                    text = String(text.prefix(1))  // Limit to 1 character
                }
                if !text.isEmpty {
                    nextFocus.wrappedValue = nextFocusField // Move to the next field
                }
            }
            .frame(width: 40, height: 40)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
    }
}



#Preview {
    ContentView()
}
