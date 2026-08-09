import Foundation
import Combine

protocol StoryServiceProtocol: Sendable {
    func fetchStories() async throws -> [Story]
    func fetchStory(id: String) async throws -> Story?
    func searchStories(query: String) async throws -> [Story]
    func fetchStories(category: StoryCategory) async throws -> [Story]
    func fetchFeatured() async throws -> Story?
    func fetchStoryOfDay() async throws -> Story?
}

enum StoryServiceError: Error, LocalizedError {
    case notFound, networkError, decodingError
    var errorDescription: String? {
        switch self {
        case .notFound: return "Story not found"
        case .networkError: return "Oops! The storybook got lost in the clouds."
        case .decodingError: return "Failed to prepare your adventure"
        }
    }
}

final class MockStoryService: StoryServiceProtocol {
    private var cached: [Story]?

    func fetchStories() async throws -> [Story] {
        if let cached { return cached }
        try await Task.sleep(nanoseconds: 400_000_000)
        let stories = MockData.stories
        cached = stories
        return stories
    }

    func fetchStory(id: String) async throws -> Story? {
        let all = try await fetchStories()
        return all.first { $0.id == id }
    }

    func searchStories(query: String) async throws -> [Story] {
        let all = try await fetchStories()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.category.rawValue.lowercased().contains(q) ||
            $0.discoverItems.joined().lowercased().contains(q)
        }
    }

    func fetchStories(category: StoryCategory) async throws -> [Story] {
        let all = try await fetchStories()
        return all.filter { $0.category == category }
    }

    func fetchFeatured() async throws -> Story? {
        let all = try await fetchStories()
        return all.first { $0.isFeatured } ?? all.first
    }

    func fetchStoryOfDay() async throws -> Story? {
        let all = try await fetchStories()
        return all.first { $0.isStoryOfDay } ?? all.randomElement()
    }
}

// Optional remote implementation showing URLSession + Codable
actor RemoteStoryService: StoryServiceProtocol {
    let baseURL: URL
    init(baseURL: URL) { self.baseURL = baseURL }
    func fetchStories() async throws -> [Story] {
        let (data, _) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("stories"))
        return try JSONDecoder().decode([Story].self, from: data)
    }
    func fetchStory(id: String) async throws -> Story? { try await fetchStories().first { $0.id == id } }
    func searchStories(query: String) async throws -> [Story] { try await fetchStories().filter { $0.title.localizedCaseInsensitiveContains(query) } }
    func fetchStories(category: StoryCategory) async throws -> [Story] { try await fetchStories().filter { $0.category == category } }
    func fetchFeatured() async throws -> Story? { try await fetchStories().first { $0.isFeatured } }
    func fetchStoryOfDay() async throws -> Story? { try await fetchStories().first { $0.isStoryOfDay } }
}

