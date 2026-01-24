import Foundation

struct ExerciseSeedData {
    static let exercises: [Exercise] = [
        // MARK: - Chest Exercises

        Exercise(
            id: "bench-press",
            name: "Barbell Bench Press",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .barbell,
            category: .compound,
            instructions: "Lie on bench, grip bar slightly wider than shoulders. Lower to chest, press up explosively."
        ),
        Exercise(
            id: "incline-bench-press",
            name: "Incline Barbell Bench Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .barbell,
            category: .compound,
            instructions: "Set bench to 30-45 degrees. Lower bar to upper chest, press up."
        ),
        Exercise(
            id: "decline-bench-press",
            name: "Decline Barbell Bench Press",
            muscleGroups: [.chest, .triceps],
            equipment: .barbell,
            category: .compound,
            instructions: "Set bench to decline position. Lower bar to lower chest, press up."
        ),
        Exercise(
            id: "dumbbell-bench-press",
            name: "Dumbbell Bench Press",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Press dumbbells up from chest level, lower with control."
        ),
        Exercise(
            id: "incline-dumbbell-press",
            name: "Incline Dumbbell Press",
            muscleGroups: [.chest, .shoulders, .triceps],
            equipment: .dumbbell,
            category: .compound,
            instructions: "On incline bench, press dumbbells up from upper chest level."
        ),
        Exercise(
            id: "dumbbell-flyes",
            name: "Dumbbell Flyes",
            muscleGroups: [.chest],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "With slight bend in elbows, lower dumbbells in arc motion to sides. Squeeze chest to return."
        ),
        Exercise(
            id: "cable-crossover",
            name: "Cable Crossover",
            muscleGroups: [.chest],
            equipment: .cable,
            category: .isolation,
            instructions: "Stand between cables, bring handles together in front of chest with slight bend in elbows."
        ),
        Exercise(
            id: "push-ups",
            name: "Push-Ups",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Hands shoulder-width apart, lower chest to ground, push back up maintaining straight body."
        ),
        Exercise(
            id: "chest-dips",
            name: "Chest Dips",
            muscleGroups: [.chest, .triceps, .shoulders],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Lean forward on dip bars, lower until stretch in chest, press back up."
        ),
        Exercise(
            id: "machine-chest-press",
            name: "Machine Chest Press",
            muscleGroups: [.chest, .triceps],
            equipment: .machine,
            category: .compound,
            instructions: "Sit with back flat, press handles forward, control the return."
        ),
        Exercise(
            id: "pec-deck",
            name: "Pec Deck Machine",
            muscleGroups: [.chest],
            equipment: .machine,
            category: .isolation,
            instructions: "Bring pads together in front of chest, squeeze, slowly return."
        ),

        // MARK: - Back Exercises

        Exercise(
            id: "deadlift",
            name: "Conventional Deadlift",
            muscleGroups: [.back, .hamstrings, .glutes, .traps],
            equipment: .barbell,
            category: .compound,
            instructions: "Stand with feet hip-width, grip bar outside legs. Drive through heels, keep back flat, stand tall."
        ),
        Exercise(
            id: "sumo-deadlift",
            name: "Sumo Deadlift",
            muscleGroups: [.back, .glutes, .quads],
            equipment: .barbell,
            category: .compound,
            instructions: "Wide stance, grip bar between legs. Drive through heels, keep chest up."
        ),
        Exercise(
            id: "barbell-row",
            name: "Barbell Bent Over Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell,
            category: .compound,
            instructions: "Hinge at hips, pull bar to lower chest/upper abs, squeeze shoulder blades."
        ),
        Exercise(
            id: "pendlay-row",
            name: "Pendlay Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell,
            category: .compound,
            instructions: "From floor, explosively row to lower chest, lower back to ground each rep."
        ),
        Exercise(
            id: "dumbbell-row",
            name: "Single-Arm Dumbbell Row",
            muscleGroups: [.back, .biceps],
            equipment: .dumbbell,
            category: .compound,
            instructions: "One hand and knee on bench, row dumbbell to hip, squeeze lat at top."
        ),
        Exercise(
            id: "pull-ups",
            name: "Pull-Ups",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Grip bar overhead, pull until chin over bar, lower with control."
        ),
        Exercise(
            id: "chin-ups",
            name: "Chin-Ups",
            muscleGroups: [.back, .biceps],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Underhand grip, pull until chin over bar, emphasizes biceps more than pull-ups."
        ),
        Exercise(
            id: "lat-pulldown",
            name: "Lat Pulldown",
            muscleGroups: [.back, .biceps],
            equipment: .cable,
            category: .compound,
            instructions: "Pull bar to upper chest, squeeze lats, control the return."
        ),
        Exercise(
            id: "close-grip-pulldown",
            name: "Close-Grip Lat Pulldown",
            muscleGroups: [.back, .biceps],
            equipment: .cable,
            category: .compound,
            instructions: "Narrow grip handle, pull to chest, emphasizes lower lats."
        ),
        Exercise(
            id: "seated-cable-row",
            name: "Seated Cable Row",
            muscleGroups: [.back, .biceps],
            equipment: .cable,
            category: .compound,
            instructions: "Sit upright, pull handle to stomach, squeeze shoulder blades together."
        ),
        Exercise(
            id: "t-bar-row",
            name: "T-Bar Row",
            muscleGroups: [.back, .biceps],
            equipment: .barbell,
            category: .compound,
            instructions: "Straddle bar, row to chest with neutral grip handle."
        ),
        Exercise(
            id: "face-pulls",
            name: "Face Pulls",
            muscleGroups: [.back, .shoulders],
            equipment: .cable,
            category: .isolation,
            instructions: "Pull rope to face, externally rotate shoulders at end position."
        ),
        Exercise(
            id: "straight-arm-pulldown",
            name: "Straight-Arm Pulldown",
            muscleGroups: [.back],
            equipment: .cable,
            category: .isolation,
            instructions: "Keep arms straight, pull bar down to thighs, squeeze lats."
        ),

        // MARK: - Shoulder Exercises

        Exercise(
            id: "overhead-press",
            name: "Barbell Overhead Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .barbell,
            category: .compound,
            instructions: "Press bar from shoulders to overhead lockout. Keep core tight."
        ),
        Exercise(
            id: "dumbbell-shoulder-press",
            name: "Dumbbell Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Press dumbbells from shoulder height to overhead."
        ),
        Exercise(
            id: "arnold-press",
            name: "Arnold Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Start with palms facing you, rotate as you press overhead."
        ),
        Exercise(
            id: "lateral-raises",
            name: "Dumbbell Lateral Raises",
            muscleGroups: [.shoulders],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Raise dumbbells to sides until arms parallel to floor. Control descent."
        ),
        Exercise(
            id: "front-raises",
            name: "Dumbbell Front Raises",
            muscleGroups: [.shoulders],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Raise dumbbells in front to shoulder height, one at a time or together."
        ),
        Exercise(
            id: "rear-delt-flyes",
            name: "Rear Delt Flyes",
            muscleGroups: [.shoulders, .back],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Bent over, raise dumbbells to sides, squeeze rear delts."
        ),
        Exercise(
            id: "cable-lateral-raises",
            name: "Cable Lateral Raises",
            muscleGroups: [.shoulders],
            equipment: .cable,
            category: .isolation,
            instructions: "Raise handle to side with constant cable tension."
        ),
        Exercise(
            id: "upright-rows",
            name: "Barbell Upright Rows",
            muscleGroups: [.shoulders, .traps],
            equipment: .barbell,
            category: .compound,
            instructions: "Pull bar up along body to chin level, lead with elbows."
        ),
        Exercise(
            id: "machine-shoulder-press",
            name: "Machine Shoulder Press",
            muscleGroups: [.shoulders, .triceps],
            equipment: .machine,
            category: .compound,
            instructions: "Press handles overhead from shoulder level."
        ),

        // MARK: - Biceps Exercises

        Exercise(
            id: "barbell-curl",
            name: "Barbell Curl",
            muscleGroups: [.biceps],
            equipment: .barbell,
            category: .isolation,
            instructions: "Curl bar from thighs to shoulders, keep elbows stationary."
        ),
        Exercise(
            id: "ez-bar-curl",
            name: "EZ Bar Curl",
            muscleGroups: [.biceps],
            equipment: .barbell,
            category: .isolation,
            instructions: "Curl EZ bar with angled grip for wrist comfort."
        ),
        Exercise(
            id: "dumbbell-curl",
            name: "Dumbbell Bicep Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Curl dumbbells alternating or together, squeeze at top."
        ),
        Exercise(
            id: "hammer-curl",
            name: "Hammer Curl",
            muscleGroups: [.biceps, .forearms],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Neutral grip curl, targets brachialis and forearms."
        ),
        Exercise(
            id: "incline-dumbbell-curl",
            name: "Incline Dumbbell Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "On incline bench, curl dumbbells with arms hanging straight down."
        ),
        Exercise(
            id: "preacher-curl",
            name: "Preacher Curl",
            muscleGroups: [.biceps],
            equipment: .barbell,
            category: .isolation,
            instructions: "On preacher bench, curl bar with upper arms against pad."
        ),
        Exercise(
            id: "cable-curl",
            name: "Cable Bicep Curl",
            muscleGroups: [.biceps],
            equipment: .cable,
            category: .isolation,
            instructions: "Curl cable handle from low position, constant tension."
        ),
        Exercise(
            id: "concentration-curl",
            name: "Concentration Curl",
            muscleGroups: [.biceps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Seated, elbow against inner thigh, curl with focus on contraction."
        ),

        // MARK: - Triceps Exercises

        Exercise(
            id: "close-grip-bench",
            name: "Close-Grip Bench Press",
            muscleGroups: [.triceps, .chest],
            equipment: .barbell,
            category: .compound,
            instructions: "Hands shoulder-width or closer, lower bar to chest, press up."
        ),
        Exercise(
            id: "skull-crushers",
            name: "Skull Crushers",
            muscleGroups: [.triceps],
            equipment: .barbell,
            category: .isolation,
            instructions: "Lower bar to forehead, extend arms. Keep upper arms vertical."
        ),
        Exercise(
            id: "tricep-pushdown",
            name: "Tricep Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable,
            category: .isolation,
            instructions: "Push bar down until arms straight, squeeze triceps."
        ),
        Exercise(
            id: "rope-pushdown",
            name: "Rope Tricep Pushdown",
            muscleGroups: [.triceps],
            equipment: .cable,
            category: .isolation,
            instructions: "Push rope down and apart at bottom for extra contraction."
        ),
        Exercise(
            id: "overhead-tricep-extension",
            name: "Overhead Tricep Extension",
            muscleGroups: [.triceps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Hold dumbbell overhead, lower behind head, extend up."
        ),
        Exercise(
            id: "tricep-dips",
            name: "Tricep Dips",
            muscleGroups: [.triceps, .chest],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Keep body upright on dip bars, lower and press up."
        ),
        Exercise(
            id: "kickbacks",
            name: "Tricep Kickbacks",
            muscleGroups: [.triceps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Bent over, extend arm straight back, squeeze tricep."
        ),
        Exercise(
            id: "diamond-push-ups",
            name: "Diamond Push-Ups",
            muscleGroups: [.triceps, .chest],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Hands close together forming diamond shape, perform push-up."
        ),

        // MARK: - Quad Exercises

        Exercise(
            id: "barbell-squat",
            name: "Barbell Back Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .barbell,
            category: .compound,
            instructions: "Bar on upper back, squat down keeping chest up, drive through heels."
        ),
        Exercise(
            id: "front-squat",
            name: "Front Squat",
            muscleGroups: [.quads, .glutes, .core],
            equipment: .barbell,
            category: .compound,
            instructions: "Bar on front delts, squat with upright torso."
        ),
        Exercise(
            id: "goblet-squat",
            name: "Goblet Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Hold dumbbell at chest, squat between legs."
        ),
        Exercise(
            id: "leg-press",
            name: "Leg Press",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .machine,
            category: .compound,
            instructions: "Feet shoulder-width on platform, lower sled, press back up."
        ),
        Exercise(
            id: "hack-squat",
            name: "Hack Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .machine,
            category: .compound,
            instructions: "Shoulders under pads, squat down and press up on angled platform."
        ),
        Exercise(
            id: "leg-extension",
            name: "Leg Extension",
            muscleGroups: [.quads],
            equipment: .machine,
            category: .isolation,
            instructions: "Extend legs until straight, squeeze quads, lower with control."
        ),
        Exercise(
            id: "lunges",
            name: "Walking Lunges",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Step forward into lunge, alternate legs while walking."
        ),
        Exercise(
            id: "bulgarian-split-squat",
            name: "Bulgarian Split Squat",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Rear foot elevated, squat down on front leg."
        ),
        Exercise(
            id: "step-ups",
            name: "Step-Ups",
            muscleGroups: [.quads, .glutes],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Step onto elevated platform, drive through heel, step down."
        ),

        // MARK: - Hamstring Exercises

        Exercise(
            id: "romanian-deadlift",
            name: "Romanian Deadlift",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell,
            category: .compound,
            instructions: "Hinge at hips with slight knee bend, lower bar along legs, feel hamstring stretch."
        ),
        Exercise(
            id: "stiff-leg-deadlift",
            name: "Stiff-Leg Deadlift",
            muscleGroups: [.hamstrings, .glutes],
            equipment: .barbell,
            category: .compound,
            instructions: "Minimal knee bend, hinge at hips to lower bar."
        ),
        Exercise(
            id: "dumbbell-rdl",
            name: "Dumbbell Romanian Deadlift",
            muscleGroups: [.hamstrings, .glutes],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Hold dumbbells, hinge at hips with flat back."
        ),
        Exercise(
            id: "lying-leg-curl",
            name: "Lying Leg Curl",
            muscleGroups: [.hamstrings],
            equipment: .machine,
            category: .isolation,
            instructions: "Face down, curl weight toward glutes, squeeze hamstrings."
        ),
        Exercise(
            id: "seated-leg-curl",
            name: "Seated Leg Curl",
            muscleGroups: [.hamstrings],
            equipment: .machine,
            category: .isolation,
            instructions: "Seated, curl weight under seat, control the return."
        ),
        Exercise(
            id: "good-mornings",
            name: "Good Mornings",
            muscleGroups: [.hamstrings, .glutes, .back],
            equipment: .barbell,
            category: .compound,
            instructions: "Bar on back, hinge at hips keeping back flat."
        ),
        Exercise(
            id: "nordic-curl",
            name: "Nordic Hamstring Curl",
            muscleGroups: [.hamstrings],
            equipment: .bodyweight,
            category: .isolation,
            instructions: "Kneel with feet anchored, lower body forward with control."
        ),

        // MARK: - Glute Exercises

        Exercise(
            id: "hip-thrust",
            name: "Barbell Hip Thrust",
            muscleGroups: [.glutes, .hamstrings],
            equipment: .barbell,
            category: .compound,
            instructions: "Back against bench, bar on hips, thrust hips up and squeeze glutes."
        ),
        Exercise(
            id: "glute-bridge",
            name: "Glute Bridge",
            muscleGroups: [.glutes],
            equipment: .bodyweight,
            category: .isolation,
            instructions: "Lying flat, drive hips up, squeeze glutes at top."
        ),
        Exercise(
            id: "cable-kickback",
            name: "Cable Glute Kickback",
            muscleGroups: [.glutes],
            equipment: .cable,
            category: .isolation,
            instructions: "Ankle strap attached, kick leg back, squeeze glute."
        ),
        Exercise(
            id: "sumo-squat",
            name: "Sumo Squat",
            muscleGroups: [.glutes, .quads],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Wide stance, toes out, squat holding dumbbell between legs."
        ),
        Exercise(
            id: "hip-abduction",
            name: "Hip Abduction Machine",
            muscleGroups: [.glutes],
            equipment: .machine,
            category: .isolation,
            instructions: "Push legs apart against pads, squeeze at end range."
        ),

        // MARK: - Calf Exercises

        Exercise(
            id: "standing-calf-raise",
            name: "Standing Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine,
            category: .isolation,
            instructions: "Rise onto toes, full stretch at bottom, squeeze at top."
        ),
        Exercise(
            id: "seated-calf-raise",
            name: "Seated Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine,
            category: .isolation,
            instructions: "Knees under pad, raise heels, emphasizes soleus."
        ),
        Exercise(
            id: "leg-press-calf-raise",
            name: "Leg Press Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine,
            category: .isolation,
            instructions: "On leg press, press through toes only."
        ),
        Exercise(
            id: "donkey-calf-raise",
            name: "Donkey Calf Raise",
            muscleGroups: [.calves],
            equipment: .machine,
            category: .isolation,
            instructions: "Bent at waist, raise heels against resistance."
        ),

        // MARK: - Core Exercises

        Exercise(
            id: "plank",
            name: "Plank",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .isolation,
            defaultRestSeconds: 60,
            instructions: "Hold push-up position on forearms, keep body straight."
        ),
        Exercise(
            id: "crunches",
            name: "Crunches",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .isolation,
            defaultRestSeconds: 45,
            instructions: "Curl shoulders toward hips, don't pull on neck."
        ),
        Exercise(
            id: "hanging-leg-raise",
            name: "Hanging Leg Raise",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .compound,
            instructions: "Hang from bar, raise legs to parallel or higher."
        ),
        Exercise(
            id: "cable-crunch",
            name: "Cable Crunch",
            muscleGroups: [.core],
            equipment: .cable,
            category: .isolation,
            instructions: "Kneel facing cable, crunch down bringing elbows to knees."
        ),
        Exercise(
            id: "russian-twist",
            name: "Russian Twist",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .isolation,
            instructions: "Seated, lean back, rotate torso side to side."
        ),
        Exercise(
            id: "ab-wheel",
            name: "Ab Wheel Rollout",
            muscleGroups: [.core],
            equipment: .none,
            category: .compound,
            instructions: "Roll wheel forward extending body, roll back with control."
        ),
        Exercise(
            id: "dead-bug",
            name: "Dead Bug",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .isolation,
            defaultRestSeconds: 45,
            instructions: "On back, extend opposite arm and leg while keeping back flat."
        ),
        Exercise(
            id: "mountain-climbers",
            name: "Mountain Climbers",
            muscleGroups: [.core],
            equipment: .bodyweight,
            category: .compound,
            defaultRestSeconds: 45,
            instructions: "In push-up position, drive knees toward chest alternating."
        ),

        // MARK: - Trap Exercises

        Exercise(
            id: "barbell-shrugs",
            name: "Barbell Shrugs",
            muscleGroups: [.traps],
            equipment: .barbell,
            category: .isolation,
            instructions: "Hold bar at thighs, shrug shoulders up toward ears."
        ),
        Exercise(
            id: "dumbbell-shrugs",
            name: "Dumbbell Shrugs",
            muscleGroups: [.traps],
            equipment: .dumbbell,
            category: .isolation,
            instructions: "Hold dumbbells at sides, shrug up and slightly back."
        ),
        Exercise(
            id: "farmers-walk",
            name: "Farmer's Walk",
            muscleGroups: [.traps, .forearms, .core],
            equipment: .dumbbell,
            category: .compound,
            instructions: "Hold heavy weights at sides, walk with good posture."
        ),

        // MARK: - Forearm Exercises

        Exercise(
            id: "wrist-curl",
            name: "Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .barbell,
            category: .isolation,
            defaultRestSeconds: 45,
            instructions: "Forearms on bench, palms up, curl wrists up."
        ),
        Exercise(
            id: "reverse-wrist-curl",
            name: "Reverse Wrist Curl",
            muscleGroups: [.forearms],
            equipment: .barbell,
            category: .isolation,
            defaultRestSeconds: 45,
            instructions: "Forearms on bench, palms down, extend wrists up."
        ),
        Exercise(
            id: "reverse-curl",
            name: "Reverse Barbell Curl",
            muscleGroups: [.forearms, .biceps],
            equipment: .barbell,
            category: .isolation,
            instructions: "Overhand grip, curl bar up keeping wrists straight."
        )
    ]

    static func getExercises(for workoutType: WorkoutType) -> [Exercise] {
        let muscleGroups = workoutType.primaryMuscleGroups
        return exercises.filter { exercise in
            exercise.muscleGroups.contains { muscleGroups.contains($0) }
        }
    }

    static func getExercises(for muscleGroup: MuscleGroup) -> [Exercise] {
        exercises.filter { $0.muscleGroups.contains(muscleGroup) }
    }

    static func getExercises(for equipment: Equipment) -> [Exercise] {
        exercises.filter { $0.equipment == equipment }
    }

    static func getCompoundExercises() -> [Exercise] {
        exercises.filter { $0.category == .compound }
    }

    static func getIsolationExercises() -> [Exercise] {
        exercises.filter { $0.category == .isolation }
    }

    static func searchExercises(query: String) -> [Exercise] {
        let lowercasedQuery = query.lowercased()
        return exercises.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            $0.muscleGroups.contains { $0.displayName.lowercased().contains(lowercasedQuery) } ||
            $0.equipment.displayName.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Firestore Upload Helper

    /// Upload all exercises to Firestore. Call this once during initial setup.
    static func uploadToFirestore() async throws {
        let firestoreService = FirestoreService.shared
        
        for exercise in exercises {
            _ = try await firestoreService.create(
                exercise,
                collection: .exercises,
                documentId: exercise.id
            )
        }
        
        print("✅ Successfully uploaded \(exercises.count) exercises to Firestore")
    }
}
