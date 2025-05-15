//
//  SkillBee.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//
import Foundation
import Combine

class SkillBeeModel: ObservableObject {
    @Published var isVisible = false
    @Published var messages: [SkillBeeMessage] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Motivational quotes
    private let motivationalQuotes = [
        "Swapping skills is learning for life. Keep buzzing! 🌟",
        "Every skill shared is a skill gained! 🐝",
        "Learning together creates stronger communities! 💪",
        "Today's learner, tomorrow's master. Keep going! 🚀",
        "Teach what you know, learn what you don't. That's the Swaptitude way! 🔄",
        "The best way to learn is to teach someone else! 🧠",
        "Skills are meant to be shared, not hoarded. Spread the knowledge! 📚",
        "Growth happens outside your comfort zone. Try teaching something new today! 🌱",
        "The more you share your skills, the better you become at them! ✨",
        "Building connections through skill sharing creates lifelong friendships! 👥"
    ]
    
    // Conversation starters by category
    private let conversationStarters: [String: [String]] = [
        "music": [
            "What inspired you to learn this instrument?",
            "How long have you been practicing this skill?",
            "What's your favorite piece to play?",
            "Do you have any tips for beginners just starting with this instrument?",
            "What's the most challenging aspect of learning this instrument?"
        ],
        "languages": [
            "What made you interested in learning this language?",
            "Have you had a chance to use this language in real life?",
            "What's the most interesting phrase you've learned so far?",
            "Do you have any favorite learning resources you'd recommend?",
            "What's your learning routine like for practicing vocabulary?"
        ],
        "technology": [
            "What project are you hoping to build with these skills?",
            "What's your coding environment like?",
            "What resources have you found helpful so far?",
            "How did you get started in this technology field?",
            "What applications are you most excited to create?"
        ],
        "cooking": [
            "What's your favorite dish to make?",
            "Do you have any specialty ingredients you love working with?",
            "What cooking technique are you most excited to learn?",
            "What cuisine are you most experienced with?",
            "Do you have any kitchen tools you couldn't live without?"
        ],
        "art": [
            "What artists inspire your work?",
            "What medium do you enjoy working with most?",
            "What's your creative process like?",
            "How did you develop your artistic style?",
            "What's the most challenging piece you've worked on?"
        ],
        "default": [
            "What made you interested in learning this skill?",
            "How do you plan to use this skill once you've mastered it?",
            "What's your learning style like?",
            "What resources have you found most helpful for this skill?",
            "What's been the most challenging part of learning this skill?"
        ]
    ]
    
    // Generate a random motivational quote
    func getRandomQuote() -> String {
        return motivationalQuotes.randomElement() ?? "Keep learning and growing! 🌱"
    }
    
    // Generate conversation starters based on skill category
    func getConversationStarters(for category: String) -> [String] {
        return conversationStarters[category.lowercased()] ?? conversationStarters["default"]!
    }
    
    // Update suggestions based on conversation context
    func updateSuggestions() {
        if messages.count <= 3 {
            suggestions = [
                "How do I find a good match?",
                "Tips for teaching beginners",
                "How to prepare for my first swap"
            ]
        } else if messages.last?.content.lowercased().contains("teach") ?? false {
            suggestions = [
                "How to structure a lesson?",
                "Tips for engaging students",
                "Common teaching mistakes"
            ]
        } else if messages.last?.content.lowercased().contains("learn") ?? false {
            suggestions = [
                "How to learn efficiently",
                "Setting learning goals",
                "Tracking my progress"
            ]
        } else {
            suggestions = [
                "How to use Swaptitude effectively",
                "Finding the right skill swap",
                "Give me a motivational quote"
            ]
        }
    }
    
