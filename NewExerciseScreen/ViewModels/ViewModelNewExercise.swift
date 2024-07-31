//
//  ViewModelNewExercise.swift
//  GymTracker
//
//  Created by student on 3/2/24.
//

import Foundation
import UIKit
import DropDown


class ViewModelNewExercise {
        
    var editIndex: Int?
    var shouldWrite = false
    var createNewId = true
    
    /**instance of workout passed to the vc via navUtils**/
    var passedWorkout: Workout
    
    //dependencies
    let localStorage: LocalStorage
    let validationUtils: ValidationUtils
    let firebaseService: FirebaseService
    let datebaseService: RealmService
    
    let arrayUtils: ArrayUtils
    let alertUtils: AlertUtils
    let animationsUI: AnimationsUI
    
    
    var PR_menuContents: [String] = [] {
        didSet {self.dropDownDidChange?()}
    }
    var dropDownDidChange: (() -> Void)?
    
    var screenState: NewExerciseScreenState {
        didSet {self.didChange?()}
    }
    var didChange: (() -> Void)?
    
    //variaables
    var exerciseName = ""
    var currentPhase: ExerciseCreatePhase
    var currentSet: Int
    var totalSets: Int
    var currentExercise: Exercise
    var currentDefaults: ExerciseDefaults
    
    //components
    var componentPicker: NewExercisePickerView? = nil
    
    
    //MARK: - INIT
    init(dependencyContainer: DependencyContainer,
         
         screenState: NewExerciseScreenState = NewExerciseScreenState().updateByPhase(currentPhase: .sets, currentSet: 1, exerciseDefaults: nil, reverse: false),
         currentPhase: ExerciseCreatePhase = .sets,
         currentSet: Int = 1,
         totalSets: Int = 1,
         currentExercise: Exercise = Exercise(),
         currentDefaults: ExerciseDefaults = ExerciseDefaults(),
         passedWorkout: Workout, editIndex: Int?) {
        
        //dependency injection
        self.validationUtils = dependencyContainer.validationUtils
        self.firebaseService = dependencyContainer.firebaseService
        self.datebaseService = dependencyContainer.databaseService
        self.localStorage = dependencyContainer.localStorage
        
        self.alertUtils = dependencyContainer.alertUtils
        self.arrayUtils = dependencyContainer.arrayUtils
        self.animationsUI = dependencyContainer.animationsUI
        
        //properties
        self.screenState = screenState
        self.didChange = nil
        self.dropDownDidChange = nil
        self.currentPhase = currentPhase
        self.currentSet = currentSet
        self.totalSets = totalSets
        self.currentExercise = currentExercise
        
        //late init placeholder
        self.currentDefaults = currentDefaults
        
        // expected as arguments
        self.passedWorkout = passedWorkout
        self.editIndex = editIndex //can be nil
    }

    // called in view.initUI()
    func configForEditing() -> ErrorCodes {
        /**sets up the defaults class to display and generate summarys for editing exercises
         **/
        var success: ErrorCodes
        let editExercise = self.passedWorkout.exercises[editIndex!]
        success = self.currentDefaults.exerciseObjectToDefaults(passedExercise: editExercise)
    
        self.screenState = self.screenState.updateByPhase(currentPhase: .sets, currentSet: 1, exerciseDefaults: self.currentDefaults, reverse: false)
        
        self.exerciseName = editExercise.name
        self.currentExercise.type = editExercise.type
        return success
    }
    
    
    //MARK: - DATABASE OPERATIONS
    private func handleDatabaseOperation(currentSuccess: ErrorCodes) -> ErrorCodes {
    
        //TODO: below needs to be tested
        var success = currentSuccess
        
        if self.shouldWrite == true && self.editIndex == nil {
            /*success = databaseService.validateHistoryCount(newWorkout: &self.passedWorkout, thisExercise: &self.currentExercise)*/
        }
            
        if self.shouldWrite == true {
            let useMetric = localStorage.fetchDefaultUseMetric()
            self.datebaseService.writeNewWorkout(self.passedWorkout, useMetric: useMetric, completion: { errorCode in
                switch errorCode {
                case .successful:
                    print("Workout written to Realm successfully.")
                    success = .successful
                case .realmWriteError:
                    print("Error writing workout to Firebase.")
                    success = .realmWriteError
                default:
                    print("An unknown error occurred.")
                    success = .unexpectedError
                }
            })
        }
        return success
    }
    
    
    //MARK: - VIEWMODEL FUNCS
    private func writeTotalSets(userInput:String?, currentErrorCode: ErrorCodes) -> ErrorCodes {
        /**safely writes to the viewmodels total sets property.
         NOTE: If there is an issue converting or writing, this function will return ErrorCode.toIntError enum otherwise .successful will be returned.**/
        
        if (currentErrorCode != .successful){
            return currentErrorCode
        }
        
        let (validInput, success) = validationUtils.stringToInt(userInput: userInput)
        if (success == .successful){
            self.totalSets = validInput!
        }
        return success
    }
    