// MARK: Mock Data
enum MockData {
    static let stories: [Story] = [
        Story(
            id: "moon_explorer",
            title: "The Little Moon Explorer",
            titleTe: "చిన్న చంద్రుని అన్వేషకుడు",
            description: "Tonight, Luna discovers a secret path to the stars and learns how brave little explorers can light up the sky.",
            descriptionTe: "ఈ రాత్రి, లూనా నక్షత్రాలకు ఒక రహస్య మార్గాన్ని కనుగొంటుంది.",
            category: .space,
            ageRange: "3-7",
            durationMinutes: 8,
            rating: 4.9,
            coverEmoji: "🌙",
            coverGradient: ["0D47A1","7C4DFF"],
            isFeatured: true,
            isStoryOfDay: true,
            pages: [
                StoryPage(id: "m1", index: 0, text: "Luna loved looking at the moon every night before bed. It glowed like a silver lantern.", textTe: "లూనాకు ప్రతి రాత్రి చంద్రుని చూడటం ఇష్టం.", illustrationName: "moon1", narrationText: "Luna loved looking at the moon every night before bed.", choice: nil, isEnding: false),
                StoryPage(id: "m2", index: 1, text: "One evening, a tiny star fell near her window and whispered, 'Follow me!'", textTe: "ఒక సాయంత్రం ఒక చిన్న నక్షత్రం ఆమె కిటికీ దగ్గర పడింది.", illustrationName: "moon2", narrationText: "A tiny star fell and whispered follow me.", choice: nil, isEnding: false),
                StoryPage(id: "m3", index: 2, text: "Luna tiptoed into the garden where fireflies drew a glowing path to the sky.", textTe: "లూనా తోటలోకి వెళ్ళింది, మిణుగురు పురుగులు మెరుస్తున్నాయి.", illustrationName: "moon3", narrationText: "Fireflies drew a glowing path.", choice: StoryChoice(prompt: "What should Luna do?", promptTe: "లూనా ఏమి చేయాలి?", options: [
                    StoryChoiceOption(id: "m3a", label: "Follow the starlight", labelTe: "నక్షత్ర కాంతిని అనుసరించు", emoji: "🌟", nextPageId: "m4a"),
                    StoryChoiceOption(id: "m3b", label: "Climb the moon hill", labelTe: "చంద్ర కొండ ఎక్కు", emoji: "🌙", nextPageId: "m4b")
                ]), isEnding: false),
                StoryPage(id: "m4a", index: 3, text: "She followed the starlight and discovered a bridge made of moonbeams!", textTe: "ఆమె నక్షత్ర కాంతిని అనుసరించి చంద్ర కిరణాల వంతెనను కనుగొంది!", illustrationName: "moon4a", narrationText: "She discovered a bridge made of moonbeams!", choice: nil, isEnding: false),
                StoryPage(id: "m4b", index: 3, text: "On the moon hill, she found a sleepy owl who knew the way to the stars.", textTe: "చంద్ర కొండపై నిద్రపోతున్న గుడ్లగూబను కనుగొంది.", illustrationName: "moon4b", narrationText: "She found a sleepy owl.", choice: nil, isEnding: false),
                StoryPage(id: "m5", index: 4, text: "Together they soared among constellations, giggling as comets whooshed by.", textTe: "కలిసి వారు నక్షత్ర సమూహాల మధ్య ఎగిరారు.", illustrationName: "moon5", narrationText: "Together they soared among constellations.", choice: nil, isEnding: false),
                StoryPage(id: "m6", index: 5, text: "Luna returned home with stardust in her pocket and a promise to explore again tomorrow.", textTe: "లూనా జేబులో నక్షత్ర ధూళితో ఇంటికి తిరిగి వచ్చింది.", illustrationName: "moon6", narrationText: "Luna returned home with stardust.", choice: nil, isEnding: true)
            ],
            discoverItems: ["A moonlit bridge","A talking star","A comet ride","Courage to explore"],
            discoverEmojis: ["🌙","⭐","☄️","💫"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "secret_forest",
            title: "The Secret Forest",
            titleTe: "రహస్య అడవి",
            description: "An adventure beyond the trees where Leo meets a talking owl and a magical tree hiding a treasure.",
            descriptionTe: "చెట్లకు అవతల ఒక సాహసం, లియో మాట్లాడే గుడ్లగూబను కలుస్తాడు.",
            category: .adventure,
            ageRange: "5-8",
            durationMinutes: 12,
            rating: 4.9,
            coverEmoji: "🌳",
            coverGradient: ["2E7D32","81C784"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "f1", index: 0, text: "Leo stepped into the whispering forest where sunlight danced through leaves.", textTe: "లియో గుసగుసలాడే అడవిలోకి అడుగుపెట్టాడు.", illustrationName: "forest1", narrationText: "Leo stepped into the whispering forest.", choice: nil, isEnding: false),
                StoryPage(id: "f2", index: 1, text: "A wise owl hooted, 'Only kind hearts can find the magical tree.'", textTe: "తెలివైన గుడ్లగూబ అంది, దయగల హృదయాలు మాత్రమే మాయా చెట్టును కనుగొనగలవు.", illustrationName: "forest2", narrationText: "A wise owl hooted.", choice: nil, isEnding: false),
                StoryPage(id: "f3", index: 2, text: "Fireflies lit the path as Leo walked deeper, hearing the forest hum.", textTe: "మిణుగురు పురుగులు దారిని వెలిగించాయి.", illustrationName: "forest3", narrationText: "Fireflies lit the path.", choice: nil, isEnding: false),
                StoryPage(id: "f4", index: 3, text: "He reached a giant tree with a door carved of roots. It glowed warmly.", textTe: "అతను వేర్లతో చెక్కిన తలుపుతో భారీ చెట్టును చేరాడు.", illustrationName: "forest4", narrationText: "He reached a giant tree.", choice: StoryChoice(prompt: "What should Leo do?", promptTe: "లియో ఏమి చేయాలి?", options: [
                    StoryChoiceOption(id: "f4a", label: "Knock gently", labelTe: "మెల్లగా తట్టు", emoji: "🚪", nextPageId: "f5a"),
                    StoryChoiceOption(id: "f4b", label: "Listen to the tree", labelTe: "చెట్టు మాట విను", emoji: "👂", nextPageId: "f5b")
                ]), isEnding: false),
                StoryPage(id: "f5a", index: 4, text: "The door creaked open to reveal a hollow filled with glowing seeds of dreams.", textTe: "తలుపు తెరుచుకుని కలల విత్తనాలు కనిపించాయి.", illustrationName: "forest5a", narrationText: "The door revealed glowing seeds.", choice: nil, isEnding: false),
                StoryPage(id: "f5b", index: 4, text: "The tree whispered, 'Plant kindness and the forest will always protect you.'", textTe: "చెట్టు గుసగుసలాడింది, దయను నాటు.", illustrationName: "forest5b", narrationText: "The tree whispered.", choice: nil, isEnding: false),
                StoryPage(id: "f6", index: 5, text: "Leo promised to care for the forest, and the trees rustled with joy.", textTe: "లియో అడవిని జాగ్రత్తగా చూసుకుంటానని వాగ్దానం చేశాడు.", illustrationName: "forest6", narrationText: "Leo promised to care.", choice: nil, isEnding: true)
            ],
            discoverItems: ["A mysterious forest","A talking owl","A magical tree","A hidden treasure"],
            discoverEmojis: ["🌲","🦉","✨","🗺"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "leo_mars",
            title: "Leo's Journey to Mars",
            titleTe: "లియో అంగారక యాత్ర",
            description: "Zoom past asteroids with Leo as he learns how planets dance around the sun.",
            descriptionTe: "లియోతో కలిసి గ్రహశకలాలను దాటి అంగారక గ్రహానికి వెళ్లండి.",
            category: .space,
            ageRange: "6-9",
            durationMinutes: 10,
            rating: 4.8,
            coverEmoji: "🚀",
            coverGradient: ["4A148C","FF6F00"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "s1", index: 0, text: "Leo built a cardboard rocket and counted down: 3, 2, 1... blast off!", textTe: "లియో కార్డ్‌బోర్డ్ రాకెట్ నిర్మించాడు.", illustrationName: "space1", narrationText: "Leo built a cardboard rocket.", choice: nil, isEnding: false),
                StoryPage(id: "s2", index: 1, text: "Stars twinkled as his rocket wobbled through the asteroid belt.", textTe: "నక్షత్రాలు మెరిశాయి.", illustrationName: "space2", narrationText: "Stars twinkled.", choice: nil, isEnding: false),
                StoryPage(id: "s3", index: 2, text: "Mars glowed red ahead. 'Welcome, little astronaut!' said rover Momo.", textTe: "అంగారక గ్రహం ఎర్రగా మెరిసింది.", illustrationName: "space3", narrationText: "Mars glowed red.", choice: nil, isEnding: false),
                StoryPage(id: "s4", index: 3, text: "Leo planted a flag and collected shiny red rocks to show his friends.", textTe: "లియో జెండా పాతి ఎర్ర రాళ్ళు సేకరించాడు.", illustrationName: "space4", narrationText: "Leo planted a flag.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Asteroid belt","Red planet Mars","Friendly rover","Zero gravity"],
            discoverEmojis: ["☄️","🔴","🤖","🌌"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "whale_song",
            title: "The Whale Who Lost His Song",
            titleTe: "పాట కోల్పోయిన తిమింగలం",
            description: "Deep under the waves, Wally the whale searches for his missing melody.",
            descriptionTe: "సముద్ర లోతులో వాలీ తన పాటను వెతుకుతాడు.",
            category: .ocean,
            ageRange: "4-8",
            durationMinutes: 9,
            rating: 4.9,
            coverEmoji: "🐳",
            coverGradient: ["006064","4DD0E1"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "o1", index: 0, text: "Wally woke up and tried to sing, but only bubbles came out.", textTe: "వాలీ పాడటానికి ప్రయత్నించాడు కానీ బుడగలు మాత్రమే వచ్చాయి.", illustrationName: "ocean1", narrationText: "Wally tried to sing.", choice: nil, isEnding: false),
                StoryPage(id: "o2", index: 1, text: "He swam past coral reefs where fish hummed lullabies.", textTe: "పగడపు దిబ్బల గుండా ఈదాడు.", illustrationName: "ocean2", narrationText: "He swam past coral reefs.", choice: nil, isEnding: false),
                StoryPage(id: "o3", index: 2, text: "A dolphin suggested, 'Maybe your song is hiding with friends.'", textTe: "డాల్ఫిన్ సూచించింది, నీ పాట స్నేహితుల వద్ద ఉండవచ్చు.", illustrationName: "ocean3", narrationText: "A dolphin suggested.", choice: nil, isEnding: false),
                StoryPage(id: "o4", index: 3, text: "Wally sang with everyone and found his voice was strongest together.", textTe: "అందరితో కలిసి పాడి తన గొంతును కనుగొన్నాడు.", illustrationName: "ocean4", narrationText: "Wally found his voice together.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Coral reef","Dolphin friends","Bubbles","Ocean song"],
            discoverEmojis: ["🪸","🐬","🫧","🎶"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "last_unicorn",
            title: "The Last Unicorn",
            titleTe: "చివరి యూనికార్న్",
            description: "A shy unicorn learns to share her sparkle with a lonely village.",
            descriptionTe: "సిగ్గుపడే యూనికార్న్ తన మెరుపును పంచుకోవడం నేర్చుకుంటుంది.",
            category: .fantasy,
            ageRange: "4-7",
            durationMinutes: 11,
            rating: 4.7,
            coverEmoji: "🦄",
            coverGradient: ["8E24AA","F48FB1"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "u1", index: 0, text: "In a misty meadow lived the last unicorn, hiding her horn.", textTe: "మంచు పచ్చికలో చివరి యూనికార్న్ నివసించింది.", illustrationName: "uni1", narrationText: "In a misty meadow lived the last unicorn.", choice: nil, isEnding: false),
                StoryPage(id: "u2", index: 1, text: "A child left a ribbon and whispered, 'Your magic could help our garden.'", textTe: "ఒక పిల్లవాడు రిబ్బన్ వదిలాడు.", illustrationName: "uni2", narrationText: "A child left a ribbon.", choice: nil, isEnding: false),
                StoryPage(id: "u3", index: 2, text: "The unicorn sprinkled stardust and wilted flowers bloomed again.", textTe: "యూనికార్న్ నక్షత్ర ధూళి చల్లింది.", illustrationName: "uni3", narrationText: "Flowers bloomed again.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Enchanted meadow","Kind child","Stardust","Bloom"],
            discoverEmojis: ["🌸","🎀","✨","🌷"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "brave_lion",
            title: "Leo and the Brave Little Lion",
            titleTe: "లియో మరియు ధైర్యవంతుడైన సింహం",
            description: "A tiny lion who roared too softly finds courage in friendship.",
            descriptionTe: "మెల్లగా గర్జించే చిన్న సింహం స్నేహంలో ధైర్యాన్ని కనుగొంటుంది.",
            category: .animals,
            ageRange: "3-6",
            durationMinutes: 7,
            rating: 4.8,
            coverEmoji: "🦁",
            coverGradient: ["E65100","FFB74D"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "a1", index: 0, text: "Kito the cub practiced his roar, but it came out as a squeak.", textTe: "కిటో గర్జన సాధన చేశాడు కానీ కీచుమన్నాడు.", illustrationName: "lion1", narrationText: "Kito practiced his roar.", choice: nil, isEnding: false),
                StoryPage(id: "a2", index: 1, text: "Leo encouraged, 'Try with your heart, not just your throat!'", textTe: "లియో ప్రోత్సహించాడు, హృదయంతో ప్రయత్నించు.", illustrationName: "lion2", narrationText: "Try with your heart.", choice: nil, isEnding: false),
                StoryPage(id: "a3", index: 2, text: "Kito roared to warn friends of a storm, and everyone cheered.", textTe: "కిటో తుఫాను గురించి గర్జించాడు.", illustrationName: "lion3", narrationText: "Kito roared to warn friends.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Savanna","Friendship","Courage","Roar"],
            discoverEmojis: ["🌾","🤝","💛","🦁"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "magic_tree",
            title: "The Magic Tree",
            titleTe: "మాయా చెట్టు",
            description: "Every leaf of this tree holds a tiny wish waiting to be discovered.",
            descriptionTe: "ఈ చెట్టు ప్రతి ఆకులో చిన్న కోరిక దాగి ఉంది.",
            category: .magic,
            ageRange: "4-8",
            durationMinutes: 9,
            rating: 4.9,
            coverEmoji: "🧙",
            coverGradient: ["4527A0","B39DDB"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "mg1", index: 0, text: "Mira found a tree that glittered even without sunlight.", textTe: "మిరా సూర్యకాంతి లేకుండా మెరిసే చెట్టును కనుగొంది.", illustrationName: "magic1", narrationText: "Mira found a glittering tree.", choice: nil, isEnding: false),
                StoryPage(id: "mg2", index: 1, text: "A leaf floated down and whispered a wish: 'I want to fly.'", textTe: "ఒక ఆకు రాలి, ఎగరాలని కోరింది.", illustrationName: "magic2", narrationText: "A leaf whispered a wish.", choice: nil, isEnding: false),
                StoryPage(id: "mg3", index: 2, text: "Mira tied the leaf to a kite and watched it dance with the wind.", textTe: "మిరా ఆకును గాలిపటానికి కట్టింది.", illustrationName: "magic3", narrationText: "Mira tied the leaf to a kite.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Glittering tree","Wish leaf","Kite","Wind dance"],
            discoverEmojis: ["🌳","🍃","🪁","💨"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "rainbow_village",
            title: "The Rainbow Village",
            titleTe: "ఇంద్రధనస్సు గ్రామం",
            description: "When the rainbow disappeared, the village children paint the sky again.",
            descriptionTe: "ఇంద్రధనస్సు మాయమైనప్పుడు పిల్లలు ఆకాశాన్ని మళ్ళీ రంగులు వేస్తారు.",
            category: .friendship,
            ageRange: "3-7",
            durationMinutes: 8,
            rating: 4.8,
            coverEmoji: "🌈",
            coverGradient: ["283593","CE93D8"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "r1", index: 0, text: "The Rainbow Village woke up grey when the rainbow vanished.", textTe: "ఇంద్రధనస్సు మాయమై గ్రామం బూడిద రంగులో మేల్కొంది.", illustrationName: "rainbow1", narrationText: "The village woke up grey.", choice: nil, isEnding: false),
                StoryPage(id: "r2", index: 1, text: "The children mixed colors from flowers, fruits and laughter.", textTe: "పిల్లలు పువ్వులు, పండ్ల నుండి రంగులు కలిపారు.", illustrationName: "rainbow2", narrationText: "Children mixed colors.", choice: nil, isEnding: false),
                StoryPage(id: "r3", index: 2, text: "They painted a huge rainbow that stretched to everyone's heart.", textTe: "వారు అందరి హృదయాలకు చేరే ఇంద్రధనస్సును చిత్రించారు.", illustrationName: "rainbow3", narrationText: "They painted a huge rainbow.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Grey village","Colors","Friendship","Rainbow"],
            discoverEmojis: ["🏘️","🎨","🤝","🌈"],
            languageSupport: ["en","te"]
        ),
        // MARK: — Real daily-life stories
        Story(
            id: "ammas_tiffin",
            title: "Amma's Tiffin Box",
            titleTe: "అమ్మ టిఫిన్ బాక్స్",
            description: "Arjun forgets his tiffin; sharing and thanking make the day happy. A real school story.",
            descriptionTe: "అర్జున్ టిఫిన్ మరచిపోతాడు, పంచుకోవడం ఆనందం ఇస్తుంది.",
            category: .friendship,
            ageRange: "4-8",
            durationMinutes: 6,
            rating: 4.9,
            coverEmoji: "🍱",
            coverGradient: ["FF6F00","FFD54F"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "t1", index: 0, text: "Arjun ran to school and left his tiffin on the table. At lunch, his tummy growled.", textTe: "అర్జున్ టిఫిన్ టేబుల్‌పై మరచిపోయాడు, ఆకలి వేసింది.", illustrationName: "tiffin1", narrationText: "Arjun left his tiffin on the table, his tummy growled.", choice: nil, isEnding: false),
                StoryPage(id: "t2", index: 1, text: "His friend Sara said, 'We can share my chapati and pickle. Amma packed extra!'", textTe: "సారా అంది, నా చపాతీ పంచుకుందాం.", illustrationName: "tiffin2", narrationText: "Sara said we can share my chapati and pickle.", choice: nil, isEnding: false),
                StoryPage(id: "t3", index: 2, text: "They ate together, laughed, and promised to remind each other. Sharing felt better than eating alone.", textTe: "కలిసి తిని నవ్వారు, పంచుకోవడం మంచిది.", illustrationName: "tiffin3", narrationText: "They ate together and sharing felt better.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Packed tiffin","Sharing food","Thank you","Friendship"],
            discoverEmojis: ["🍱","🤝","🙏","😊"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "helping_tata",
            title: "Helping Tata in the Field",
            titleTe: "తాతకు పొలంలో సహాయం",
            description: "A village morning where kids help grandpa carry water and learn respect for hard work.",
            descriptionTe: "గ్రామ ఉదయం, పిల్లలు తాతకు నీళ్లు మోయడంలో సహాయం చేస్తారు.",
            category: .learning,
            ageRange: "5-9",
            durationMinutes: 7,
            rating: 4.8,
            coverEmoji: "🌾",
            coverGradient: ["2E7D32","AED581"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "v1", index: 0, text: "Early morning, Tata walks to the field with a pot of water. Ravi wants to help.", textTe: "తెల్లవారుజామున తాత నీళ్ల చెంబుతో పొలానికి వెళ్తాడు.", illustrationName: "field1", narrationText: "Tata walks to the field, Ravi wants to help.", choice: nil, isEnding: false),
                StoryPage(id: "v2", index: 1, text: "Ravi carries the small bottle carefully without spilling. Tata smiles, 'Chala manchidi!'", textTe: "రవి నీళ్లు ఒలకకుండా జాగ్రత్తగా మోస్తాడు.", illustrationName: "field2", narrationText: "Ravi carries water carefully.", choice: nil, isEnding: false),
                StoryPage(id: "v3", index: 2, text: "They rest under a neem tree, drink water, and Tata tells how seeds become food. Hard work is prayer.", textTe: "వేప చెట్టు కింద కూర్చుని తాత విత్తనాల కథ చెప్తాడు.", illustrationName: "field3", narrationText: "They rest and Tata tells how seeds become food.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Village field","Carrying water","Neem tree","Respect for work"],
            discoverEmojis: ["🌾","💧","🌳","🙏"],
            languageSupport: ["en","te"]
        ),
        Story(
            id: "lost_pencil",
            title: "The Lost Pencil",
            titleTe: "పోయిన పెన్సిల్",
            description: "When honesty matters more than a new pencil. A daily school moral story.",
            descriptionTe: "కొత్త పెన్సిల్ కంటే నిజాయితీ ముఖ్యం.",
            category: .learning,
            ageRange: "4-7",
            durationMinutes: 6,
            rating: 4.9,
            coverEmoji: "✏️",
            coverGradient: ["37474F","90A4AE"],
            isFeatured: false,
            isStoryOfDay: false,
            pages: [
                StoryPage(id: "p1", index: 0, text: "Meena found a shiny pencil under her desk. It had someone's name on it — Srinu.", textTe: "మీనా బెంచీ కింద మెరిసే పెన్సిల్ కనుగొంది, దానిపై శ్రీను పేరు ఉంది.", illustrationName: "pencil1", narrationText: "Meena found a shiny pencil with Srinu's name.", choice: nil, isEnding: false),
                StoryPage(id: "p2", index: 1, text: "She thought, 'I like it, but Srinu will be sad.' She decides to give it back.", textTe: "నాకు నచ్చింది కానీ శ్రీను బాధపడతాడు అనుకుంది.", illustrationName: "pencil2", narrationText: "She decides to give it back.", choice: nil, isEnding: false),
                StoryPage(id: "p3", index: 2, text: "Srinu smiles and they become good friends. Teacher says, 'Honesty is the best habit.'", textTe: "శ్రీను నవ్వి స్నేహితులు అయ్యారు, నిజాయితీ మంచి అలవాటు.", illustrationName: "pencil3", narrationText: "Honesty is the best habit.", choice: nil, isEnding: true)
            ],
            discoverItems: ["Found pencil","Honesty","Friendship","Teacher's praise"],
            discoverEmojis: ["✏️","💛","🤝","👩‍🏫"],
            languageSupport: ["en","te"]
        )
    ]
}
