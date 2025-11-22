//
//  AdventureModel.swift
//  MyAdventure
//
//  Model layer for the AWS Support Engineer Adventure Game
//

import Foundation

// MARK: - Adventure State
enum AdventureState {
    case start
    case customerSelection
    case handlingCustomer(Customer)
    case adventureComplete(AdventureOutcome)
}

enum AdventureOutcome {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .success(let msg):
            return "✅ SUCCESS: \(msg)"
        case .failure(let msg):
            return "❌ FAILURE: \(msg)"
        }
    }
}

struct Customer {
    let id: Int
    let name: String
    let company: String
    let issue: String
    let choices: [Choice]
}

struct Choice {
    let id: Int
    let text: String
    let nextState: ChoiceOutcome
}

enum ChoiceOutcome {
    case nextChoice([Choice])
    case success(String)
    case failure(String)
    case continueToNextCustomer
}

struct AdventureModel {
    private(set) var currentState: AdventureState = .start
    private(set) var currentCustomer: Customer?
    private(set) var currentChoices: [Choice] = []
    private(set) var customersHandled: Set<Int> = []
    private(set) var finalOutcome: AdventureOutcome?

    let customers: [Customer] = [
        Customer(
            id: 1,
            name: "Karen",
            company: "CloudCorp Inc.",
            issue: "EC2 instance won't connect to the internet.",
            choices: [
                // Layer 2: First decision - Check connectivity
                Choice(id: 101, text: "Check if it has a public IP", nextState: .nextChoice([
                    // Layer 3: It has public IP, what's next?
                    Choice(id: 1011, text: "Check security group rules", nextState: .nextChoice([
                        // Layer 4: Found the issue!
                        Choice(id: 10111, text: "Allow HTTP/HTTPS traffic", nextState: .success("Karen's instance is online! She gives you 5 stars ⭐⭐⭐⭐⭐")),
                        Choice(id: 10112, text: "Open ALL ports to internet", nextState: .failure("Security team shuts down your entire department. Karen's data got hacked.")),
                        Choice(id: 10113, text: "Close all ports for security", nextState: .failure("Nothing can connect. Karen threatens legal action."))
                    ])),
                    Choice(id: 1012, text: "Just reboot everything", nextState: .failure("The instance had ephemeral storage. All data gone. Karen cries.")),
                    Choice(id: 1013, text: "Tell her to wait 30 days", nextState: .failure("Karen escalates to your CEO. You're now answering phones."))
                ])),
                Choice(id: 102, text: "Delete AWS and use Google Cloud", nextState: .failure("You just got fired. Karen is angrier now.")),
                Choice(id: 103, text: "Tell her to restart her computer", nextState: .failure("Karen demands to speak to YOUR manager."))
            ]
        ),
        Customer(
            id: 2,
            name: "Bob",
            company: "StartupXYZ",
            issue: "Monthly AWS bill jumped from $50 to $10,000.",
            choices: [
                // Layer 2: First decision - Investigate costs
                Choice(id: 201, text: "Check CloudWatch for idle resources", nextState: .nextChoice([
                    // Layer 3: Found expensive resources
                    Choice(id: 2011, text: "Review NAT Gateway charges", nextState: .nextChoice([
                        // Layer 4: Fix the NAT Gateways
                        Choice(id: 20111, text: "Delete unused NAT Gateways", nextState: .success("Found 47 idle NAT Gateways! Bill drops to $52. Bob names his firstborn after you. 🎉")),
                        Choice(id: 20112, text: "Keep them 'just in case'", nextState: .failure("Bill stays at $10k/month. Bob's startup runs out of funding.")),
                        Choice(id: 20113, text: "Replace with NAT instances", nextState: .failure("NAT instances crash constantly. Bob migrates to Azure."))
                    ])),
                    Choice(id: 2012, text: "Check for zombie RDS databases", nextState: .success("Found 20 test databases still running. Deleted them. Bill fixed!")),
                    Choice(id: 2013, text: "Upgrade everything to save money", nextState: .failure("Bill jumps to $50k. Bob files bankruptcy."))
                ])),
                Choice(id: 202, text: "Tell him that's just how cloud works", nextState: .failure("Bob cancels AWS. Your boss is NOT happy.")),
                Choice(id: 203, text: "Mine Bitcoin on his instances", nextState: .failure("Security escorts you out. Police are involved."))
            ]
        ),
        Customer(
            id: 3,
            name: "Susan",
            company: "Enterprise Solutions LLC",
            issue: "Load balancer returning 503 errors.",
            choices: [
                // Layer 2: First decision - Diagnose 503s
                Choice(id: 301, text: "Check target group health", nextState: .nextChoice([
                    // Layer 3: Targets are unhealthy
                    Choice(id: 3011, text: "Check health check configuration", nextState: .nextChoice([
                        // Layer 4: Fix health checks
                        Choice(id: 30111, text: "Fix health check path to /health", nextState: .success("All targets healthy! Susan promotes you to Senior Engineer! 🚀")),
                        Choice(id: 30112, text: "Disable health checks entirely", nextState: .failure("Load balancer sends traffic to dead servers. Website down for 3 days.")),
                        Choice(id: 30113, text: "Change interval to 1 second", nextState: .failure("Health checks overwhelm servers. Everything crashes. CEO is furious."))
                    ])),
                    Choice(id: 3012, text: "Add more instances randomly", nextState: .failure("New instances also fail health checks. Bill doubles. Nothing works.")),
                    Choice(id: 3013, text: "Remove load balancer completely", nextState: .failure("Single point of failure. Website crashes under load. Susan quits."))
                ])),
                Choice(id: 302, text: "Turn it off and back on again", nextState: .failure("Load balancer offline for 20 minutes. Lost $2M in sales.")),
                Choice(id: 303, text: "Blame Mercury retrograde", nextState: .failure("Susan files formal complaint. HR escorts you to exit interview."))
            ]
        )
    ]