    private func inputRequired(userInput: String?) -> ErrorCodes{
        /**checks if the input is required for the current phase & if so if the input exists.
         NOTE: if this function returns ErrorCodes.successful enum then either no input was needed or the input was present when needed.**/
        
        let inputRequiredList: [ExerciseCreatePhase] = [ExerciseCreatePhase.sets, ExerciseCreatePhase.weight, ExerciseCreatePhase.reps]
        if (userInput == "" && inputRequiredList.contains(self.currentPhase) == true){
            return ErrorCodes.missingInputError
        } else {
            return ErrorCodes.successful
        }
    }
    
    
    
    private func advanceToNextPhase(currentErrorCode: ErrorCodes) {

        //update phase & screen state
        if (currentErrorCode == .successful){
            
            //cycle phase forward
            /**phases follow default cycling order.**/
            self.currentPhase = self.currentPhase.cyclePhase(reverse: false, currentPhase: currentPhase, currentSet: self.currentSet, totalSets: self.totalSets)
            
            if (self.currentPhase == .setForward){
                /**adjust current phase for incrementing to the next set.**/
                currentSet += 1
                currentPhase = .reps
            }
            
            //Adjust phase based on defaults
            self.currentPhase = self.currentDefaults.adjustPhaseByDefaults(currentPhase: self.currentPhase, currentSet: currentSet, reverse: false)
        }
    }
    
    
    
    private func writeToWorkout() -> ErrorCodes {
        self.currentExercise.name = self.exerciseName
        
        // - case: editing
        if let editIndex = self.editIndex {
            
            // - case editing; should write
            if self.shouldWrite {
                print("\n Writing to database \n\n")
                /**unsure if this is used - check if breakpoint ever reached.
                 **/
                //TODO: database write logic
            
            // - case editing; should not write
            } else {
                guard editIndex < self.passedWorkout.exercises.count else {
                    return .workoutWriteError
                }
                self.passedWorkout.exercises[editIndex] = self.currentExercise
            }
            
        // - case new exercise
        } else {
            self.passedWorkout.addExercise(newExercise: self.currentExercise)
        }
        return .successful
    }
    
    
    
    private func verfyFinalInputs(success: ErrorCodes) -> ErrorCodes {
        print("\n \(self.currentExercise) \n")
        var result = success
        if self.exerciseName == "" || self.exerciseName.isEmpty {
            self.currentPhase = .muscleGroups
            return .missingExerciseName
        }
        
        if self.currentDefaults.pickerWeight.contains(2) && self.currentExercise.type == "" {
            return .missingExercisePR
        }
        
        result = writeToWorkout()
        return result
    }

    
    
    //MARK: confirm button
    func confirmButtonTapped(userInput: String?, pickerSelectionString: [String], pickerSelectionIndex: [Int]) -> ErrorCodes {
        /**
         Handles all logic that occurs when the user the taps the confirm button.
         
         Note:
         - variable: success reads whether each task required in this method was sucessful or passed certain checks.
         - if failure to complete all necessary tasks this method returns an ErrorCode enum indicating the issue to the view.**/
        
        var success: ErrorCodes

        //check if input required
        success = inputRequired(userInput: userInput)
        
        //write to viewModel variable - set
        if (self.currentPhase == .sets){
            success = writeTotalSets(userInput: userInput, currentErrorCode: success)
        }
        
        //write input to exercise model
        success = currentExercise.writeByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet, userInput: userInput, pickerInputString: pickerSelectionString, currentErrorCode: success)
        
