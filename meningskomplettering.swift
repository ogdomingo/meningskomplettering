//
//  meningskomplettering.swift
//  GithubSamples
//
//  Created by Domos Szegi on 2026-10-08.
//

/*
 The code is divided into two parts:
 1. The actual SentenceView presented in the Exercise
 2. TextBox layout that places each word in the sentence
 */

// 1. SentenceView

struct SentenceView: View {
    @EnvironmentObject var viewModel: ExerciseViewModel

    var body: some View {
        if let sentence = viewModel.currentExerciseData.exerciseSentence {
            // 1. TextBox with the sentence data
            TextBox{
                // Hidden view of a single space for
                ForEach(sentence) { word in
                    if !word.isCorrect {
                        Text("\(word.word)")
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                    } else {
                        ZStack (alignment: .bottom) {
                            // Hidden button with the length of the longest word
                            Button(action: {
                                return
                            }, label: {
                                Text("\(viewModel.longestWord)")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                                    .padding(10)
                                    .background(.gray)
                            })
                            .zIndex(3)
                            .hidden()
                            Line()
                                .stroke(style: .init(dash: [4]))
                                .frame(height: 1)
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                        .padding(.horizontal, 5)
                    }
                }

                // Last element that is used to calculate the spacing is a space, and is hidden
                Text(" ")
                    .hidden()
            }
        } else {
            EmptyView()
        }
    }
}

// 2. TextBox

struct TextBox: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        return maxSize(subviews: subviews, proposal: proposal)
        
        // maxSize function
        func maxSize(subviews: Subviews, proposal: ProposedViewSize) -> CGSize {
            // Collects the subview sizes of each subview
            let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
            guard let parentWidth = proposal.width else { fatalError("Parent container did not pass down a valid proposed size") }
            
            // NEW CODE
            // Spacing will be the width of a " " (space glyph)
            let spacing = subviews[subviews.count - 1].sizeThatFits(.unspecified).width
            
            // find the tallest view among the subviews, and assign lineHeight to that
            let lineHeight: CGFloat = subviewSizes.reduce(0) { max($0, $1.height)}
            
            // Initialize currentHeight to the height of the first element
            var currentHeight: CGFloat = 0
            var currentWidth: CGFloat = 0
            
            //I will iterate over the subviewSizes, and try to add together the view sizes that are equal or less than the parentWidth, if that conditional evaluates to false, then, I update maxWidth before setting currentWidth, increment maxHeight with the line height
            for index in subviewSizes.indices.dropLast() {
                // Initialize currentHeight if this is the first subview
                if index < 1 {
                    currentHeight += lineHeight //TODO: check here if I need this or not * 2
                }
                 // Is there any more space for new views?
                if currentWidth == parentWidth || (currentWidth + subviewSizes[index].width + spacing ) > parentWidth {
                    // No, there isn't, so:
                    // Wrap to next line and add the element by
                    // 1. resetting the horizontal value of the next line to be 0
                    currentWidth = 0
                    
                    // 2. Adding the next line's height to the currentHeight by calling findLineHeight
                    currentHeight += lineHeight
                    
                    // 3. Add the element, by adding the width value to currentWidth (plus this view's spacing horizontally
                    currentWidth += subviewSizes[index].width + spacing
                    
                } else {
                    // Yes, there is, so:
                    // Add the next element by adding it's width + spacing to currentWidth
                    currentWidth += (subviewSizes[index].width + spacing)
                }
            }
            
            // Calculate maxSize to return
            return CGSize(
                width: parentWidth,
                height: currentHeight)
        }
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // CGPoint coordinates
        var x = bounds.minX
        var y = bounds.minY
        
        // Maximum width of the textbox
        let maxWidth = bounds.width
        var currentLineWidth: CGFloat = 0
        var lineHalf: CGFloat = 0
        
        // Spacing is the width of a space glyph
        let spacing = subviews[subviews.count - 1].sizeThatFits(.unspecified).width
        
        
        for index in subviews.indices.dropLast() {
            // Check if index < 1, i.e. if this is the first ever item, because I will need to set the first line height
            if index < 1 {
                // Find the largest view among the subviews, assign it's height divided by two to the variable lineHalf, and add lineHalf to y
                let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified)}
                for subview in subviewSizes {
                    if subview.height / 2 > lineHalf {
                        lineHalf = subview.height / 2
                    }
                }
                y += lineHalf
            }
            
            // Measure the next subview
            let subviewSize = subviews[index].sizeThatFits(.unspecified)
                
            
            // Check if there is place for the next item on the line
            if (currentLineWidth + subviewSize.width + spacing) <= maxWidth {
                // Yes?
                // 1. Move the x point with half of its width
                x += subviewSize.width / 2
                
                // 2. Place the item
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .center,
                    proposal: .unspecified)
                
                // 3. Update currentLineWidth
                currentLineWidth += subviewSize.width + spacing
                
                // 4. Move the x pointer to the end of this view by adding the other half of its width to x (plus spacing)
                x += subviewSize.width / 2 + spacing
                
            // Else there is no space on this line, iterate variables, and place it on the next line
            } else {
                // 1. Move the y coordinate that equals to a full line height
                y += lineHalf * 2

                // 2. Calculate the width of this subview, and update the 'x' value to be 'bounds.minX + subviewSize/2'
                x = bounds.minX + subviewSize.width / 2
                
                // 3. Place the item
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .center,
                    proposal: .unspecified)
                
                // 4. Update currentLineWidth
                currentLineWidth = subviewSize.width + spacing
                
                // 5. Move the x pointer to the end of this view by adding the other half of its width to x
                x += subviewSize.width / 2 + spacing
            }
            
        }
    }
    
    // Returns the height of the current line, based on the largest view that would fit it
    func findLineHeight(index: Int, subviews: Subviews, maxWidth: CGFloat) -> CGFloat {
        // Get the maxWidth of the line, and in a for loop, star
        // Create a variable called currentLineWidth, initialize to 0, and continue to add the width of the subviews to it if I haven't exceeded maxWidth
        // Create a variable called lineHeight, set it to 0, and each time I get a new subview, I compare the two and assign the larger value
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        let index = index
        
        // For in loop that runs as many times as the index I am outside the function, to the end of it
        for i in subviews.indices[index..<subviews.dropLast().endIndex] {
            // Measure the subview
            let subviewSize = subviews[i].sizeThatFits(.unspecified)
            
                                            // MISTAKE: Compare the current lineHeight to its height, and if its height is larger, assign it to lineHeight
            // Check if currentLineWidth is equal to maxWidth
            if lineWidth == maxWidth {
                // If it is, then there is no more space in the line; return lineHeight
                return lineHeight
            // Else if currentLineWidth is more than maxWidth
            } else if lineWidth > maxWidth {
                // Call fatalError, I have made a mistake, this shouldn't happen
                fatalError("In findLineHeight, currentLineWidth was more than maxWidth")
            }
                
            // Check if adding the subview's width to the currentLineWidth would make it more than maxWidth
            if (subviewSize.width + lineWidth) > maxWidth {
                // If it would, then there is no space for it in the line; return lineHeight
                return lineHeight
            // If it wouldn't, then it would be equal to, or less, so I can continue adding views
            } else {
                // This means that if this view's height is more than the lineHeight, I will reassign it, and add the width to currentLineWidth
                if subviewSize.height > lineHeight {
                    lineHeight = subviewSize.height
                }
                // PLACE ELEMENT in line
                lineWidth += subviewSize.width
            }
        }
        return lineHeight
    }
}