    // Get response for query - no AI needed, just use predetermined responses
    func getResponseForQuery(_ query: String) -> String {
        let lowercasedQuery = query.lowercased()
        
        // Structure lesson question
        if lowercasedQuery.contains("structure") && lowercasedQuery.contains("lesson") {
            return "To structure an effective lesson: 1) Start with a clear introduction of what will be covered 2) Break down complex concepts into manageable chunks 3) Demonstrate key techniques with examples 4) Allow time for guided practice 5) End with a summary and opportunity for questions. Remember to adapt based on your student's learning pace! 🐝"
        }
        
        // Tips for engaging students
        else if lowercasedQuery.contains("engaging") && lowercasedQuery.contains("student") {
            return "To keep students engaged: 1) Use interactive activities rather than just lecturing 2) Relate skills to real-world applications they care about 3) Ask open-ended questions to encourage participation 4) Provide immediate, constructive feedback 5) Mix teaching methods to accommodate different learning styles 6) Show enthusiasm for what you're teaching! 🐝"
        }
        
        // Common teaching mistakes
        else if lowercasedQuery.contains("common") && lowercasedQuery.contains("teaching") && lowercasedQuery.contains("mistake") {
            return "Common teaching mistakes to avoid: 1) Moving too quickly through difficult concepts 2) Focusing only on theory without practical application 3) Not adapting to different learning styles 4) Getting frustrated when students don't understand immediately 5) Forgetting to provide positive reinforcement along with corrections 6) Overwhelming students with too much information at once 🐝"
        }
        
        // Match responses to other common questions
        else if lowercasedQuery.contains("find") && lowercasedQuery.contains("match") {
            return "To find a good match on Swaptitude: 1) Create a detailed skill post highlighting what you can teach and want to learn 2) Browse the Explore tab to find users with complementary skills 3) Look for users with verified profiles and good ratings 4) Send personalized messages when you connect 🐝"
        }
        else if lowercasedQuery.contains("teach") && (lowercasedQuery.contains("tip") || lowercasedQuery.contains("beginner")) {
            return "Tips for teaching beginners: 1) Break down complex concepts into simple steps 2) Be patient and positive with feedback 3) Focus on fundamentals before advanced techniques 4) Use examples and demonstrations 5) Set realistic expectations and celebrate small wins 🐝"
        }
        else if lowercasedQuery.contains("prepare") && lowercasedQuery.contains("swap") {
            return "To prepare for your first skill swap: 1) Plan a structured lesson with clear goals 2) Prepare any necessary materials or resources 3) Find a comfortable meeting place 4) Set expectations about time commitment 5) Be open to learning and adapting your teaching style based on feedback 🐝"
        }
        else if lowercasedQuery.contains("profile") {
            return "Creating an effective profile: 1) Add a clear profile photo 2) Write a detailed bio about your experience 3) Be specific about skills you can teach 4) Clearly state what you want to learn 5) Get verified to build trust with potential matches 🐝"
        }
        else if lowercasedQuery.contains("rating") || lowercasedQuery.contains("review") {
            return "Getting good reviews is important for trust on Swaptitude! After successful skill exchanges, politely ask your partner to leave a review. Always be professional, prepared, and respectful during exchanges. Remember to leave honest and constructive reviews for others too! 🐝"
        }
        else if lowercasedQuery.contains("verify") || lowercasedQuery.contains("verification") {
            return "Getting verified on Swaptitude helps build trust with potential skill partners. Go to your Profile tab, and you'll find the verification option. Complete the email verification process to get the verified badge on your profile. Verified users typically get more matches! 🐝"
        }
        else if lowercasedQuery.contains("delete") || lowercasedQuery.contains("remove") {
            return "To delete content on Swaptitude: For posts, go to your Profile tab and tap the delete button on the post you want to remove. For account deletion, go to Profile > Side Menu > Delete Account. Note that deleting your account will remove all your posts, matches, and messages! 🐝"
        }
        else if lowercasedQuery.contains("chat") || lowercasedQuery.contains("message") {
            return "Messaging tips for Swaptitude: 1) Start with a friendly introduction 2) Reference specific skills you're interested in exchanging 3) Ask open-ended questions about their experience 4) Suggest a specific time/place to meet for the skill exchange 5) Be respectful and professional in all communications 🐝"
        }
        else if lowercasedQuery.contains("location") || lowercasedQuery.contains("meet") {
            return "When arranging skill swap meetings: 1) Choose public places like libraries, cafes, or community centers 2) Consider the needs of the skill (e.g., quiet space for language learning) 3) Be clear about time expectations 4) Share location details through the chat 5) Always prioritize safety when meeting someone new 🐝"
        }
        else if lowercasedQuery.contains("learn") && (lowercasedQuery.contains("efficient") || lowercasedQuery.contains("effective")) {
            return "For efficient learning: 1) Set specific, achievable goals 2) Break learning into small chunks 3) Practice regularly, even if just for 15-20 minutes 4) Actively engage with the material rather than passive learning 5) Teach what you've learned to others to reinforce your understanding 🐝"
        }
        else if lowercasedQuery.contains("unmatch") || lowercasedQuery.contains("disconnect") {
            return "To unmatch with someone on Swaptitude: 1) Go to your Matches tab 2) Select the match you want to end 3) Tap on the match details 4) Scroll down and tap 'Unmatch' 5) Confirm your decision. Note that this will delete all messages between you and this person! 🐝"
        }
        else if lowercasedQuery.contains("post") && (lowercasedQuery.contains("create") || lowercasedQuery.contains("make")) {
            return "To create a skill post: 1) Tap the Post tab in the main menu 2) Fill in what you can teach and its category 3) Fill in what you want to learn and its category 4) Add a detailed description 5) Add your location (optional) 6) Tap 'Post Skill Swap' to publish. Be specific to attract the right matches! 🐝"
        }
        else if lowercasedQuery.contains("quote") || lowercasedQuery.contains("motivation") {
            return getRandomQuote() + " What else can I help you with today? 🐝"
        }
        else if lowercasedQuery.contains("thank") {
            return "You're very welcome! I'm always here to help with your skill-swapping journey. Is there anything else you'd like to know about Swaptitude? 🐝"
        }
        else if lowercasedQuery.contains("hello") || lowercasedQuery.contains("hi ") {
            return "Hello there! How can I assist with your skill-swapping today? Whether you need help with finding matches, preparing lessons, or using Swaptitude features, I'm here to help! 🐝"
        }
                else if lowercasedQuery.contains("zoom") || lowercasedQuery.contains("meeting") {
                    return "To schedule a meeting in Swaptitude: 1) Open your chat with a match 2) Click the 'Schedule Zoom' button 3) Set the meeting title, date, time, and duration 4) Create the meeting and share the link 5) Both you and your match will receive a notification about the scheduled meeting. You can also add it directly to your calendar! 🐝"
                }
                else if lowercasedQuery.contains("calendar") {
                    return "After scheduling a meeting with your match, you can easily add it to your calendar by clicking 'Add to Calendar' in the meeting details. This will create a calendar event with all the meeting information including the Zoom link! 🐝"
                }
                else if lowercasedQuery.contains("safe") || lowercasedQuery.contains("security") {
                    return "Staying safe on Swaptitude: 1) Always meet in public places for initial exchanges 2) Share your meeting details with someone you trust 3) Trust verified profiles more than unverified ones 4) Check reviews before meeting 5) Report any inappropriate behavior through the app 🐝"
                }
                else if lowercasedQuery.contains("best") && lowercasedQuery.contains("practice") {
                    return "Best practices for Swaptitude: 1) Keep your profile and posts up-to-date 2) Respond to messages promptly 3) Be clear about your skill level when teaching 4) Provide and ask for feedback after exchanges 5) Leave honest reviews 6) Respect others' time and commitments 🐝"
                }
                else if lowercasedQuery.contains("welcome") || lowercasedQuery.contains("introduction") {
                    return "Welcome to Swaptitude! This platform helps you connect with others to exchange skills - you teach what you know and learn what you want! Create a post detailing your offerings and interests, find matches, chat to arrange details, and then meet to share knowledge. Need any specific guidance? 🐝"
                }
                
                // Default response for anything else
                return "I'm not sure about that, but I can help you with finding matches, preparing for skill exchanges, creating posts, or understanding how Swaptitude works. Is there anything specific about skill swapping you'd like to know? 🐝"
            }
        }
