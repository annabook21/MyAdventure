//
//  ViewController.swift
//  MyAdventure
//
//  Controller for the MyAdventure game
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var choice1Button: UIButton!
    @IBOutlet weak var choice2Button: UIButton!
    @IBOutlet weak var choice3Button: UIButton!
    @IBOutlet weak var restartButton: UIButton!

    private var adventureModel = AdventureModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        adventureModel.startAdventure()
        refreshUI()
    }

    private func configureUI() {
        storyLabel.numberOfLines = 0
        [choice1Button, choice2Button, choice3Button, restartButton].forEach { button in
            button?.layer.cornerRadius = 12
            button?.titleLabel?.numberOfLines = 0
            button?.titleLabel?.textAlignment = .center
            button?.backgroundColor = .systemBlue
            button?.setTitleColor(.white, for: .normal)
        }
        restartButton.backgroundColor = .systemGray
    }

    private func refreshUI() {
        storyLabel.text = adventureModel.getCurrentStoryText()
        updateButtons()
    }

    private func updateButtons() {
        let choices = adventureModel.currentChoices
        let buttons = [choice1Button, choice2Button, choice3Button]

        for (index, button) in buttons.enumerated() {
            if index < choices.count {
                button?.isHidden = false
                button?.setTitle(choices[index].text, for: .normal)
            } else {
                button?.isHidden = true
            }
        }
        
        // Show restart button when game is complete (success or failure)
        let isComplete: Bool
        if case .adventureComplete = adventureModel.currentState {
            isComplete = true
        } else {
            isComplete = false
        }
        restartButton.isHidden = !isComplete
        
        // Hide choice buttons when game is complete
        if isComplete {
            buttons.forEach { $0?.isHidden = true }
        }
    }

    private func showCustomerSelectionOptions() {
        let available = adventureModel.getAvailableCustomers()
        let buttons = [choice1Button, choice2Button, choice3Button]
        for (index, button) in buttons.enumerated() {
            if index < available.count {
                button?.isHidden = false
                button?.setTitle("Handle \(available[index].name)", for: .normal)
            } else {
                button?.isHidden = true
            }
        }
    }

    @IBAction func choice1ButtonTapped(_ sender: UIButton) {
        handleButton(at: 0)
    }
    @IBAction func choice2ButtonTapped(_ sender: UIButton) {
        handleButton(at: 1)
    }
    @IBAction func choice3ButtonTapped(_ sender: UIButton) {
        handleButton(at: 2)
    }

    @IBAction func restartButtonTapped(_ sender: UIButton) {
        adventureModel.reset()
        refreshUI()
    }

    private func handleButton(at index: Int) {
        switch adventureModel.currentState {
        case .start:
            adventureModel.startAdventure()
        case .customerSelection:
            let customers = adventureModel.getAvailableCustomers()
            guard index < customers.count else { return }
            adventureModel.selectCustomer(customers[index].id)
        case .handlingCustomer:
            guard index < adventureModel.currentChoices.count else { return }
            let choice = adventureModel.currentChoices[index]
            adventureModel.makeChoice(choice.id)
        case .adventureComplete:
            break
        }
        refreshUI()
    }
}

