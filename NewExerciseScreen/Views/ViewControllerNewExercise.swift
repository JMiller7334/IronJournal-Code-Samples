//
//  ViewControllerNewExercise.swift
//  GymTracker
//
//  Created by student on 3/20/22.
//
import UIKit
import DropDown
import FirebaseDatabase
import FirebaseAuth

class ViewControllerNewExercise: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var viewModel: ViewModelNewExercise
    
    //components
    var componentPicker: NewExercisePickerView = NewExercisePickerView(dependencyContainer: DependencyContainer.shared)
    var componentMuscleGroup: MuscleGroupCollectionView!
    
    var inputsMinimized: Bool = false
    
    
    //MARK: - INITS
    init(viewModel: ViewModelNewExercise) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ViewModelNewExercise(dependencyContainer: DependencyContainer.shared, passedWorkout: Workout(), editIndex: nil)
        
        super.init(coder: coder)
    }
    
    //Drop Down//
    let PR_menu: DropDown = {
        let PR_menu = DropDown()
        return PR_menu
    }()
    
    //MARK: - UI VARS
    @IBOutlet var labelPR: UILabel!
    @IBOutlet var labelPhase: UILabel!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var labelHint: UILabel!
    @IBOutlet var textSummary: UITextView!
    @IBOutlet var labelSummary: UILabel!
    @IBOutlet var fieldName: UITextField!
    @IBOutlet var buttonConfirm: UIButton!
    @IBOutlet var buttonBack: UIButton!
    @IBOutlet var summaryContainer: StylizedView!
    
    @IBOutlet var fieldUserInput: UITextField!
    
    //constraintS
    @IBOutlet weak var constraintUserInput: NSLayoutConstraint!
    @IBOutlet weak var constraintUserInputVert: NSLayoutConstraint!
    private var originUserInputVertSize: CGFloat!
    @IBOutlet weak var constraintPickerVert: NSLayoutConstraint!
    private var originPickerVertSize: CGFloat!
    
    
    //MARK: - PICKERVIEW FUNCS
    /** - IMPORTANT: These functions are contained within the NewExercisePickerComponent. All picker logic for this pickerview is handled there.
     No additional code for the pickerview should or is handled within this viewController.**/
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return componentPicker.numberOfComponents(in: pickerView, viewModel: viewModel)
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let pickerContent = componentPicker.pickerView(pickerView, numberOfRowsInComponent: component, viewModel: viewModel)
        return pickerContent
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let pickerContent = componentPicker.pickerView(pickerView, titleForRow: row, forComponent: component, viewModel: viewModel)
        return pickerContent
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        /**picker on select function**/
        componentPicker.pickerView(pickerView, didSelectRow: row, inComponent: component, viewModel: viewModel, fieldName: fieldName)
        
        if (viewModel.currentPhase == .weight) {
            if (row == 2){
                fieldUserInput.placeholder = "Enter a percentage."
            } else {
                fieldUserInput.placeholder = "Enter a goal weight."
            }
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let labelView = componentPicker.pickerView(pickerView, viewForRow: row, forComponent: component, reusing: view, viewModel: viewModel)
        return labelView
    }
    
    
    //MARK: - VIEW FUNCTIONS
    func setViewFromPhase(){
        /**This function configures the view based on the current phase the screen is in.
         ALL view changes for each phase should occur within this function.**/
        
        let screenState = viewModel.screenState
        
        pickerView.reloadAllComponents()
        
        fieldUserInput.text = screenState.displayInputDefault
        fieldUserInput.placeholder = screenState.displayInputPlaceholder
        
        labelPhase.text = screenState.displayPhase
        
        if labelHint.text != screenState.displayHint {
            labelHint.text = screenState.displayHint
        }
        labelSummary.text = screenState.displaySummaryTitle
        
        textSummary.text = screenState.displaySummary
        progressView.progress = screenState.displayProgress
        
        inputVisiblilty(visible: screenState.inputAvailable)
        
        if screenState.pickerViewDefault.count == pickerView.numberOfComponents {
            for (component, row) in screenState.pickerViewDefault.enumerated() {
                pickerView.selectRow(row, inComponent: component, animated: true)
            }
        }
        
        //summary auto scrolling
        //TODO: BUG - can't scroll summary when not enough lines.
        if self.viewModel.currentDefaults.isEditing {
            
            var lineToReach = 1
            if self.viewModel.currentSet > 1 {
                lineToReach = (self.viewModel.currentSet-1) * 7
            }

            textSummary.scrollToLine(lineNumber: lineToReach)
            
        } else {
            self.viewModel.animationsUI.scrollUI_scrollBottom(scrollView: textSummary)
        }
        
        //MARK: MUSCLE GROUP PHASE
        if viewModel.currentPhase == .muscleGroups && inputsMinimized == false{
            self.pickerView.isHidden = true
            labelSummary.text = "Select primary muscle group:"
            textSummary.fadeOutView{ [weak self] _ in
                guard let self = self else { return }
                self.componentMuscleGroup.showCollectionView()
            }
            animateMinimizeInputs()
            
        // case: any other phase:
        } else if inputsMinimized {
            self.pickerView.isHidden = false
            componentMuscleGroup.hideCollectionView()
            labelSummary.text = "Summary"
            textSummary.fadeInView()
            
            animateMaximizeInputs()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fieldName.resignFirstResponder()
        return true
    }
    
    private func inputVisiblilty(visible:Bool){
        /**this function toggles the user input field and animates the change. This change is handled by adjusting the size constraint of the input field element so that it shrinks and neighboring
         element is then automatically resized to fill the empty space thanks to the constraint spacing that is configured.**/
        if (visible == true){
            constraintUserInput.constant = 220
            fieldUserInput.isHidden = false
        } else {
            constraintUserInput.constant = 0
            fieldUserInput.isHidden = true
        }
    }
    
    //MARK: CONFIG DROP DOWN
    private func preSelect1RM(){
        // preSelection for dropdown(when editing)
        let preSelect1RM = self.viewModel.getExerciseType()
        if let validPreSelect = preSelect1RM {
            if let selectIndex = self.viewModel.PR_menuContents.firstIndex(of: validPreSelect) {
                self.viewModel.onDropDownSelected(dropDownIndex: selectIndex)
                self.labelPR.text = self.viewModel.PR_menuContents[selectIndex]
            } else {
                
                //TODO: test case for missing PRs/Records.
                AlertUtils.shared.showAlert(on: self, alertMode: .alert, errorCode: .nilPR, title: "", message: nil)
            }
        }
    }
    private func configDropdown() {
        PR_menu.dataSource = viewModel.PR_menuContents
        
        let gesture = UITapGestureRecognizer( target: self, action: #selector(didTapItem))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        labelPR.addGestureRecognizer(gesture)
        
        PR_menu.selectionAction = { index, title in
            self.viewModel.onDropDownSelected(dropDownIndex: index)
            if (index == 0){
                self.labelPR.text = "Select related PR/1RM"
            } else {
                self.labelPR.text = self.viewModel.PR_menuContents[index]
            }
        }
        PR_menu.anchorView = labelPR
        if (self.viewModel.PR_menuContents.count <= 1) {
            labelPR.isHidden = true
            componentPicker.include1RMs = false
        } else {
            componentPicker.include1RMs = true
            preSelect1RM()
  
        }
        componentPicker.config1RMs()
    }
    
    
    //MARK: INIT UI
    func initUI(){
        /**start up function that configures the UI and default display of various buttons within the view. This is only run on once when the view is loaded.**/
        
        originPickerVertSize = constraintPickerVert.constant
        originUserInputVertSize = constraintUserInputVert.constant
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        fieldName.delegate = self
        fieldName.tag = 1
        //setupToolbar()
        
        fieldName.returnKeyType = .done
        fieldName.autocapitalizationType = .words
        fieldName.autocorrectionType = .no
        
        //input keyboard
        fieldUserInput.delegate = self
        fieldUserInput.tag = 2
        fieldUserInput.keyboardType = .numberPad
        fieldUserInput.returnKeyType = .done
        setupToolbar()
        
        //DROPDOWN SETUP
        self.viewModel.fetchExerciseRecords {
            print("V-newExercise:<initUI>: records fetched")
        }
        
        //PICKER SETUP
        pickerView.delegate = self
        pickerView.dataSource = self
        
        fieldName.placeholder = "Enter Exercise Name"
        
        //EXERCISE GROUP PICKER
        componentMuscleGroup = MuscleGroupCollectionView(in: summaryContainer, muscleGroups: nil, primaryGroups: nil, paddingWidth: 10, paddingHeight: 50, displayOnly: false)
        componentMuscleGroup.selectionCallback = { [weak self] primaryGroupSelected in
            guard let self = self, self.viewModel.currentPhase == .muscleGroups else { return }
            if primaryGroupSelected {
                self.labelSummary.text = "Select secondary muscle group(s):"
            } else {
                self.labelSummary.text = "Select primary muscle group:"
            }
        }
        componentMuscleGroup.hideCollectionView()
        
        
        // setup for editing
        if let validEditIndex = viewModel.editIndex {
            var success: ErrorCodes
            success = viewModel.configForEditing()
            
            let editExercise = viewModel.passedWorkout.exercises[validEditIndex]
            fieldName.text = editExercise.name
            componentMuscleGroup.updateSelectedGroups(passedPrimaryGroup: editExercise.primaryMuscleGroup, passedMuscleGroups: editExercise.muscleGroups)
            
            
            if success != .successful {
                AlertUtils.shared.showAlert(on: self, alertMode: .alert, errorCode: .exerciseToDefaultsMissingExercise, title: "Exercise Conversion Issue", message: nil)
                exitScreen()
            }
        }
        
        setViewFromPhase()
    }
    
    func onViewModelChanged(){
        /**This func will update the view with the updated values present in the viewModel.
         called when the viewModel changes.**/
        setViewFromPhase()
        pickerView.reloadAllComponents()
    }
    
    func onDropDownContentChanged(){
        configDropdown()
    }
    


    //MARK: View-did-load
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        
        // Set up the subscription to changes in the ViewModel
         viewModel.didChange = { [weak self] in
             DispatchQueue.main.async {
                 self?.onViewModelChanged()
             }
         }
        
        viewModel.dropDownDidChange = { [weak self] in
            DispatchQueue.main.async {
                self?.onDropDownContentChanged()
            }
        }
    }
    
    //MARK: other functions
    @objc func didTapItem(){
        PR_menu.show()
    }
    
    //MARK: keyboard
    func setupToolbar(){
        //Create a toolbar
        let bar = UIToolbar()
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissMyKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        //Add the created button items in the toobar
        bar.items = [flexSpace, flexSpace, doneBtn]
        bar.sizeToFit()
        //Add the toolbar to our textfield
        fieldName.inputAccessoryView = bar
        fieldUserInput.inputAccessoryView = bar
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        if let keyboardFrame: NSValue = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            _ = keyboardFrame.cgRectValue
        }
    }
    @objc func keyboardWillHide(sender: NSNotification) {
        //self.view.frame.origin.y = 0 // Move view to original position
    }
    @objc func dismissMyKeyboard(){
        view.endEditing(true)
    }
    
    private func exitScreen(){        
        NavUtils.initScreenNewWorkout(vc: self, currentWorkout: self.viewModel.passedWorkout, createNewId: self.viewModel.createNewId)
    }

    //MARK: IB actions
    @IBAction func buttonBackTapped(_ sender: UIButton) {
        resetInputs()
        if (viewModel.currentPhase == .sets){
            exitScreen()
        } else {
            viewModel.backButtonTapped()
        }
    }
    
    private func screenFinished(){
        //init new screen & terminate this screen.
        NavUtils.initScreenNewWorkout(vc: self, currentWorkout: self.viewModel.passedWorkout, createNewId: self.viewModel.createNewId)
        NavUtils.removeFromStack(vc: ViewControllerNewExercise.self, navigationController: self.navigationController)
    }
    
    private func resetInputs(){
        HighlightUtil.resetAppearance(for: fieldUserInput)
        HighlightUtil.resetAppearance(for: fieldName)
        HighlightUtil.resetAppearance(for: labelPR)
    }
    
    private func highlightMissingInput(success: ErrorCodes) {
        resetInputs()
        
        switch success {
        case .missingInputError:
            HighlightUtil.highlight(for: fieldUserInput, borderColor: .yellow, textColor: .yellow, placeholderAttributes: [.foregroundColor: UIColor.yellow])
        case .missingExerciseName:
            HighlightUtil.highlight(for: fieldName, borderColor: .yellow, textColor: .yellow, placeholderAttributes: [.foregroundColor: UIColor.yellow])
        case .missingExercisePR:
            HighlightUtil.highlight(for: labelPR, borderColor: .yellow, textColor: .yellow)
        default:
            print("V-vcNewExercise<hightlightMissingInput>: no missing input")
        }
    }
    
    @IBAction func buttonConfirmTapped(_ sender: UIButton) {
        
        //muscle groups
        if self.viewModel.currentPhase == .muscleGroups {
            let primaryGroup = componentMuscleGroup.selectedPrimaryMuscle
            let secondaryGroup: [String] = Array(componentMuscleGroup.selectedMuscleGroups)
            viewModel.writeMuscleGroups(primaryMuscleGroup: primaryGroup, secondaryMuscleGroups: secondaryGroup)
        }
        
        /**Gets picker selection data**/
        let (pickerInputString, pickerInputIndex) = componentPicker.getPickerInputs(pickerView: pickerView, viewModel: viewModel)
            
        //call viewModel
        let success = viewModel.confirmButtonTapped(userInput: fieldUserInput.text, pickerSelectionString: pickerInputString, pickerSelectionIndex: pickerInputIndex)
        
        highlightMissingInput(success: success)
        if (success != ErrorCodes.successful) {
            print("VC-NewExercise<buttonConfirmTapped>: error recieved from viewModel: \(success)")
            AlertUtils.shared.showAlert(on: self, alertMode: .alert, errorCode: success, title: "Alert", message: nil)
            
        } else {
            if (viewModel.currentPhase == .completion) {
                screenFinished()
            }
        }
    }
    
    @IBAction func textFieldInputChanged(_ sender: UITextField) {
        viewModel.exerciseName = sender.text ?? ""
    }
    
    //MARK: UI ANIMATIONS
    func animateMinimizeInputs() {
        let minimizedHeight: CGFloat = 0.0
        self.inputsMinimized = true
        
        UIView.animate(withDuration: 0.3, animations: {
            self.constraintUserInputVert.constant = minimizedHeight
            self.constraintPickerVert.constant = minimizedHeight
            self.view.layoutIfNeeded()
        })
    }
    
    func animateMaximizeInputs() {
        self.inputsMinimized = false
        UIView.animate(withDuration: 0.3, animations: {
            self.constraintUserInputVert.constant = self.originUserInputVertSize
            self.constraintPickerVert.constant = self.originPickerVertSize
            self.view.layoutIfNeeded()
        })
    }
    
}
