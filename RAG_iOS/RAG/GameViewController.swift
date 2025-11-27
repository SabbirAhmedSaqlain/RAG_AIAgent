//
//  GameViewController.swift
//  RAG
//
//  Created by Rezan on 11/27/25.
//
import UIKit

struct AskResponse: Codable {
    let answer: String
}

class GameViewController: UIViewController {

    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI Assistant"
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let queryField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Ask something..."
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.text = "Tell me about Sabbir Ahmed?"
        return tf
    }()
    
    private let askButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Ask", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        btn.backgroundColor = UIColor.systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        return btn
    }()
    
    private let clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Clear", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        btn.backgroundColor = UIColor.systemGray2
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        return btn
    }()
    
    private let buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private let resultTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 17)
        tv.isEditable = false
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 12
        return tv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Networking state/config
    
    // A dedicated session with shorter timeouts than the default.
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Time to wait for the initial connection.
        config.timeoutIntervalForRequest = 20 // seconds
        // Total time for a resource load (including redirects).
        config.timeoutIntervalForResource = 60 // seconds
        // Keep shared caches disabled for deterministic behavior (optional).
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
    // Track current request for cancellation.
    private var currentTask: Task<Void, Never>?
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLayout()
        askButton.addTarget(self, action: #selector(didTapAskOrCancel), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        // Configure stack with buttons
        buttonsStack.addArrangedSubview(askButton)
        buttonsStack.addArrangedSubview(clearButton)
        
        [titleLabel, queryField, buttonsStack, resultTextView, loadingIndicator]
            .forEach { view.addSubview($0) }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        queryField.translatesAutoresizingMaskIntoConstraints = false
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        askButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            queryField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            queryField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            queryField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            queryField.heightAnchor.constraint(equalToConstant: 44),
            
            buttonsStack.topAnchor.constraint(equalTo: queryField.bottomAnchor, constant: 16),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsStack.heightAnchor.constraint(equalToConstant: 48),
            
            resultTextView.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 20),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: buttonsStack.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 10)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func didTapAskOrCancel() {
        // If a request is in flight, cancel it.
        if currentTask != nil {
            cancelCurrentRequest()
            return
        }
        
        guard let query = queryField.text, !query.isEmpty else {
            showAlert("Enter a prompt")
            return
        }
        
        currentTask = Task { [weak self] in
            guard let self else { return }
            await self.callAgent(query: query)
        }
        
        setLoadingUI(isLoading: true)
    }
    
    @objc private func didTapClear() {
        resultTextView.text = ""
    }
    
    private func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
        setLoadingUI(isLoading: false)
        updateResult("Request cancelled.")
    }
    
    // MARK: - Networking
    
    private func callAgent(query: String) async {
        do {
            let answer = try await askAgent(query)
            await updateResult(answer)
        } catch is CancellationError {
            // Swallow; UI already updated on cancel.
        } catch let urlError as URLError {
            let message: String
            switch urlError.code {
            case .timedOut:
                message = "⏳ The request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                message = "🌐 Network issue: \(urlError.localizedDescription)"
            default:
                message = "❌ URL error: \(urlError.localizedDescription)"
            }
            await updateResult(message)
        } catch {
            await updateResult("❌ Error: \(error.localizedDescription)")
        }
        await MainActor.run {
            self.setLoadingUI(isLoading: false)
            self.currentTask = nil
        }
    }
    
    private func askAgent(_ query: String) async throws -> String {
        guard let url = URL(string: "http://localhost:8000/ask") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Percent-encode form-urlencoded body to avoid server parsing issues.
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let bodyString = "query=\(encodedQuery)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Optional: per-request timeout override (kept short to avoid long hangs).
        request.timeoutInterval = 30
        
        // Use our configured session (with timeouts).
        let (data, response) = try await session.data(for: request)
        
        // Basic status code check for faster failure feedback.
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw URLError(.badServerResponse, userInfo: ["status": http.statusCode, "body": text])
        }
        
        let decoded = try JSONDecoder().decode(AskResponse.self, from: data)
        return decoded.answer
    }
    
    // MARK: - UI Helpers
    
    @MainActor
    private func updateResult(_ text: String) {
        resultTextView.text = text
    }
    
    @MainActor
    private func setLoadingUI(isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            askButton.setTitle("Cancel", for: .normal)
            askButton.backgroundColor = .systemRed
            clearButton.isEnabled = false
            queryField.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            askButton.setTitle("Ask", for: .normal)
            askButton.backgroundColor = .systemBlue
            clearButton.isEnabled = true
            queryField.isEnabled = true
        }
    }
    
    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