    mutating func startAdventure() {
        currentState = .customerSelection
        currentChoices = getCustomerSelectionChoices()
    }

    mutating func selectCustomer(_ id: Int) {
        guard let customer = customers.first(where: { $0.id == id }) else { return }
        currentCustomer = customer
        currentState = .handlingCustomer(customer)
        currentChoices = customer.choices
    }

    mutating func makeChoice(_ choiceId: Int) {
        guard let customer = currentCustomer,
              let choice = currentChoices.first(where: { $0.id == choiceId }) else { return }

        switch choice.nextState {
        case .nextChoice(let nextChoices):
            currentChoices = nextChoices
        case .success(let message):
            customersHandled.insert(customer.id)
            if customersHandled.count >= customers.count {
                finalOutcome = .success("🎉 You helped all customers! You're Employee of the Month!")
                currentState = .adventureComplete(finalOutcome!)
            } else {
                finalOutcome = .success(message + " Customer satisfied! Pick another.")
                currentState = .adventureComplete(finalOutcome!)
            }
            currentChoices = []
        case .failure(let message):
            finalOutcome = .failure(message)
            currentState = .adventureComplete(finalOutcome!)
            currentChoices = []
        case .continueToNextCustomer:
            handleSuccess(customer)
        }
    }

    mutating func reset() {
        currentState = .customerSelection
        currentCustomer = nil
        currentChoices = []
        customersHandled = []
        finalOutcome = nil
        startAdventure()
    }

    private mutating func handleSuccess(_ customer: Customer) {
        customersHandled.insert(customer.id)
        currentChoices = []

        if customersHandled.count >= customers.count {
            finalOutcome = .success("You handled every customer successfully.")
            currentState = .adventureComplete(finalOutcome!)
        } else {
            currentState = .customerSelection
            currentChoices = getCustomerSelectionChoices()
            currentCustomer = nil
        }
    }

    private func getCustomerSelectionChoices() -> [Choice] {
        let remaining = customers.filter { !customersHandled.contains($0.id) }
        return remaining.enumerated().map { Choice(id: $0.offset + 1000, text: "Handle \($0.element.name)", nextState: .nextChoice($0.element.choices)) }
    }

    func getCurrentStoryText() -> String {
        switch currentState {
        case .start:
            return "You're the AWS Networking Cloud Support Engineer. Choose a customer to save the day."
        case .customerSelection:
            return "You're the AWS Networking Cloud Support Engineer. Choose a customer to save the day.\n\nPick your next customer."
        case .handlingCustomer(let customer):
            return "\(customer.name) from \(customer.company)\n\nIssue: \(customer.issue)"
        case .adventureComplete(let outcome):
            return outcome.message
        }
    }

    func getAvailableCustomers() -> [Customer] {
        return customers.filter { !customersHandled.contains($0.id) }
    }
}

