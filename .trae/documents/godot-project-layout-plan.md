## Summary
- Establish a Godot 4.6 project layout for a text-based life sim, matching the provided directory tree.
- Define clear responsibilities and data flow between autoload managers, Resource types, data assets (.tres), UI scenes, and gameplay scripts.
- Plan focuses on layout + purpose only (no deep gameplay design), uses .tres Resources for data, JSON for save files, and a turn-based “advance year” loop.

## Current State Analysis
- Repository currently contains only core Godot project files: [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot), icons, and git config files.
- No directories, scripts, scenes, or data assets from the proposed layout exist yet.
- Godot version/features: 4.6 with GL Compatibility rendering; physics uses Jolt.

## Target Layout (Source of Truth)
Create the following directories and files (exactly as listed), keeping naming consistent:
- autoloads/
  - GameManager.gd
  - EventManager.gd
  - SaveManager.gd
- resources/
  - CharacterData.gd
  - LifeEvent.gd
  - JobData.gd
- data/
  - events/
    - childhood_events.tres
    - teen_events.tres
    - adult_events.tres
  - jobs/
    - job_list.tres
  - names/
    - name_pools.tres
- scenes/
  - main/
    - Main.tscn
  - ui/
    - panels/
      - StatsPanel.tscn
      - EventPanel.tscn
      - HistoryLog.tscn
    - components/
      - ChoiceButton.tscn
  - overlays/
    - GameOverScreen.tscn
- scripts/
  - character/
    - CharacterGenerator.gd
  - events/
    - EventResolver.gd
  - procgen/
    - NameGenerator.gd
- assets/
  - fonts/

## Responsibilities & Boundaries (What Each Area Is For)
### autoloads/
- Purpose: global singletons that coordinate gameplay and persist across scene changes.
- GameManager.gd
  - Owns the “advance year” loop state (current age/year, current CharacterData instance, phase selection).
  - Calls into EventManager to pull events, and into SaveManager to persist.
- EventManager.gd
  - Owns loading/caching of event pools from data/events/*.tres.
  - Provides APIs like “get candidate events for current age/phase” (selection logic lives here or in EventResolver, see below).
- SaveManager.gd
  - Owns serialization/deserialization of current run into JSON files in user:// (Godot’s writable path).
  - Does not contain game rules; it only translates state to/from JSON.

### resources/
- Purpose: strongly-typed data models that can be authored and stored in .tres and passed around at runtime.
- CharacterData.gd (Resource)
  - Runtime state for the current character (stats, age, flags, job reference, history).
  - Kept independent from UI nodes so it can be saved/loaded cleanly.
- LifeEvent.gd (Resource)
  - Describes one event: text, eligible phases/age range, stat deltas, choice list, tags.
  - Intended to be instanced and stored inside childhood/teen/adult .tres lists.
- JobData.gd (Resource)
  - Describes one job: title, requirements, salary/benefits, stat effects, promotion path identifiers.

### data/
- Purpose: authored content assets and lists.
- events/*.tres
  - Each file represents a pool/list of LifeEvent resources for a life phase.
  - Loaded once at start (or lazily) by EventManager.
- jobs/job_list.tres
  - A list of JobData resources.
- names/name_pools.tres
  - A structure holding first/last name pools and optional weights; used by NameGenerator.

### scripts/
- Purpose: pure logic modules that are not global singletons and not Scenes.
- character/CharacterGenerator.gd
  - Creates a new CharacterData from defaults and random selections (using NameGenerator and job list).
- events/EventResolver.gd
  - Applies an event (and chosen option) to CharacterData and produces a result payload for UI (e.g., lines for HistoryLog).
- procgen/NameGenerator.gd
  - Randomly selects names from name_pools.tres; deterministic seed support can be added later if desired.

### scenes/
- Purpose: nodes and UI composition; should be thin and delegate logic to autoloads/scripts.
- main/Main.tscn
  - Root scene. Wires panels together; triggers “advance year” action; receives signals/results and updates UI.
- ui/panels/StatsPanel.tscn
  - Displays CharacterData fields (age, stats, current job).
- ui/panels/EventPanel.tscn
  - Displays current event text and renders choices using ChoiceButton component(s).
- ui/panels/HistoryLog.tscn
  - Appends readable summaries of past years/events.
- ui/components/ChoiceButton.tscn
  - Reusable button with consistent styling; emits selected choice id/payload.
- overlays/GameOverScreen.tscn
  - Shown on game-over conditions (e.g., death, bankruptcy), with restart/load options.

### assets/fonts/
- Purpose: custom fonts and imports used by UI scenes.

## Autoload Wiring (Project Settings Changes)
Once scripts exist, add autoloads via Project Settings → Autoload (preferred) which edits [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot):
- GameManager (path: res://autoloads/GameManager.gd)
- EventManager (path: res://autoloads/EventManager.gd)
- SaveManager (path: res://autoloads/SaveManager.gd)

## Conventions (To Keep the Layout Maintainable)
- Resource scripts in resources/ only define data + validation defaults; they do not reference Nodes/UI.
- UI scenes read from CharacterData and display; they do not implement game rules.
- Event selection (“which event occurs”) is separated from event application (“what changes when event chosen”).
- SaveManager is the only place that reads/writes JSON; other code passes plain Dictionaries/arrays or Resource fields.
- Data assets in data/ are the only place where narrative text and large content live (not in scripts).

## Implementation Steps (No File Creation During Planning)
1. Create the directory structure under the project root exactly as listed in “Target Layout”.
2. Add core scripts:
   - Create the three autoload scripts and register them in Project Settings.
   - Create Resource scripts (CharacterData, LifeEvent, JobData) and validate they can be instanced in the editor.
3. Create data assets:
   - Create the .tres lists for events/jobs/names and populate with a minimal set for smoke testing.
4. Create scenes:
   - Build Main.tscn and the UI panels/components, connecting signals for “advance year” and “choice selected”.
5. Integrate flow:
   - Main calls GameManager.advance_year().
   - GameManager requests an event from EventManager; UI displays via EventPanel.
   - On selection, EventResolver applies results to CharacterData; HistoryLog/StatsPanel update.
6. Add saving/loading:
   - SaveManager writes JSON to user://; Main exposes Save/Load buttons or menu items.

## Assumptions & Decisions (Locked)
- Godot version is 4.6 (from project.godot).
- Data assets use .tres Resources (not JSON) for events/jobs/names.
- Save files use JSON (in user://).
- Core loop is turn-based: user presses a button to advance one year, generating 0–N events.
- This plan describes structure and responsibilities only; detailed balancing/probabilities and narrative content are out of scope here.

## Verification (When Executing This Plan Later)
- Godot editor opens project without errors; autoloads appear in Project Settings → Autoload.
- Main.tscn set as main scene and runs.
- “Advance year” updates age and appends at least one history entry.
- EventPanel renders at least one event from the appropriate phase pool and records the chosen option.
- Save creates a JSON file in user:// and Load restores CharacterData values correctly.