        //write input to defaults model
        success = currentDefaults.writeDefaultsByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet, userInput: userInput, pickerInput: pickerSelectionIndex, currentErrorCode: success)
        
        //update currentphase & current set
        self.advanceToNextPhase(currentErrorCode: success)
        
        //verify final user inputs
        if (currentPhase == .completion) {
            success = verfyFinalInputs(success: success)
        }
        
        //update view using screen state
        if (success == .successful){
            /** - Important: NewExerciseScreenState Model reads exercise defaults & and generates summary from ExerciseDefaults model*/
            self.screenState = self.screenState.updateByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet, exerciseDefaults: self.currentDefaults, reverse: false)
        }

        //MARK: Database write
        //write to database if finished
        if self.currentPhase == .completion && success == .successful {
            success = handleDatabaseOperation(currentSuccess: success)
        }
        return success
    }
    
    
    
    private func advanceToPreviousPhase(){
        //update current phase
        /**This follows the default phase cycling order.**/
        self.currentPhase = currentPhase.cyclePhase(reverse: true, currentPhase: self.currentPhase, currentSet: self.currentSet, totalSets: self.totalSets)
        
        //update currentset if needed
        if (self.currentPhase == .setPrevious){
            /**adjust current phase for incrementing to the previous set.**/
            currentSet -= 1
            currentPhase = .rest
        }
        
        //update current phase based on defaults
        self.currentPhase = currentDefaults.adjustPhaseByDefaults(currentPhase: self.currentPhase, currentSet: self.currentSet, reverse: true)
    }
    
    //MARK: BACK BUTTON
    func backButtonTapped(){
        /**Handles cycling back phases. This allows the user to go back and redo or change the any inputs they previously enter.
         This function also loads and updates the default to values for the phase the user is cycling back to.**/
        print("\n")
        
        //TODO: observe current phase and determine if function should exit screen.
                
        //delete defaults at current set index
        if (self.currentDefaults.isEditing == false) {
            self.currentDefaults.deleteDefaultsByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet)
        }
        
        //update phase & current set
        self.advanceToPreviousPhase()

        //read defaults & update screen state
        self.screenState = self.screenState.updateByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet, exerciseDefaults: self.currentDefaults, reverse: true)
    }
    
    
    //MARK: - DROPDOWN SELECT
    func onDropDownSelected(dropDownIndex: Int){
        print("DROP DOWN SELECTION")
        if (dropDownIndex == 0){
            self.currentExercise.type = ""
        } else {
            self.currentExercise.type = PR_menuContents[dropDownIndex]
            print(self.currentExercise)
        }
    }
    
    
    
    //MARK: - PICKER SELECT
    func onPickerSelected(selectedRow: Int, selectedComp: Int){
        /**This function handles updating the phase when an option in the pickerview is selected.
         These changes are then processed by screen state and the changes will be reflected in the view.
         **/
        
        let originalPhase = currentPhase
        
        //Exertion - no exertion toggle
        if (self.currentPhase == .noExertion && selectedRow == 1){
            self.currentPhase = .exertion
        } else if (currentPhase == .exertion && selectedRow == 0 && selectedComp == 1){
            currentPhase = .noExertion
        }
        
        //Weight - no weight toggle
        if (self.currentPhase == .noWeight && selectedRow == 1) {
            self.currentPhase = .weight
            
        } else if (self.currentPhase == .weight && selectedRow == 0) {
            self.currentPhase = .noWeight
        }
        
        //Reps - no reps toggle
        if (self.currentPhase == .noReps && selectedRow == 1) {
            self.currentPhase = .reps
        } else if (self.currentPhase == .reps && selectedRow == 0) {
            self.currentPhase = .noReps
        }
        
        //update screen state
        /**ensure screen state is only updated one time and only if the currentPhase did chnage.**/
        if (originalPhase != currentPhase){
            self.screenState = screenState.updateByPhase(currentPhase: self.currentPhase, currentSet: self.currentSet, exerciseDefaults: nil, reverse: false)
        }
    }
    
    func getExerciseType() -> String? {
        if self.editIndex == nil {
            print("NOT EDITING")
            return nil
        }
        let type = self.currentExercise.type
        if self.currentExercise.type == ""{
            // Handle the case where exercise type is nil
            print("NO TYPE")
            return nil
        }
        return type
    }
    
    //MARK: DATABASE READ(PRs)
    func fetchExerciseRecords(completion: @escaping () -> Void) {
        self.firebaseService.fetchSavedRecords { recordsArray in
            self.PR_menuContents = ["Select Related 1RM/PR"] + recordsArray.map { $0.name }
            completion()
        }
    }
    
    //MARK: WRITE MUSCLE GROUPS
    func writeMuscleGroups(primaryMuscleGroup: String, secondaryMuscleGroups: [String]) {
        self.currentExercise.primaryMuscleGroup = primaryMuscleGroup
        self.currentExercise.muscleGroups = secondaryMuscleGroups
    }
}
